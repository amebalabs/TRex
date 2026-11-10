import AppKit
import XCTest

@testable import TRexCore

@MainActor
final class FrozenScreenWindowTests: XCTestCase {
    private func makeScreenshot(red: CGFloat, green: CGFloat, blue: CGFloat) throws -> CGImage {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 8,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        return try XCTUnwrap(context.makeImage())
    }

    /// The native selection UI runs above the frozen still and must receive every mouse and
    /// key event, so the still may neither intercept the mouse nor take key status.
    func testWindowLeavesAllInputToTheSelectionUI() throws {
        let window = FrozenScreenWindow(
            frame: NSRect(x: 0, y: 0, width: 100, height: 100),
            screenshot: try makeScreenshot(red: 1, green: 0, blue: 0)
        )

        XCTAssertTrue(window.ignoresMouseEvents)
        XCTAssertFalse(window.canBecomeKey)
        XCTAssertFalse(window.canBecomeMain)
        XCTAssertEqual(window.animationBehavior, .none)
        XCTAssertEqual(window.frame.size, NSSize(width: 100, height: 100))
    }

    func testViewDrawsTheFrozenScreenshot() throws {
        let view = FrozenScreenView(screenshot: try makeScreenshot(red: 0, green: 1, blue: 0))
        view.frame = NSRect(x: 0, y: 0, width: 20, height: 20)

        let rep = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: rep)

        let color = try XCTUnwrap(rep.colorAt(x: rep.pixelsWide / 2, y: rep.pixelsHigh / 2)?.usingColorSpace(.deviceRGB))
        XCTAssertEqual(color.redComponent, 0, accuracy: 0.05)
        XCTAssertEqual(color.greenComponent, 1, accuracy: 0.05)
        XCTAssertEqual(color.blueComponent, 0, accuracy: 0.05)
    }
}
