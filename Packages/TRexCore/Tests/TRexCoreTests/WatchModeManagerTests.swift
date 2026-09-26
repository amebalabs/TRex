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

    // pollTick marks a frame as processed (advancing lastImageHash) whenever
    // hasRecognizedText is false, so whitespace-only OCR output must be
    // classified the same way as empty output.
    func testWhitespaceOnlyCaptureCountsAsUnrecognizedText() {
        XCTAssertFalse(WatchModeManager.hasRecognizedText(""))
        XCTAssertFalse(WatchModeManager.hasRecognizedText(" \n\t "))
        XCTAssertTrue(WatchModeManager.hasRecognizedText(" some text "))
    }
}
