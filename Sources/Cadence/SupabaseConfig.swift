import Foundation
import Supabase

enum SupabaseConfig {
    private static let defaultURL = "https://ottrmtmnndmwtkntkfaq.supabase.co"
    private static let defaultAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90dHJtdG1ubmRtd3RrbnRrZmFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2MDAxODMsImV4cCI6MjA4OTE3NjE4M30.DW0HWOvc8Huoo7ZOA10jYXSkaskr3uIrp2G3lX2dkJE"

    static let url: URL = {
        let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? defaultURL
        guard let url = URL(string: urlString) else {
            fatalError("Invalid SUPABASE_URL: \(urlString)")
        }
        return url
    }()

    static let anonKey: String = {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? defaultAnonKey
    }()

    static let client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
}
