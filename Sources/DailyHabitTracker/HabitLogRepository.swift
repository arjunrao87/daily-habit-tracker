import Foundation
import Supabase

/// Repository for reading and writing habit log data in Supabase.
final class HabitLogRepository {
    private let client: SupabaseClient
    private let authManager: AuthManager
    private let table = "habit_logs"

    init(client: SupabaseClient = SupabaseConfig.client, authManager: AuthManager? = nil) {
        self.client = client
        self.authManager = authManager ?? AuthManager(client: client)
    }

    /// Ensures the user is authenticated and returns their user ID.
    private func authenticatedUserId() async throws -> String {
        try await authManager.ensureAuthenticated()
    }

    /// Fetch all habit logs for the authenticated user on a given date.
    func fetchLogs(date: String) async throws -> [HabitLog] {
        let userId = try await authenticatedUserId()
        return try await client
            .from(table)
            .select()
            .eq("user_id", value: userId)
            .eq("date", value: date)
            .execute()
            .value
    }

    /// Fetch all habit logs for a specific user on a given date.
    func fetchLogs(userId: String, date: String) async throws -> [HabitLog] {
        try await client
            .from(table)
            .select()
            .eq("user_id", value: userId)
            .eq("date", value: date)
            .execute()
            .value
    }

    /// Upsert a habit log for the authenticated user.
    func upsertLog(habitType: HabitType, date: String, count: Int) async throws -> HabitLog {
        let userId = try await authenticatedUserId()
        return try await upsertLog(userId: userId, habitType: habitType, date: date, count: count)
    }

    /// Upsert a habit log (insert or update on conflict).
    func upsertLog(userId: String, habitType: HabitType, date: String, count: Int) async throws -> HabitLog {
        let payload: [String: AnyJSON] = [
            "user_id": .string(userId),
            "habit_type": .string(habitType.rawValue),
            "date": .string(date),
            "count": .integer(count)
        ]

        let response: [HabitLog] = try await client
            .from(table)
            .upsert(payload, onConflict: "user_id,habit_type,date")
            .select()
            .execute()
            .value

        guard let log = response.first else {
            throw HabitLogError.upsertFailed
        }
        return log
    }

    /// Fetch habit logs for the authenticated user within a date range (for streak calculation).
    func fetchLogs(from startDate: String, to endDate: String) async throws -> [HabitLog] {
        let userId = try await authenticatedUserId()
        return try await fetchLogs(userId: userId, from: startDate, to: endDate)
    }

    /// Fetch habit logs for a user within a date range (for streak calculation).
    func fetchLogs(userId: String, from startDate: String, to endDate: String) async throws -> [HabitLog] {
        try await client
            .from(table)
            .select()
            .eq("user_id", value: userId)
            .gte("date", value: startDate)
            .lte("date", value: endDate)
            .order("date", ascending: false)
            .execute()
            .value
    }
}

enum HabitLogError: Error {
    case upsertFailed
}
