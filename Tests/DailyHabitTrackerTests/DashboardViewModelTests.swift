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

    @MainActor
    func testCountReturnsZeroForUnsetHabit() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        // All habits start at 0
        for habit in HabitType.allCases {
            XCTAssertEqual(viewModel.count(for: habit), 0)
        }
    }

    @MainActor
    func testIncrementCountMethodExists() {
        // Verify the incrementCount method is available on the view model
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        // The method exists and can be referenced (compile-time check)
        let _: (HabitType) async -> Void = viewModel.incrementCount
        XCTAssertTrue(true)
    }
}
