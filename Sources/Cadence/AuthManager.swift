import Foundation
import Supabase

/// Manages anonymous authentication with Supabase.
/// The Supabase SDK automatically persists sessions between app launches.
final class AuthManager: Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.client = client
    }

    /// Ensures the user is authenticated. If no session exists, signs in anonymously.
    /// Returns the authenticated user's ID.
    @discardableResult
    func ensureAuthenticated() async throws -> String {
        // Check for an existing session first (persisted by the SDK)
        if let session = try? await client.auth.session {
            return session.user.id.uuidString.lowercased()
        }

        // No existing session — create an anonymous one
        let session = try await client.auth.signInAnonymously()
        return session.user.id.uuidString.lowercased()
    }

    /// Returns the current user ID, or nil if not authenticated.
    var currentUserId: String? {
        get async {
            guard let session = try? await client.auth.session else { return nil }
            return session.user.id.uuidString.lowercased()
        }
    }

    /// Returns true if the user has an active session.
    var isAuthenticated: Bool {
        get async {
            return await currentUserId != nil
        }
    }
}
