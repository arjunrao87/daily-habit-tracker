import Foundation
import Supabase

/// Handles app launch flow: authenticates anonymously, then provides
/// access to authenticated services. No sign-in screen is shown.
final class AppLauncher {
    let authManager: AuthManager
    let repository: HabitLogRepository

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.authManager = AuthManager(client: client)
        self.repository = HabitLogRepository(client: client, authManager: authManager)
    }

    /// Call on app launch. Ensures anonymous auth session exists,
    /// then returns the user ID for the habit dashboard.
    func launch() async throws -> String {
        let userId = try await authManager.ensureAuthenticated()
        return userId
    }
}
