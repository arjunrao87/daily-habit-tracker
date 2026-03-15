import Foundation
import Supabase

/// Central Supabase client configuration.
/// Set your project URL and anon key via environment variables or replace the placeholders.
enum SupabaseConfig {
    static let url: URL = {
        guard let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL environment variable is not set or invalid")
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY environment variable is not set")
        }
        return key
    }()

    static let client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
}
