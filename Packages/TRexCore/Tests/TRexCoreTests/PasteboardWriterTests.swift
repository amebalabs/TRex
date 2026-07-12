import XCTest
@testable import TRexCore

@MainActor
final class PasteboardWriterTests: XCTestCase {
    func testReplacesTextOnAnIsolatedPasteboard() {
        let pasteboard = NSPasteboard(name: .init("TRexCoreTests.\(UUID().uuidString)"))
        XCTAssertTrue(pasteboard.setString("before", forType: .string))

        XCTAssertTrue(PasteboardWriter.replaceString("after", in: pasteboard))
        XCTAssertEqual(pasteboard.string(forType: .string), "after")
    }

    func testRestoresPreviousPayloadWhenWriteFails() {
        let pasteboard = NSPasteboard(name: .init("TRexCoreTests.\(UUID().uuidString)"))
        XCTAssertTrue(pasteboard.setString("before", forType: .string))

        let success = PasteboardWriter.replaceString("after", in: pasteboard) { _, _ in false }

        XCTAssertFalse(success)
        XCTAssertEqual(pasteboard.string(forType: .string), "before")
    }
}
