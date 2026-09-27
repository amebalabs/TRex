import XCTest
@testable import TRexCore

@MainActor
final class PasteboardWriterTests: XCTestCase {
    private var pasteboards: [NSPasteboard] = []

    private func makePasteboard() -> NSPasteboard {
        let pasteboard = NSPasteboard(name: .init("TRexCoreTests.\(UUID().uuidString)"))
        pasteboards.append(pasteboard)
        return pasteboard
    }

    override func tearDown() {
        // Named pasteboards persist until logout unless released.
        for pasteboard in pasteboards {
            pasteboard.releaseGlobally()
        }
        pasteboards.removeAll()
        super.tearDown()
    }

    func testReplacesTextOnAnIsolatedPasteboard() {
        let pasteboard = makePasteboard()
        XCTAssertTrue(pasteboard.setString("before", forType: .string))

        XCTAssertTrue(PasteboardWriter.replaceString("after", in: pasteboard))
        XCTAssertEqual(pasteboard.string(forType: .string), "after")
    }

    func testRestoresPreviousPayloadWhenWriteFailsAndSnapshotIsAllowed() {
        let pasteboard = makePasteboard()
        XCTAssertTrue(pasteboard.setString("before", forType: .string))

        let success = PasteboardWriter.replaceString("after", in: pasteboard, snapshotAllowed: true) { _, _ in false }

        XCTAssertFalse(success)
        XCTAssertEqual(pasteboard.string(forType: .string), "before")
    }

    func testDoesNotReadOrRestorePreviousPayloadWhenSnapshotIsNotAllowed() {
        let pasteboard = makePasteboard()
        XCTAssertTrue(pasteboard.setString("before", forType: .string))

        let success = PasteboardWriter.replaceString("after", in: pasteboard, snapshotAllowed: false) { _, _ in false }

        XCTAssertFalse(success)
        // Without a snapshot there is nothing to restore: the pasteboard was
        // cleared but never read, so no privacy prompt can be triggered.
        XCTAssertNil(pasteboard.string(forType: .string))
    }

    func testSnapshotPolicyNeverAllowsPromptingReads() {
        let pasteboard = makePasteboard()

        if #available(macOS 15.4, *) {
            // Snapshots are allowed only when read access is already granted,
            // for automatic and user-initiated writes alike.
            let readAccessGranted = pasteboard.accessBehavior == .alwaysAllow
            XCTAssertEqual(
                PasteboardWriter.shouldSnapshotBeforeWriting(userInitiated: false, in: pasteboard),
                readAccessGranted
            )
            XCTAssertEqual(
                PasteboardWriter.shouldSnapshotBeforeWriting(userInitiated: true, in: pasteboard),
                readAccessGranted
            )
        } else {
            // Without a way to check access, only user-initiated writes may
            // snapshot; automatic OCR/watch-mode writes never read.
            XCTAssertFalse(PasteboardWriter.shouldSnapshotBeforeWriting(userInitiated: false, in: pasteboard))
            XCTAssertTrue(PasteboardWriter.shouldSnapshotBeforeWriting(userInitiated: true, in: pasteboard))
        }
    }
}
