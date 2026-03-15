import XCTest
@testable import DailyHabitTracker

final class HabitLogTests: XCTestCase {

    func testHabitLogDecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "test-user-123",
            "habit_type": "reading",
            "date": "2026-03-15",
            "count": 3,
            "created_at": "2026-03-15T10:00:00Z",
            "updated_at": "2026-03-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let log = try JSONDecoder().decode(HabitLog.self, from: json)

        XCTAssertEqual(log.id, UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000"))
        XCTAssertEqual(log.userId, "test-user-123")
        XCTAssertEqual(log.habitType, .reading)
        XCTAssertEqual(log.date, "2026-03-15")
        XCTAssertEqual(log.count, 3)
        XCTAssertNotNil(log.createdAt)
        XCTAssertNotNil(log.updatedAt)
    }

    func testHabitLogEncoding() throws {
        let log = HabitLog(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            userId: "test-user-123",
            habitType: .meditation,
            date: "2026-03-15",
            count: 1,
            createdAt: nil,
            updatedAt: nil
        )

        let data = try JSONEncoder().encode(log)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["user_id"] as? String, "test-user-123")
        XCTAssertEqual(dict["habit_type"] as? String, "meditation")
        XCTAssertEqual(dict["count"] as? Int, 1)
    }

    func testHabitTypeCases() {
        let cases = HabitType.allCases.map(\.rawValue)
        XCTAssertEqual(cases, ["reading", "meditation", "gym", "cholesterol"])
    }

    func testHabitTypeIconNames() {
        XCTAssertEqual(HabitType.reading.iconName, "book.fill")
        XCTAssertEqual(HabitType.meditation.iconName, "brain")
        XCTAssertEqual(HabitType.gym.iconName, "dumbbell.fill")
        XCTAssertEqual(HabitType.cholesterol.iconName, "fork.knife")
    }

    func testHabitTypeDisplayNames() {
        XCTAssertEqual(HabitType.reading.displayName, "Reading")
        XCTAssertEqual(HabitType.meditation.displayName, "Meditation")
        XCTAssertEqual(HabitType.gym.displayName, "Gym")
        XCTAssertEqual(HabitType.cholesterol.displayName, "Cholesterol")
    }

    func testAllHabitsHaveDistinctIcons() {
        let icons = Set(HabitType.allCases.map(\.iconName))
        XCTAssertEqual(icons.count, 4, "Each habit should have a unique icon")
    }
}
