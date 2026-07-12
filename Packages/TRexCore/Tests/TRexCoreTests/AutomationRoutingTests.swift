import XCTest
@testable import TRexCore

final class AutomationRoutingTests: XCTestCase {
    func testNormalCaptureAlwaysKeepsClipboardRoute() {
        XCTAssertFalse(
            TRex.shouldRouteToAutomation(
                mode: .captureScreen,
                autoOpenProvidedURL: "https://example.com/?text={text}",
                autoRunShortcut: "Process OCR"
            )
        )
    }

    func testAutomationCaptureNeedsMeaningfulConfiguration() {
        XCTAssertFalse(
            TRex.shouldRouteToAutomation(
                mode: .captureScreenAndTriggerAutomation,
                autoOpenProvidedURL: " \n",
                autoRunShortcut: "\t"
            )
        )
        XCTAssertTrue(
            TRex.shouldRouteToAutomation(
                mode: .captureScreenAndTriggerAutomation,
                autoOpenProvidedURL: "",
                autoRunShortcut: "Process OCR"
            )
        )
        XCTAssertTrue(
            TRex.shouldRouteToAutomation(
                mode: .captureClipboardAndTriggerAutomation,
                autoOpenProvidedURL: "https://example.com/?text={text}",
                autoRunShortcut: ""
            )
        )
    }
}
