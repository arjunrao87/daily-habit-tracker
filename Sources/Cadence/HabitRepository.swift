import Foundation
import Supabase

/// Repository for CRUD operations on user-defined habits.
final class HabitRepository: Sendable {
    private let client: SupabaseClient
    private let authManager: AuthManager
    private let table = "habits"

    init(client: SupabaseClient = SupabaseConfig.client, authManager: AuthManager? = nil) {
        self.client = client
        self.authManager = authManager ?? AuthManager(client: client)
    }

    private func authenticatedUserId() async throws -> String {
        try await authManager.ensureAuthenticated()
    }

    /// Fetch all habits for the authenticated user, ordered by sort_order.
    func fetchHabits() async throws -> [Habit] {
        let userId = try await authenticatedUserId()
        return try await client
            .from(table)
            .select()
            .eq("user_id", value: userId)
            .order("sort_order", ascending: true)
            .execute()
            .value
    }

    /// Create a new habit.
    func createHabit(name: String, icon: String, color: String, isInverse: Bool) async throws -> Habit {
        let userId = try await authenticatedUserId()

        // Get next sort_order
        let existing: [Habit] = try await client
            .from(table)
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        let nextOrder = (existing.map(\.sortOrder).max() ?? -1) + 1

        let payload: [String: AnyJSON] = [
            "user_id": .string(userId),
            "name": .string(name),
            "icon": .string(icon),
            "color": .string(color),
            "is_inverse": .bool(isInverse),
            "sort_order": .integer(nextOrder)
        ]

        let response: [Habit] = try await client
            .from(table)
            .insert(payload)
            .select()
            .execute()
            .value

        guard let habit = response.first else {
            throw HabitError.createFailed
        }
        return habit
    }

    /// Update an existing habit.
    func updateHabit(_ habit: Habit) async throws -> Habit {
        let payload: [String: AnyJSON] = [
            "name": .string(habit.name),
            "icon": .string(habit.icon),
            "color": .string(habit.color),
            "is_inverse": .bool(habit.isInverse),
            "sort_order": .integer(habit.sortOrder)
        ]

        let response: [Habit] = try await client
            .from(table)
            .update(payload)
            .eq("id", value: habit.id.uuidString)
            .select()
            .execute()
            .value

        guard let updated = response.first else {
            throw HabitError.updateFailed
        }
        return updated
    }

    /// Delete a habit. Associated logs are cascade-deleted.
    func deleteHabit(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

enum HabitError: Error {
    case createFailed
    case updateFailed
}
