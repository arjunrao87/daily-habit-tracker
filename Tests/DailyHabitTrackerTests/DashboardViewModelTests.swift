import XCTest
@testable import DailyHabitTracker

final class DashboardViewModelTests: XCTestCase {
    @MainActor
    func testViewModelInitializesWithZeroCounts() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        for habit in HabitType.allCases {
            XCTAssertEqual(viewModel.count(for: habit), 0)
        }
    }

    @MainActor
    func testTodayDisplayDateIsNotEmpty() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        XCTAssertFalse(viewModel.todayDisplayDate.isEmpty)
    }

    @MainActor
    func testAllFourHabitsHaveCards() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        let habits = HabitType.allCases
        XCTAssertEqual(habits.count, 4)
        XCTAssertEqual(viewModel.habitCounts.count, 4)
        for habit in habits {
            XCTAssertNotNil(viewModel.habitCounts[habit])
        }
    }
}
