import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var habitCounts: [HabitType: Int]
    private(set) var isLoading = false
    private(set) var error: (any Error)?

    let repository: HabitLogRepository

    var todayDisplayDate: String {
        Date.now.formatted(date: .complete, time: .omitted)
    }

    nonisolated init(repository: HabitLogRepository) {
        self.repository = repository
        var counts: [HabitType: Int] = [:]
        for habit in HabitType.allCases {
            counts[habit] = 0
        }
        self.habitCounts = counts
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
            }
            habitCounts = counts
            error = nil
        } catch {
            self.error = error
        }
    }

    func count(for habit: HabitType) -> Int {
        habitCounts[habit] ?? 0
    }

    func incrementCount(for habit: HabitType) async {
        let previousCount = habitCounts[habit] ?? 0
        let newCount = previousCount + 1

        // Optimistic update
        habitCounts[habit] = newCount

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            _ = try await repository.upsertLog(habitType: habit, date: today, count: newCount)
            error = nil
        } catch {
            // Roll back on failure
            habitCounts[habit] = previousCount
            self.error = error
        }
    }

    func decrementCount(for habit: HabitType) async {
        let previousCount = habitCounts[habit] ?? 0
        let newCount = max(previousCount - 1, 0)

        guard newCount != previousCount else { return }

        // Optimistic update
        habitCounts[habit] = newCount

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            _ = try await repository.upsertLog(habitType: habit, date: today, count: newCount)
            error = nil
        } catch {
            habitCounts[habit] = previousCount
            self.error = error
        }
    }

    func resetCount(for habit: HabitType) async {
        let previousCount = habitCounts[habit] ?? 0

        guard previousCount != 0 else { return }

        // Optimistic update
        habitCounts[habit] = 0

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            _ = try await repository.upsertLog(habitType: habit, date: today, count: 0)
            error = nil
        } catch {
            habitCounts[habit] = previousCount
            self.error = error
        }
    }
}
