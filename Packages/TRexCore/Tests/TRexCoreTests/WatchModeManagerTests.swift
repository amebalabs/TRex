import XCTest
@testable import TRexCore

final class WatchModeManagerTests: XCTestCase {
    func testClipboardOutputCombinesNonEmptyCaptures() {
        XCTAssertEqual(WatchModeManager.combinedClipboardText(existing: "", next: "first"), "first")
        XCTAssertEqual(
            WatchModeManager.combinedClipboardText(existing: "first", next: "second"),
            "first\n---\nsecond"
        )
    }

    func testClipboardOutputRejectsWhitespaceOnlyCapture() {
        XCTAssertNil(WatchModeManager.combinedClipboardText(existing: "first", next: " \n\t "))
    }
}
