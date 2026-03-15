import XCTest
@testable import DailyHabitTracker

final class AuthManagerTests: XCTestCase {

    func testAuthManagerInitializes() {
        // Verify AuthManager can be created without crashing
        // (actual Supabase calls require a running instance)
        let manager = AuthManager()
        XCTAssertNotNil(manager)
    }

    func testAppLauncherInitializes() {
        // Verify AppLauncher can be created and has both auth and repository
        let launcher = AppLauncher()
        XCTAssertNotNil(launcher.authManager)
        XCTAssertNotNil(launcher.habitRepository)
        XCTAssertNotNil(launcher.logRepository)
    }

    func testHabitLogRepositoryWithAuthManager() {
        // Verify repository can be created with an explicit AuthManager
        let authManager = AuthManager()
        let repo = HabitLogRepository(authManager: authManager)
        XCTAssertNotNil(repo)
    }
}
