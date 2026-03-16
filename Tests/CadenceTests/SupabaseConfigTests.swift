import XCTest
@testable import Cadence

final class SupabaseConfigTests: XCTestCase {
    func testURLIsValid() {
        let url = SupabaseConfig.url
        XCTAssertEqual(url.scheme, "https")
        XCTAssertTrue(url.host?.contains("supabase") ?? false)
    }

    func testAnonKeyIsNotEmpty() {
        let key = SupabaseConfig.anonKey
        XCTAssertFalse(key.isEmpty)
    }
}
