import Foundation
import Supabase

/// Handles app launch flow: authenticates anonymously, then provides
/// access to authenticated services. No sign-in screen is shown.
final class AppLauncher: Sendable {
    let authManager: AuthManager
    let habitRepository: HabitRepository
    let logRepository: HabitLogRepository

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.authManager = AuthManager(client: client)
        self.habitRepository = HabitRepository(client: client, authManager: authManager)
        self.logRepository = HabitLogRepository(client: client, authManager: authManager)
    }

    /// Call on app launch. Ensures anonymous auth session exists,
    /// then returns the user ID for the habit dashboard.
    func launch() async throws -> String {
        let userId = try await authManager.ensureAuthenticated()
        return userId
    }
}
