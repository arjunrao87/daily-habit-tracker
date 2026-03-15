import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var habitCounts: [HabitType: Int]
    private(set) var habitStreaks: [HabitType: Int]
    private(set) var isLoading = false
    private(set) var error: (any Error)?

    let repository: HabitLogRepository

    private var historicalDateCounts: [HabitType: [String: Int]] = [:]
    private var todayLoggedHabits: Set<HabitType> = []
    private var userStartDate: Date?

    var todayDisplayDate: String {
        Date.now.formatted(date: .complete, time: .omitted)
    }

    nonisolated init(repository: HabitLogRepository) {
        self.repository = repository
        var counts: [HabitType: Int] = [:]
        var streaks: [HabitType: Int] = [:]
        for habit in HabitType.allCases {
            counts[habit] = 0
            streaks[habit] = 0
        }
        self.habitCounts = counts
        self.habitStreaks = streaks
    }

    func loadTodayLogs() async {
        isLoading = true
        defer { isLoading = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            let logs = try await repository.fetchLogs(date: today)
            var counts: [HabitType: Int] = [:]
            for habit in HabitType.allCases {
                counts[habit] = 0
            }
            for log in logs {
                counts[log.habitType] = log.count
                todayLoggedHabits.insert(log.habitType)
            }
            habitCounts = counts
            error = nil

            await loadStreaks()
        } catch {
            self.error = error
        }
    }

    func count(for habit: HabitType) -> Int {
        habitCounts[habit] ?? 0
    }

    func streak(for habit: HabitType) -> Int {
        habitStreaks[habit] ?? 0
    }

    func incrementCount(for habit: HabitType) async {
        let previousCount = habitCounts[habit] ?? 0
        let newCount = previousCount + 1

        habitCounts[habit] = newCount
        todayLoggedHabits.insert(habit)
        recalculateStreak(for: habit)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            _ = try await repository.upsertLog(habitType: habit, date: today, count: newCount)
            error = nil
        } catch {
            habitCounts[habit] = previousCount
            recalculateStreak(for: habit)
            self.error = error
        }
    }

    func decrementCount(for habit: HabitType) async {
        let previousCount = habitCounts[habit] ?? 0
        let newCount = max(previousCount - 1, 0)

        guard newCount != previousCount else { return }

        habitCounts[habit] = newCount
        recalculateStreak(for: habit)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            _ = try await repository.upsertLog(habitType: habit, date: today, count: newCount)
            error = nil
        } catch {
            habitCounts[habit] = previousCount
            recalculateStreak(for: habit)
            self.error = error
        }
    }

    func resetCount(for habit: HabitType) async {
        let previousCount = habitCounts[habit] ?? 0

        guard previousCount != 0 else { return }

        habitCounts[habit] = 0
        recalculateStreak(for: habit)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            _ = try await repository.upsertLog(habitType: habit, date: today, count: 0)
            error = nil
        } catch {
            habitCounts[habit] = previousCount
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
            let logs = try await repository.fetchLogs(from: startString, to: endString)

            var dateCounts: [HabitType: [String: Int]] = [:]
            for habit in HabitType.allCases {
                dateCounts[habit] = [:]
            }
            for log in logs {
                dateCounts[log.habitType]?[log.date] = log.count
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
        for habit in HabitType.allCases {
            habitStreaks[habit] = calculateStreak(for: habit)
        }
    }

    private func recalculateStreak(for habit: HabitType) {
        habitStreaks[habit] = calculateStreak(for: habit)
    }

    private func calculateStreak(for habit: HabitType) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let isInverse = habit.isInverse
        var streak = 0

        // Check today
        if todayLoggedHabits.contains(habit) {
            let todayCount = habitCounts[habit] ?? 0
            let meetsCondition = isInverse ? todayCount == 0 : todayCount >= 1
            if meetsCondition {
                streak = 1
            } else {
                return 0
            }
        }
        // If today not logged, skip today and start from yesterday

        // Walk backwards from yesterday
        guard var checkDate = calendar.date(byAdding: .day, value: -1, to: today) else { return streak }
        guard let minDate = calendar.date(byAdding: .day, value: -365, to: today) else { return streak }

        while checkDate >= minDate {
            // For inverse habits, stop before the user's first recorded activity
            if isInverse, let startDate = userStartDate, checkDate < startDate {
                break
            }

            let dateString = formatter.string(from: checkDate)
            let count = historicalDateCounts[habit]?[dateString] ?? 0

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
