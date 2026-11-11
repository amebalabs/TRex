import Cocoa
import CoreGraphics
import OSLog
import ScreenCaptureKit

/// Shows a "frozen" snapshot of every connected display as a full-screen backdrop while the
/// user selects a region. Useful when the underlying content is moving (video, animation,
/// hover galleries) and the standard interactive selection would chase the content as it
/// changes.
///
/// The backdrop is passive: the selection UI itself (crosshair, drag rectangle, Escape to
/// cancel) belongs to the caller-supplied `selection`, normally the native `screencapture -i`,
/// which draws above the backdrop and captures the frozen pixels beneath its selection.
@MainActor
public enum FrozenScreenSelectionOverlay {
    /// Freezes every display, runs `selection` on top of the frozen stills, and returns its
    /// result. Returns nil without running `selection` if no display could be captured.
    public static func selectRegion(using selection: @MainActor () async -> NSImage?) async -> NSImage? {
        FrozenLogger.shared.info("🧊 FrozenScreenSelectionOverlay.selectRegion() invoked")

        // Capture every display BEFORE we put up any UI — if we did it after, our overlays
        // would appear in the screenshot.
        let captures = await captureAllDisplays()
        FrozenLogger.shared.info("🧊 Captured \(captures.count, privacy: .public) display(s)")
        if captures.isEmpty {
            FrozenLogger.shared.error("🧊 No displays could be captured for freeze overlay — likely Screen Recording permission missing")
            return nil
        }

        // The windows are passive and never become key, so TRex is not activated. Activating
        // the app (and bumping the LSUIElement app to .regular) made macOS switch Spaces to
        // TRex, sliding every window off-screen and back.
        let windows = captures.map { screen, cgImage in
            FrozenLogger.shared.info("🧊 Building window for screen \(screen.frame.debugDescription, privacy: .public) image=\(cgImage.width, privacy: .public)x\(cgImage.height, privacy: .public)")
            return FrozenScreenWindow(frame: screen.frame, screenshot: cgImage)
        }
        FrozenLogger.shared.info("🧊 Ordering \(windows.count, privacy: .public) window(s)")
        for window in windows {
            window.orderFrontRegardless()
        }
        defer {
            for window in windows {
                window.orderOut(nil)
                window.close()
            }
        }

        return await selection()
    }

    /// Use ScreenCaptureKit's one-shot screenshot API (macOS 14.0+) to grab a still of each
    /// connected display and pair it with its matching NSScreen.
    private static func captureAllDisplays() async -> [(NSScreen, CGImage)] {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            var results: [(NSScreen, CGImage)] = []
            for display in content.displays {
                guard let screen = NSScreen.screens.first(where: { $0.displayID == display.displayID }) else {
                    continue
                }
                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                config.width = display.width * Int(screen.backingScaleFactor)
                config.height = display.height * Int(screen.backingScaleFactor)
                config.showsCursor = false
                config.capturesAudio = false
                do {
                    let image = try await SCScreenshotManager.captureImage(
                        contentFilter: filter,
                        configuration: config
                    )
                    results.append((screen, image))
                } catch {
                    FrozenLogger.shared.error("Screenshot failed for display \(display.displayID): \(error.localizedDescription, privacy: .public)")
                }
            }
            return results
        } catch {
            FrozenLogger.shared.error("SCShareableContent failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}

// MARK: - Logger holder

private enum FrozenLogger {
    static let shared = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ameba.TRex",
        category: "FrozenSelection"
    )
}

// MARK: - NSScreen helper

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}

// MARK: - Window

/// Full-screen still of one display. Passive by design: it ignores mouse events and never
/// becomes key, so the selection UI running above it receives all input.
@MainActor
final class FrozenScreenWindow: NSPanel {
    init(frame: NSRect, screenshot: CGImage) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = true
        self.backgroundColor = .black
        self.hasShadow = false
        // On macOS 27 this window zooms in when ordered front and zooms out when ordered out.
        // Because this window shows a screenshot of the desktop, the zoom makes every on-screen
        // window appear to slide or shift when the selection starts and ends.
        self.animationBehavior = .none
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        self.ignoresMouseEvents = true
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.setFrame(frame, display: true)
        self.contentView = FrozenScreenView(screenshot: screenshot)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - Still view

@MainActor
final class FrozenScreenView: NSView {
    private let screenshot: CGImage

    init(screenshot: CGImage) {
        self.screenshot = screenshot
        super.init(frame: .zero)
        self.wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Frozen screen content at full brightness — no dim, the freeze itself is the cue
        // that selection mode is active.
        ctx.draw(screenshot, in: bounds)
    }
}
