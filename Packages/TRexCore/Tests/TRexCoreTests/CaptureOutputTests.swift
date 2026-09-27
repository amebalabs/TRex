import XCTest
@testable import TRexCore

@MainActor
final class CaptureOutputTests: XCTestCase {
    func testCLIOutputIsEmittedEvenWhenClipboardWriteFails() {
        var printed = [String]()

        let wroteToClipboard = TRex.emitCaptureOutput(
            "recognized text",
            isCLI: true,
            writeToClipboard: { _ in false },
            printLine: { printed.append($0) }
        )

        XCTAssertFalse(wroteToClipboard)
        XCTAssertEqual(printed, ["recognized text"])
    }

    func testCLIOutputIsEmittedWhenClipboardWriteSucceeds() {
        var printed = [String]()

        let wroteToClipboard = TRex.emitCaptureOutput(
            "recognized text",
            isCLI: true,
            writeToClipboard: { _ in true },
            printLine: { printed.append($0) }
        )

        XCTAssertTrue(wroteToClipboard)
        XCTAssertEqual(printed, ["recognized text"])
    }

    func testGUIInvocationDoesNotPrintToStandardOutput() {
        var printed = [String]()

        _ = TRex.emitCaptureOutput(
            "recognized text",
            isCLI: false,
            writeToClipboard: { _ in true },
            printLine: { printed.append($0) }
        )

        XCTAssertTrue(printed.isEmpty)
    }
}
