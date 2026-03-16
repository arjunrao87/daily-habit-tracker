import XCTest
@testable import Cadence

final class NetworkMonitorTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let monitor = NetworkMonitor()
        XCTAssertTrue(monitor.isConnected)
    }
}
