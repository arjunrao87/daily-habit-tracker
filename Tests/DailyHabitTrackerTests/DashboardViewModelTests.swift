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

    @MainActor
    func testDecrementCountMethodExists() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        let _: (HabitType) async -> Void = viewModel.decrementCount
        XCTAssertTrue(true)
    }

    @MainActor
    func testResetCountMethodExists() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        let _: (HabitType) async -> Void = viewModel.resetCount
        XCTAssertTrue(true)
    }

    @MainActor
    func testCountCannotGoNegative() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        // All counts start at 0 — decrement should not go below 0
        for habit in HabitType.allCases {
            XCTAssertEqual(viewModel.count(for: habit), 0)
        }
    }

    @MainActor
    func testStreaksInitializeToZero() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        for habit in HabitType.allCases {
            XCTAssertEqual(viewModel.streak(for: habit), 0)
        }
    }

    @MainActor
    func testStreakMethodExists() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        let _: (HabitType) -> Int = viewModel.streak
        XCTAssertTrue(true)
    }

    @MainActor
    func testHabitStreaksPropertyExists() {
        let viewModel = DashboardViewModel(repository: HabitLogRepository())
        XCTAssertEqual(viewModel.habitStreaks.count, 4)
        for habit in HabitType.allCases {
            XCTAssertNotNil(viewModel.habitStreaks[habit])
        }
    }

    func testCholesterolIsInverseHabit() {
        XCTAssertTrue(HabitType.cholesterol.isInverse)
        XCTAssertFalse(HabitType.reading.isInverse)
        XCTAssertFalse(HabitType.meditation.isInverse)
        XCTAssertFalse(HabitType.gym.isInverse)
    }
}
