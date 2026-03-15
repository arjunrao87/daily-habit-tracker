import Foundation
import Supabase

/// Repository for reading and writing habit log data in Supabase.
final class HabitLogRepository {
    private let client: SupabaseClient
    private let table = "habit_logs"

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.client = client
    }

    /// Fetch all habit logs for a user on a given date.
    func fetchLogs(userId: String, date: String) async throws -> [HabitLog] {
        try await client
            .from(table)
            .select()
            .eq("user_id", value: userId)
            .eq("date", value: date)
            .execute()
            .value
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
