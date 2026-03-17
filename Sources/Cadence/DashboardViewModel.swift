import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var habits: [Habit] = []
    private(set) var habitCounts: [UUID: Int] = [:]
    private(set) var habitStreaks: [UUID: Int] = [:]
    private(set) var isLoading = false
    private(set) var error: (any Error)?

    let habitRepository: HabitRepository
    let logRepository: HabitLogRepository

    private var historicalDateCounts: [UUID: [String: Int]] = [:]
    private var todayLoggedHabits: Set<UUID> = []
    private var userStartDate: Date?
    private var lastLoadedDate: String?

    var todayDisplayDate: String {
        Date.now.formatted(date: .complete, time: .omitted)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }

    var isPerfectDay: Bool {
        guard !habits.isEmpty else { return false }
        return habits.allSatisfy { habit in
            let count = habitCounts[habit.id] ?? 0
            return habit.isInverse ? count == 0 : count >= 1
        }
    }

    var perfectDayStreak: Int {
        guard isPerfectDay else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var streak = 1
        guard var checkDate = calendar.date(byAdding: .day, value: -1, to: today) else { return streak }
        guard let minDate = calendar.date(byAdding: .day, value: -365, to: today) else { return streak }

        while checkDate >= minDate {
            let dateString = formatter.string(from: checkDate)
            let allMet = habits.allSatisfy { habit in
                let count = historicalDateCounts[habit.id]?[dateString] ?? 0
                return habit.isInverse ? count == 0 : count >= 1
            }
            if allMet {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    var bestStreakHabit: (habit: Habit, streak: Int)? {
        guard !habits.isEmpty else { return nil }
        var best: (Habit, Int)?
        for habit in habits {
            let s = habitStreaks[habit.id] ?? 0
            if s > 0 {
                if best == nil || s > best!.1 {
                    best = (habit, s)
                }
            }
        }
        if let best { return (habit: best.0, streak: best.1) }
        return nil
    }

    init(habitRepository: HabitRepository, logRepository: HabitLogRepository) {
        self.habitRepository = habitRepository
        self.logRepository = logRepository
    }

    // MARK: - Loading

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            habits = try await habitRepository.fetchHabits()
            await loadTodayLogs()
        } catch {
            self.error = error
        }
    }

    /// Reloads data if the calendar day has changed since the last load.
    /// Call this when the app returns to the foreground.
    func reloadIfDayChanged() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        guard today != lastLoadedDate else { return }
        await loadAll()
    }

    func loadTodayLogs() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            let logs = try await logRepository.fetchLogs(date: today)
            todayLoggedHabits = []
            var counts: [UUID: Int] = [:]
            for habit in habits {
                counts[habit.id] = 0
            }
            for log in logs {
                counts[log.habitId] = log.count
                todayLoggedHabits.insert(log.habitId)
            }
            habitCounts = counts
            lastLoadedDate = today
            error = nil

            await loadStreaks()
        } catch {
            self.error = error
        }
    }

    // MARK: - Accessors

    func count(for habit: Habit) -> Int {
        habitCounts[habit.id] ?? 0
    }

    func streak(for habit: Habit) -> Int {
        habitStreaks[habit.id] ?? 0
    }

    /// Returns date→count map for a given habit (used by history view).
    func dateCounts(for habit: Habit) -> [String: Int] {
        var counts = historicalDateCounts[habit.id] ?? [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        counts[today] = habitCounts[habit.id] ?? 0
        return counts
    }

    // MARK: - Habit CRUD

    func createHabit(name: String, icon: String, color: String, isInverse: Bool) async {
        do {
            print("[CREATE] Creating habit: \(name)")
            let habit = try await habitRepository.createHabit(
                name: name, icon: icon, color: color, isInverse: isInverse
            )
            print("[CREATE] Success: \(habit.name) id=\(habit.id)")
            habits.append(habit)
            habitCounts[habit.id] = 0
            habitStreaks[habit.id] = 0
        } catch {
            print("[CREATE] FAILED: \(error)")
            self.error = error
        }
    }

    func deleteHabit(_ habit: Habit) async {
        let previousHabits = habits
        habits.removeAll { $0.id == habit.id }
        habitCounts.removeValue(forKey: habit.id)
        habitStreaks.removeValue(forKey: habit.id)

        do {
            try await habitRepository.deleteHabit(id: habit.id)
        } catch {
            habits = previousHabits
            self.error = error
        }
    }

    // MARK: - Count Operations

    func incrementCount(for habit: Habit) async {
        let previousCount = habitCounts[habit.id] ?? 0
        let newCount = previousCount + 1

        print("[INCREMENT] \(habit.name): \(previousCount) -> \(newCount), habitId=\(habit.id)")
        habitCounts[habit.id] = newCount
        todayLoggedHabits.insert(habit.id)
        recalculateStreak(for: habit)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            let result = try await logRepository.upsertLog(habitId: habit.id, date: today, count: newCount)
            print("[INCREMENT] Upsert success: \(habit.name) count=\(result.count)")
            error = nil
        } catch {
            print("[INCREMENT] Upsert FAILED: \(habit.name) error=\(error)")
            habitCounts[habit.id] = previousCount
            recalculateStreak(for: habit)
            self.error = error
        }
    }

    func decrementCount(for habit: Habit) async {
        let previousCount = habitCounts[habit.id] ?? 0
        let newCount = max(previousCount - 1, 0)

        guard newCount != previousCount else { return }

        habitCounts[habit.id] = newCount
        recalculateStreak(for: habit)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            _ = try await logRepository.upsertLog(habitId: habit.id, date: today, count: newCount)
            error = nil
        } catch {
            habitCounts[habit.id] = previousCount
            recalculateStreak(for: habit)
            self.error = error
        }
    }

    func resetCount(for habit: Habit) async {
        let previousCount = habitCounts[habit.id] ?? 0

        guard previousCount != 0 else { return }

        habitCounts[habit.id] = 0
        recalculateStreak(for: habit)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            _ = try await logRepository.upsertLog(habitId: habit.id, date: today, count: 0)
            error = nil
        } catch {
            habitCounts[habit.id] = previousCount
            recalculateStreak(for: habit)
            self.error = error
        }
    }

    // MARK: - Streak Calculation

    private func loadStreaks() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -365, to: today) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: today)

        do {
            let logs = try await logRepository.fetchLogs(from: startString, to: endString)

            var dateCounts: [UUID: [String: Int]] = [:]
            for habit in habits {
                dateCounts[habit.id] = [:]
            }
            for log in logs {
                dateCounts[log.habitId]?[log.date] = log.count
            }
            historicalDateCounts = dateCounts

            if let earliest = logs.map({ $0.date }).min() {
                userStartDate = formatter.date(from: earliest)
            }

            recalculateAllStreaks()
        } catch {
            // Streak loading failure is non-critical
        }
    }

    private func recalculateAllStreaks() {
        for habit in habits {
            habitStreaks[habit.id] = calculateStreak(for: habit)
        }
    }

    private func recalculateStreak(for habit: Habit) {
        habitStreaks[habit.id] = calculateStreak(for: habit)
    }

    private func calculateStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let isInverse = habit.isInverse
        var streak = 0

        if todayLoggedHabits.contains(habit.id) {
            let todayCount = habitCounts[habit.id] ?? 0
            let meetsCondition = isInverse ? todayCount == 0 : todayCount >= 1
            if meetsCondition {
                streak = 1
            } else {
                return 0
            }
        }

        guard var checkDate = calendar.date(byAdding: .day, value: -1, to: today) else { return streak }
        guard let minDate = calendar.date(byAdding: .day, value: -365, to: today) else { return streak }

        while checkDate >= minDate {
            if isInverse, let startDate = userStartDate, checkDate < startDate {
                break
            }

            let dateString = formatter.string(from: checkDate)
            let count = historicalDateCounts[habit.id]?[dateString] ?? 0

            let meetsCondition = isInverse ? count == 0 : count >= 1
            if meetsCondition {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }

        return streak
    }
}
