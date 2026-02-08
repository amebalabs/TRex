import Cocoa
import OSLog

/// Uses the native macOS `screencapture -i` interactive selection to let the user pick a region,
/// then derives the screen rectangle from the captured image dimensions and mouse positions.
@MainActor
public final class RegionSelectionOverlay {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ameba.TRex",
        category: "RegionSelection"
    )

    /// Show the native screencapture interactive selection UI and return the selected rect.
    /// Returns the selected rect in CGWindow coordinate system (origin at top-left of main display),
    /// or nil if the user cancelled (pressed Escape).
    public static func selectRegion() async -> CGRect? {
        let tracker = MouseTracker()
        tracker.start()
        defer { tracker.stop() }

        let directory = NSTemporaryDirectory()
        let filePath = NSURL.fileURL(withPathComponents: [directory, "watchmode-select-\(UUID().uuidString).png"])!.path

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", filePath]

        let success: Bool = await withCheckedContinuation { continuation in
            process.terminationHandler = { process in
                continuation.resume(returning: process.terminationStatus == 0)
            }
            do {
                try process.run()
            } catch {
                logger.error("screencapture failed to launch: \(error.localizedDescription, privacy: .public)")
                continuation.resume(returning: false)
            }
        }

        // Clean up the temp file — we only need the coordinates
        defer {
            try? FileManager.default.removeItem(atPath: filePath)
        }

        guard success, FileManager.default.fileExists(atPath: filePath) else {
            logger.info("Region selection cancelled or failed")
            return nil
        }

        // Read the captured image to get its pixel dimensions
        guard let nsImage = NSImage(contentsOfFile: filePath),
              let imageRep = nsImage.representations.first else {
            logger.error("Failed to read captured image for dimensions")
            return nil
        }

        let imageWidth = imageRep.pixelsWide
        let imageHeight = imageRep.pixelsHigh

        // Get the mouse positions recorded during the screencapture drag
        guard let mouseDown = tracker.mouseDownPosition,
              let mouseUp = tracker.mouseUpPosition else {
            logger.warning("Mouse positions not captured, falling back to image dimensions")
            // Fallback: can't determine position without mouse tracking.
            // This shouldn't normally happen.
            return nil
        }

        // Mouse positions are in CGEvent coordinate space (origin top-left of main display)
        let x = min(mouseDown.x, mouseUp.x)
        let y = min(mouseDown.y, mouseUp.y)

        // Use image pixel dimensions with the scale of the selected screen (accounts for Retina scaling)
        let screenScale = screenScale(for: CGPoint(
            x: (mouseDown.x + mouseUp.x) / 2,
            y: (mouseDown.y + mouseUp.y) / 2
        ))
        let w = CGFloat(imageWidth) / screenScale
        let h = CGFloat(imageHeight) / screenScale

        let rect = CGRect(x: x, y: y, width: w, height: h)
        logger.info("Selected region: \(rect.debugDescription, privacy: .public)")
        return rect
    }

    private static func screenScale(for point: CGPoint) -> CGFloat {
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) {
            return screen.backingScaleFactor
        }
        return NSScreen.main?.backingScaleFactor ?? 2.0
    }
}

// MARK: - Mouse Position Tracker

/// Tracks mouse-down and mouse-up positions using a CGEvent tap.
/// Used to determine where the user dragged during screencapture's interactive selection.
private final class MouseTracker: @unchecked Sendable {
    private(set) var mouseDownPosition: CGPoint?
    private(set) var mouseUpPosition: CGPoint?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        mouseDownPosition = nil
        mouseUpPosition = nil

        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue)

        // Use a weak-like pattern via Unmanaged to avoid retain cycle
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, type, event, userInfo in
                guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
                let tracker = Unmanaged<MouseTracker>.fromOpaque(userInfo).takeUnretainedValue()

                switch type {
                case .leftMouseDown:
                    tracker.mouseDownPosition = event.location
                case .leftMouseUp:
                    tracker.mouseUpPosition = event.location
                default:
                    break
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: selfPtr
        ) else {
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            // CFMachPort is automatically invalidated when removed from run loop
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    deinit {
        stop()
    }
}
