import AppKit
import XCTest

@testable import TRexCore

@MainActor
final class FrozenSelectionCursorTests: XCTestCase {
    private func makeView() throws -> FrozenSelectionView {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 8,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        return FrozenSelectionView(screenshot: try XCTUnwrap(context.makeImage()))
    }

    func testEnteringAnotherNonKeyOverlayRestoresCrosshair() throws {
        let first = try makeView()
        let second = try makeView()
        let windows = [first, second].map { view in
            let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            window.contentView = view
            return window
        }
        defer { NSCursor.arrow.set() }
        for view in [first, second, first] {
            XCTAssertFalse(try XCTUnwrap(view.window).isKeyWindow)
            NSCursor.arrow.set()
            let event = try XCTUnwrap(NSEvent.enterExitEvent(
                with: .mouseEntered, location: .zero, modifierFlags: [], timestamp: 0,
                windowNumber: try XCTUnwrap(view.window).windowNumber, context: nil,
                eventNumber: 0, trackingNumber: 0, userData: nil
            ))
            view.mouseEntered(with: event)
            XCTAssertEqual(NSCursor.current, .crosshair)
        }
        withExtendedLifetime(windows) {}
    }

    func testMovementRestoresCrosshairAfterAppKitResetsIt() throws {
        let view = try makeView()
        view.frame = NSRect(x: 0, y: 0, width: 100, height: 100)
        view.updateTrackingAreas()
        XCTAssertTrue(view.trackingAreas.contains { $0.options.contains([.activeAlways, .mouseMoved]) })
        let event = try XCTUnwrap(NSEvent.mouseEvent(
            with: .mouseMoved, location: NSPoint(x: 10, y: 10), modifierFlags: [],
            timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0,
            clickCount: 0, pressure: 0
        ))
        defer { NSCursor.arrow.set() }
        NSCursor.arrow.set()
        view.mouseMoved(with: event)
        XCTAssertEqual(NSCursor.current, .crosshair)
    }
}
