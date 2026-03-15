import Foundation
import SwiftUI

/// A user-defined habit.
struct Habit: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let userId: String
    var name: String
    var icon: String
    var color: String
    var isInverse: Bool
    var sortOrder: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case icon
        case color
        case isInverse = "is_inverse"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    var swiftUIColor: Color {
        switch color {
        case "blue": .blue
        case "purple": .purple
        case "green": .green
        case "orange": .orange
        case "red": .red
        case "pink": .pink
        case "teal": .teal
        case "indigo": .indigo
        default: .blue
        }
    }

    static let availableIcons = [
        "book.fill", "brain", "dumbbell.fill", "fork.knife",
        "heart.fill", "moon.fill", "drop.fill", "flame.fill",
        "leaf.fill", "star.fill", "music.note", "pencil",
        "paintbrush.fill", "camera.fill", "bicycle", "figure.walk",
        "cup.and.saucer.fill", "pills.fill", "bed.double.fill", "clock.fill"
    ]

    static let availableColors = [
        "blue", "purple", "green", "orange", "red", "pink", "teal", "indigo"
    ]
}

/// Represents a single row in the `habit_logs` table.
struct HabitLog: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: String
    let habitId: UUID
    let date: String
    var count: Int
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case habitId = "habit_id"
        case date
        case count
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
