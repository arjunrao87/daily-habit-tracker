import Foundation
import Supabase

/// Repository for reading and writing habit log data in Supabase.
final class HabitLogRepository: Sendable {
    private let client: SupabaseClient
    private let authManager: AuthManager
    private let table = "habit_logs"

    init(client: SupabaseClient = SupabaseConfig.client, authManager: AuthManager? = nil) {
        self.client = client
        self.authManager = authManager ?? AuthManager(client: client)
    }

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
            .not("habit_id", operator: .is, value: "null")
            .execute()
            .value
    }

    /// Upsert a habit log for the authenticated user.
    func upsertLog(habitId: UUID, date: String, count: Int) async throws -> HabitLog {
        let userId = try await authenticatedUserId()

        let payload: [String: AnyJSON] = [
            "user_id": .string(userId),
            "habit_id": .string(habitId.uuidString),
            "date": .string(date),
            "count": .integer(count)
        ]

        let response: [HabitLog] = try await client
            .from(table)
            .upsert(payload, onConflict: "user_id,habit_id,date")
            .select()
            .execute()
            .value

        guard let log = response.first else {
            throw HabitLogError.upsertFailed
        }
        return log
    }

    /// Fetch habit logs for the authenticated user within a date range.
    func fetchLogs(from startDate: String, to endDate: String) async throws -> [HabitLog] {
        let userId = try await authenticatedUserId()
        return try await client
            .from(table)
            .select()
            .eq("user_id", value: userId)
            .not("habit_id", operator: .is, value: "null")
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
