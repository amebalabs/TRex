import Cocoa
import CoreGraphics
import OSLog
import ScreenCaptureKit

/// Shows a "frozen" snapshot of every connected display as a full-screen overlay and lets the
/// user drag-select a region from the still image. Useful when the underlying content is moving
/// (video, animation, hover galleries) and the standard interactive selection would chase the
/// content as it changes.
@MainActor
public enum FrozenScreenSelectionOverlay {
    /// Returns the cropped pixel image of the user's selection, or nil if cancelled / failed.
    public static func selectRegion() async -> NSImage? {
        await SelectionCoordinator().run()
    }
}

// MARK: - Coordinator

@MainActor
private final class SelectionCoordinator {
    private var windows: [SelectionWindow] = []
    private var continuation: CheckedContinuation<NSImage?, Never>?
    private var keyMonitor: Any?
    private var didResume = false
    private var previouslyActiveApp: NSRunningApplication?
    private var savedActivationPolicy: NSApplication.ActivationPolicy = .accessory

    func run() async -> NSImage? {
        FrozenLogger.shared.info("🧊 FrozenScreenSelectionOverlay.run() invoked")
        previouslyActiveApp = NSWorkspace.shared.frontmostApplication

        // Capture every display BEFORE we put up any UI — if we did it after, our overlays
        // would appear in the screenshot.
        let captures = await captureAllDisplays()
        FrozenLogger.shared.info("🧊 Captured \(captures.count, privacy: .public) display(s)")
        if captures.isEmpty {
            FrozenLogger.shared.error("🧊 No displays could be captured for freeze overlay — likely Screen Recording permission missing")
            return nil
        }

        return await withCheckedContinuation { (cont: CheckedContinuation<NSImage?, Never>) in
            self.continuation = cont
            self.start(with: captures)
        }
    }

    private func start(with captures: [(NSScreen, CGImage)]) {
        for (screen, cgImage) in captures {
            FrozenLogger.shared.info("🧊 Building window for screen \(screen.frame.debugDescription, privacy: .public) image=\(cgImage.width, privacy: .public)x\(cgImage.height, privacy: .public)")
            let window = SelectionWindow(screen: screen, screenshot: cgImage, coordinator: self)
            windows.append(window)
        }

        if windows.isEmpty {
            FrozenLogger.shared.error("🧊 No windows built")
            finish(with: nil)
            return
        }

        // LSUIElement apps need accessory policy bumped to .regular momentarily so windows
        // can become key and receive keyboard events; we restore on finish().
        savedActivationPolicy = NSApp.activationPolicy()
        if savedActivationPolicy != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
        FrozenLogger.shared.info("🧊 Activated app, ordering \(self.windows.count, privacy: .public) window(s)")

        // Pick the window under the mouse to become key so its first responder gets keyDown.
        let mouseLoc = NSEvent.mouseLocation
        let preferred = windows.first(where: { $0.screen?.frame.contains(mouseLoc) == true }) ?? windows.first
        for window in windows {
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
        }
        preferred?.makeKeyAndOrderFront(nil)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { // ESC
                self.finish(with: nil)
                return nil
            }
            return event
        }
    }

    func finish(with image: NSImage?) {
        guard !didResume else { return }
        didResume = true

        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }

        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()

        // Restore activation policy (accessory for menu-bar app) and focus.
        if NSApp.activationPolicy() != savedActivationPolicy {
            NSApp.setActivationPolicy(savedActivationPolicy)
        }
        if let previouslyActiveApp {
            previouslyActiveApp.activate()
        }

        continuation?.resume(returning: image)
        continuation = nil
    }

    /// Use ScreenCaptureKit's one-shot screenshot API (macOS 14.0+) to grab a still of each
    /// connected display and pair it with its matching NSScreen.
    private func captureAllDisplays() async -> [(NSScreen, CGImage)] {
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

@MainActor
private final class SelectionWindow: NSWindow {
    private let selectionView: SelectionView

    init(screen: NSScreen, screenshot: CGImage, coordinator: SelectionCoordinator) {
        self.selectionView = SelectionView(screenshot: screenshot, coordinator: coordinator)

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = true
        self.backgroundColor = .black
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        self.ignoresMouseEvents = false
        self.isReleasedWhenClosed = false
        self.acceptsMouseMovedEvents = true
        self.setFrame(screen.frame, display: true)
        self.contentView = selectionView
        self.initialFirstResponder = selectionView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Selection view

@MainActor
private final class SelectionView: NSView {
    private let screenshot: CGImage
    private weak var coordinator: SelectionCoordinator?
    private var dragStart: NSPoint?
    private var dragCurrent: NSPoint?
    private var trackingArea: NSTrackingArea?

    init(screenshot: CGImage, coordinator: SelectionCoordinator) {
        self.screenshot = screenshot
        self.coordinator = coordinator
        super.init(frame: .zero)
        self.wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .cursorUpdate, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Frozen screen content at full brightness — no dim, the freeze itself is the cue
        // that selection mode is active.
        ctx.draw(screenshot, in: bounds)

        // Selection rectangle outline only.
        if let rect = currentSelectionRect(), rect.width > 0, rect.height > 0 {
            ctx.setStrokeColor(NSColor.systemBlue.cgColor)
            ctx.setLineWidth(1.5)
            ctx.stroke(rect)

            // Dimension label
            let label = "\(Int(rect.width)) × \(Int(rect.height))"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor.white,
                .backgroundColor: NSColor.black.withAlphaComponent(0.55)
            ]
            let size = (label as NSString).size(withAttributes: attrs)
            let labelOrigin = NSPoint(
                x: min(rect.maxX - size.width - 6, bounds.maxX - size.width - 6),
                y: max(rect.minY - size.height - 4, bounds.minY + 4)
            )
            (label as NSString).draw(at: labelOrigin, withAttributes: attrs)
        }
    }

    private func currentSelectionRect() -> NSRect? {
        guard let start = dragStart, let current = dragCurrent else { return nil }
        return NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        dragStart = pt
        dragCurrent = pt
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        dragCurrent = pt
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentSelectionRect(), rect.width > 2, rect.height > 2 else {
            dragStart = nil
            dragCurrent = nil
            coordinator?.finish(with: nil)
            return
        }

        // View coords (origin bottom-left, points) → image coords (origin top-left, pixels).
        let viewWidth = bounds.width
        let viewHeight = bounds.height
        let imageWidth = CGFloat(screenshot.width)
        let imageHeight = CGFloat(screenshot.height)
        let scaleX = imageWidth / viewWidth
        let scaleY = imageHeight / viewHeight

        let cropRect = CGRect(
            x: rect.minX * scaleX,
            y: (viewHeight - rect.maxY) * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        ).integral

        dragStart = nil
        dragCurrent = nil

        guard let cropped = screenshot.cropping(to: cropRect) else {
            coordinator?.finish(with: nil)
            return
        }

        let nsImage = NSImage(
            cgImage: cropped,
            size: NSSize(width: cropped.width, height: cropped.height)
        )
        coordinator?.finish(with: nsImage)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            coordinator?.finish(with: nil)
        } else {
            super.keyDown(with: event)
        }
    }
}
