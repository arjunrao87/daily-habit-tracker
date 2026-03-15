import XCTest
@testable import DailyHabitTracker

final class DashboardViewModelTests: XCTestCase {

    private func makeHabit(
        name: String = "Test",
        icon: String = "star.fill",
        color: String = "blue",
        isInverse: Bool = false
    ) -> Habit {
        Habit(
            id: UUID(),
            userId: "test-user",
            name: name,
            icon: icon,
            color: color,
            isInverse: isInverse,
            sortOrder: 0,
            createdAt: nil
        )
    }

    @MainActor
    func testViewModelInitializesEmpty() {
        let viewModel = DashboardViewModel(
            habitRepository: HabitRepository(),
            logRepository: HabitLogRepository()
        )
        XCTAssertTrue(viewModel.habits.isEmpty)
        XCTAssertTrue(viewModel.habitCounts.isEmpty)
    }

    @MainActor
    func testTodayDisplayDateIsNotEmpty() {
        let viewModel = DashboardViewModel(
            habitRepository: HabitRepository(),
            logRepository: HabitLogRepository()
        )
        XCTAssertFalse(viewModel.todayDisplayDate.isEmpty)
    }

    @MainActor
    func testCountReturnsZeroForUnknownHabit() {
        let viewModel = DashboardViewModel(
            habitRepository: HabitRepository(),
            logRepository: HabitLogRepository()
        )
        let habit = makeHabit()
        XCTAssertEqual(viewModel.count(for: habit), 0)
    }

    @MainActor
    func testStreakReturnsZeroForUnknownHabit() {
        let viewModel = DashboardViewModel(
            habitRepository: HabitRepository(),
            logRepository: HabitLogRepository()
        )
        let habit = makeHabit()
        XCTAssertEqual(viewModel.streak(for: habit), 0)
    }

    func testHabitInverseProperty() {
        let inverse = makeHabit(isInverse: true)
        let normal = makeHabit(isInverse: false)
        XCTAssertTrue(inverse.isInverse)
        XCTAssertFalse(normal.isInverse)
    }

    func testHabitHashable() {
        let habit1 = makeHabit(name: "A")
        let habit2 = makeHabit(name: "B")
        var set: Set<Habit> = []
        set.insert(habit1)
        set.insert(habit2)
        XCTAssertEqual(set.count, 2)
    }
}
