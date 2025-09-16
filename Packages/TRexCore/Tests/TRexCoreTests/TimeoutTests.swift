import XCTest
@testable import TRexCore

final class TimeoutTests: XCTestCase {
    func testWithTimeoutSucceeds() async throws {
        let value = try await withTimeout(seconds: 1.0) {
            try await Task.sleep(nanoseconds: 100_000_000)
            return "done"
        }

        XCTAssertEqual(value, "done")
    }

    func testWithTimeoutTimesOut() async {
        do {
            _ = try await withTimeout(seconds: 0.1) {
                try await Task.sleep(nanoseconds: 500_000_000)
                return "slow"
            }
            XCTFail("Expected timeout to throw")
        } catch {
            guard case TimeoutError.timedOut = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }
}
