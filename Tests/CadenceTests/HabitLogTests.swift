import XCTest
@testable import Cadence

final class HabitLogTests: XCTestCase {

    func testHabitLogDecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "test-user-123",
            "habit_id": "660e8400-e29b-41d4-a716-446655440000",
            "date": "2026-03-15",
            "count": 3,
            "created_at": "2026-03-15T10:00:00Z",
            "updated_at": "2026-03-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let log = try JSONDecoder().decode(HabitLog.self, from: json)

        XCTAssertEqual(log.id, UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000"))
        XCTAssertEqual(log.userId, "test-user-123")
        XCTAssertEqual(log.habitId, UUID(uuidString: "660e8400-e29b-41d4-a716-446655440000"))
        XCTAssertEqual(log.date, "2026-03-15")
        XCTAssertEqual(log.count, 3)
        XCTAssertNotNil(log.createdAt)
        XCTAssertNotNil(log.updatedAt)
    }

    func testHabitLogEncoding() throws {
        let log = HabitLog(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            userId: "test-user-123",
            habitId: UUID(uuidString: "660e8400-e29b-41d4-a716-446655440000")!,
            date: "2026-03-15",
            count: 1,
            createdAt: nil,
            updatedAt: nil
        )

        let data = try JSONEncoder().encode(log)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["user_id"] as? String, "test-user-123")
        XCTAssertEqual(dict["habit_id"] as? String, "660E8400-E29B-41D4-A716-446655440000")
        XCTAssertEqual(dict["count"] as? Int, 1)
    }

    func testHabitDecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "test-user-123",
            "name": "Reading",
            "icon": "book.fill",
            "color": "blue",
            "is_inverse": false,
            "sort_order": 0,
            "created_at": "2026-03-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let habit = try JSONDecoder().decode(Habit.self, from: json)

        XCTAssertEqual(habit.name, "Reading")
        XCTAssertEqual(habit.icon, "book.fill")
        XCTAssertEqual(habit.color, "blue")
        XCTAssertFalse(habit.isInverse)
        XCTAssertEqual(habit.sortOrder, 0)
    }

    func testHabitSwiftUIColor() {
        let habit = makeHabit(color: "purple")
        // Just verify it doesn't crash for all available colors
        for color in Habit.availableColors {
            let h = makeHabit(color: color)
            _ = h.swiftUIColor
        }
        _ = habit.swiftUIColor
    }

    func testAvailableIconsAndColors() {
        XCTAssertGreaterThan(Habit.availableIcons.count, 0)
        XCTAssertGreaterThan(Habit.availableColors.count, 0)
        // All icons should be unique
        XCTAssertEqual(Set(Habit.availableIcons).count, Habit.availableIcons.count)
    }

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
}
