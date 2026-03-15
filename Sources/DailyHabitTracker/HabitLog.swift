import Foundation

/// The four fixed habits tracked by the app.
enum HabitType: String, Codable, CaseIterable {
    case reading
    case meditation
    case gym
    case cholesterol
}

/// Represents a single row in the `habit_logs` table.
struct HabitLog: Codable, Identifiable {
    let id: UUID
    let userId: String
    let habitType: HabitType
    let date: String  // ISO 8601 date (yyyy-MM-dd)
    var count: Int
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case habitType = "habit_type"
        case date
        case count
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
