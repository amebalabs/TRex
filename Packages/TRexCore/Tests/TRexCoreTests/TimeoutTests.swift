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

    func testWithTimeoutDoesNotWaitForUncooperativeOperation() async {
        let clock = ContinuousClock()
        let start = clock.now

        do {
            _ = try await withTimeout(seconds: 0.05) {
                await withCheckedContinuation { continuation in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume(returning: "late")
                    }
                }
            }
            XCTFail("Expected timeout")
        } catch TimeoutError.timedOut {
            XCTAssertLessThan(start.duration(to: clock.now), .milliseconds(250))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
