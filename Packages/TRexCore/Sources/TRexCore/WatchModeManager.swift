import Cocoa
import CryptoKit
import OSLog
import Combine

/// Manages continuous capture of a screen region, detecting changes via SHA256 hash comparison
/// and routing recognized text to the configured output handler.
///
/// Flow: startWatching() → region selection → overlay with setup controls → beginCapture() → polling loop
@MainActor
public final class WatchModeManager: ObservableObject {

    /// True when watch mode is active (overlay visible). This covers both the setup phase
    /// (region selected, user configuring options) and the capturing phase. Use this to
    /// reflect overall watch mode state in UI (e.g. menu item title).
    @Published public private(set) var isWatching = false
    /// True only when the polling loop is running and actively capturing screen changes.
    /// This is a subset of `isWatching` — capturing implies watching, but not vice versa.
    /// Use this to drive activity indicators (e.g. menu bar pulse animation).
    @Published public private(set) var isCapturing = false
    @Published public private(set) var captureCount = 0
    /// Polling interval, adjustable from the overlay before starting.
    @Published public var pollingInterval: Double = 1.0

    private var currentRect: CGRect?
    private var outputMode: WatchOutputMode = .appendToClipboard
    private var outputFilePath: String?
    private var lastImageHash: Data?
    private var pollTask: Task<Void, Never>?
    private var isPaused = false

    private let preferences = Preferences.shared
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ameba.TRex", category: "WatchMode")
    private var systemEventCancellables = Set<AnyCancellable>()
    private lazy var overlay = WatchModeOverlay()

    public nonisolated init() {}

    // MARK: - Public API

    /// Start watch mode: show region selection, then display overlay in setup mode.
    /// Polling does NOT begin until the user clicks Start in the overlay.
    public func startWatching(outputMode: WatchOutputMode? = nil, outputFilePath: String? = nil) async {
        guard !isWatching else {
            logger.warning("Watch mode already active")
            return
        }

        self.outputMode = outputMode ?? preferences.watchModeDefaultOutputMode
        self.pollingInterval = preferences.watchModePollingInterval

        // Validate file path early when file output mode is selected
        if self.outputMode == .appendToFile {
            guard Self.sanitizedOutputURL(from: outputFilePath) != nil else {
                logger.error("Rejected watch mode file path: must be within user's home directory")
                return
            }
        }
        self.outputFilePath = outputFilePath

        guard let rect = await RegionSelectionOverlay.selectRegion() else {
            logger.info("Region selection cancelled")
            return
        }

        showSetup(rect: rect)
    }

    /// Begin capturing (called from the overlay Start button).
    public func beginCapture() {
        guard isWatching, !isCapturing, currentRect != nil else { return }

        // Persist the interval chosen in the overlay
        preferences.watchModePollingInterval = pollingInterval

        lastImageHash = nil
        captureCount = 0
        isPaused = false
        isCapturing = true

        subscribeToSystemEvents()

        logger.info("Watch mode capturing: rect=\(self.currentRect!.debugDescription, privacy: .public), interval=\(self.pollingInterval, privacy: .public)s")

        pollTask = Task { [weak self] in
            await self?.pollLoop()
        }
    }

    /// Re-select the region (called from the overlay Re-select button).
    public func reselectRegion() async {
        // Stop any active capture
        stopCapture()

        // Hide overlay while selecting
        overlay.hide()

        guard let rect = await RegionSelectionOverlay.selectRegion() else {
            // User cancelled re-selection — restore previous overlay if we had a rect
            if let previousRect = currentRect {
                overlay.show(rect: previousRect, manager: self)
            } else {
                cancel()
            }
            return
        }

        showSetup(rect: rect)
    }

    /// Cancel watch mode entirely (called from the overlay Cancel button).
    public func cancel() {
        stopCapture()
        overlay.hide()
        currentRect = nil
        isWatching = false
        logger.info("Watch mode cancelled")
    }

    /// Stop watching: stop capture and remove overlay.
    public func stopWatching() {
        stopCapture()
        overlay.hide()
        currentRect = nil
        isWatching = false
        logger.info("Watch mode stopped after \(self.captureCount, privacy: .public) captures")
    }

    // MARK: - Private

    private func showSetup(rect: CGRect) {
        currentRect = rect
        isWatching = true
        isCapturing = false
        overlay.show(rect: rect, manager: self)
        logger.info("Watch mode setup: rect=\(rect.debugDescription, privacy: .public)")
    }

    private func stopCapture() {
        pollTask?.cancel()
        pollTask = nil
        lastImageHash = nil
        isCapturing = false
        isPaused = false
        systemEventCancellables.removeAll()
    }

    // MARK: - Polling Loop

    private func pollLoop() async {
        while !Task.isCancelled && isCapturing {
            if !isPaused && !TRex.shared.isCaptureInProgress {
                await pollTick()
            }

            let interval = pollingInterval
            do {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            } catch {
                break // Task cancelled
            }
        }
    }

    private func pollTick() async {
        guard let rect = currentRect else { return }

        guard let image = await captureRect(rect) else {
            logger.warning("Failed to capture region")
            return
        }

        let hash = imageHash(image)

        guard hash != lastImageHash else {
            return // No change detected
        }

        lastImageHash = hash
        logger.info("Change detected in watched region (capture #\(self.captureCount + 1, privacy: .public))")

        // Run OCR on the captured image
        guard let ocrResult = await TRex.shared.recognizeImageForWatchMode(image) else {
            logger.warning("OCR returned no result for watched region")
            return
        }

        let text = ocrResult.text
        guard !text.isEmpty else { return }

        captureCount += 1
        handleOutput(text)
    }

    // MARK: - Screen Capture

    private let screenCaptureURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

    private func captureRect(_ rect: CGRect) async -> CGImage? {
        let x = Int(rect.origin.x)
        let y = Int(rect.origin.y)
        let w = Int(rect.width)
        let h = Int(rect.height)

        let directory = NSTemporaryDirectory()
        let filePath = NSURL.fileURL(withPathComponents: [directory, "watchmode-\(UUID().uuidString).png"])!.path

        let process = Process()
        process.executableURL = screenCaptureURL
        process.arguments = ["-x", "-R", "\(x),\(y),\(w),\(h)", filePath]

        let success: Bool = await withCheckedContinuation { continuation in
            process.terminationHandler = { process in
                continuation.resume(returning: process.terminationStatus == 0)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }

        guard success, FileManager.default.fileExists(atPath: filePath) else {
            return nil
        }

        defer {
            try? FileManager.default.removeItem(atPath: filePath)
        }

        guard let nsImage = NSImage(contentsOfFile: filePath) else {
            return nil
        }

        return nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    // MARK: - Change Detection

    private func imageHash(_ image: CGImage) -> Data {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        let totalBytes = bytesPerRow * height

        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            // Fallback: hash the raw data provider bytes
            if let dataProvider = image.dataProvider, let data = dataProvider.data {
                let bytes = CFDataGetBytePtr(data)!
                let length = CFDataGetLength(data)
                let buffer = UnsafeBufferPointer(start: bytes, count: length)
                let digest = SHA256.hash(data: buffer)
                return Data(digest)
            }
            return Data()
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let digest = SHA256.hash(data: pixelData)
        return Data(digest)
    }

    // MARK: - Output Handlers

    private func handleOutput(_ text: String) {
        switch outputMode {
        case .appendToClipboard:
            appendToClipboard(text)
        case .appendToFile:
            appendToFile(text)
        case .notificationStream:
            showNotification(text)
        }
    }

    private func appendToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        let existing = pasteboard.string(forType: .string) ?? ""
        let combined: String
        if existing.isEmpty {
            combined = text
        } else {
            combined = existing + "\n---\n" + text
        }
        pasteboard.clearContents()
        pasteboard.setString(combined, forType: .string)
    }

    /// Resolve and validate the output file path.
    /// Paths from external sources (e.g. URL scheme) are restricted to user-writable
    /// locations under the user's home directory to prevent path injection.
    private static func sanitizedOutputURL(from path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }

        let fileURL = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            .standardizedFileURL

        // Reject paths outside the user's home directory
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        guard fileURL.path.hasPrefix(home.path) else {
            return nil
        }

        return fileURL
    }

    private func appendToFile(_ text: String) {
        guard let validURL = Self.sanitizedOutputURL(from: outputFilePath) else {
            logger.error("No valid output file path configured for watch mode")
            return
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] \(text)\n"

        do {
            if FileManager.default.fileExists(atPath: validURL.path) {
                let handle = try FileHandle(forWritingTo: validURL)
                handle.seekToEndOfFile()
                if let data = entry.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            } else {
                try entry.write(to: validURL, atomically: true, encoding: .utf8)
            }
        } catch {
            logger.error("Failed to write to watch mode output file: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func showNotification(_ text: String) {
        TRex.shared.showNotification(text: text)
    }

    // MARK: - System Event Handling

    private func subscribeToSystemEvents() {
        systemEventCancellables.removeAll()

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.screensDidSleepNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPaused = true
                self?.logger.info("Watch mode paused: screens did sleep")
            }
            .store(in: &systemEventCancellables)

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.screensDidWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPaused = false
                self?.logger.info("Watch mode resumed: screens did wake")
            }
            .store(in: &systemEventCancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.logger.warning("Screen parameters changed, stopping watch mode (region may be invalid)")
                self?.stopWatching()
            }
            .store(in: &systemEventCancellables)
    }
}
