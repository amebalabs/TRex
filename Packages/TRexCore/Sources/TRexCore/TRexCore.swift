import OSLog
import SwiftUI
import UserNotifications
import Vision

/// Bundle identifiers for TRex apps
public enum BundleIdentifiers {
    public static let gui = "com.ameba.TRex"
    public static let cli = "com.ameba.TRex.cli"

    /// Check if current process is the CLI tool
    public static var isCLI: Bool {
        Bundle.main.bundleIdentifier == cli
    }
}

// Timeout error for async operations
enum TimeoutError: Error {
    case timedOut
}

// Async timeout utility
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError.timedOut
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

public class TRex: NSObject {
    public static let shared = TRex()
    let preferences = Preferences.shared
    private var currentInvocationMode: InvocationMode = .captureScreen
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ameba.TRex", category: "TRexCore")

    var task: Process?
    let sceenCaptureURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

    public lazy var screenShotFilePath: String = {
        let directory = NSTemporaryDirectory()
        return NSURL.fileURL(withPathComponents: [directory, "capture.png"])!.path
    }()

    var screenCaptureArguments: [String] {
        var out = ["-i"] // capture screen interactively, by selection or window
        if !preferences.captureSound {
            out.append("-x") // do not play sounds
        }
        out.append(screenShotFilePath)
        return out
    }

    var hasAutomationsConfigured: Bool {
        !preferences.autoOpenProvidedURL.isEmpty || !preferences.autoRunShortcut.isEmpty
    }

    var invocationRequiresAutomation: Bool {
        currentInvocationMode == .captureClipboardAndTriggerAutomation ||
            currentInvocationMode == .captureScreenAndTriggerAutomation ||
            currentInvocationMode == .captureFromFileAndTriggerAutomation
    }

    public func capture(_ mode: InvocationMode, imagePath: String? = nil) async {
        currentInvocationMode = mode

        guard let text = await getText(imagePath) else { return }

        if BundleIdentifiers.isCLI {
            // CLI doesn't need MainActor - process directly to avoid keeping run loop alive
            self.processDetectedText(text)
        } else {
            // GUI app needs main thread for UI updates
            await MainActor.run {
                self.processDetectedText(text)
            }
        }
    }

    private func getImage(_ imagePath: String? = nil) -> NSImage? {
        switch currentInvocationMode {
        case .captureScreen, .captureScreenAndTriggerAutomation:
            task = Process()
            task?.executableURL = sceenCaptureURL

            task?.arguments = screenCaptureArguments

            do {
                try task?.run()
            } catch {
                logger.error("Screen capture command failed")
                task = nil
                return nil
            }

            task?.waitUntilExit()
            task = nil
            return NSImage(contentsOfFile: screenShotFilePath)
        case .captureClipboard, .captureClipboardAndTriggerAutomation:
            if let url = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil)?.first as? NSURL,
               url.isFileURL, let path = url.path
            {
                return NSImage(contentsOfFile: path)
            }

            if let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                return image
            }

            return nil
        case .captureFromFile, .captureFromFileAndTriggerAutomation:
            guard let imagePath = imagePath, FileManager.default.fileExists(atPath: imagePath) else {
                return nil
            }
            return NSImage(contentsOfFile: imagePath)
        }
    }

    private func getText(_ imagePath: String? = nil) async -> String? {
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("🚀 getText called - starting OCR process")
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        guard task == nil else {
            logger.warning("⚠️ Task is not nil, returning early")
            return nil
        }

        guard let nsImage = getImage(imagePath) else {
            logger.error("❌ Failed to get image")
            return nil
        }

        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            logger.error("❌ Failed to convert NSImage to CGImage")
            return nil
        }

        logger.info("📐 Image loaded: \(cgImage.width, privacy: .public)x\(cgImage.height, privacy: .public)")

        // Always check for QR codes first
        let text = parseQR(image: cgImage)
        guard text.isEmpty else {
            logger.info("📱 QR code detected, result length: \(text.count, privacy: .public)")
            if preferences.autoOpenQRCodeURL {
                detectAndOpenURL(text: text)
            }
            return text
        }

        logger.info("📝 No QR code detected, proceeding with text recognition")
        logger.info("⚙️ Current settings:")
        logger.info("  → Tesseract enabled: \(self.preferences.tesseractEnabled, privacy: .public)")
        logger.info("  → Automatic language detection: \(self.preferences.automaticLanguageDetection, privacy: .public)")
        logger.info("  → Selected language code: \(self.preferences.recognitionLanguageCode, privacy: .public)")
        logger.info("  → macOS version: \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion, privacy: .public)")

        // Use OCRManager to select appropriate engine
        let languages = preferences.tesseractEnabled && !preferences.tesseractLanguages.isEmpty
            ? preferences.tesseractLanguages.map { LanguageCodeMapper.fromTesseract($0) }
            : (preferences.automaticLanguageDetection && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13
                ? [] // Empty array means automatic detection for Vision
                : [LanguageCodeMapper.standardize(preferences.recognitionLanguageCode)])

        if languages.isEmpty {
            logger.info("🌍 Languages array is EMPTY - will use automatic detection")
        } else {
            logger.info("🔤 Languages array: [\(languages.joined(separator: ", "), privacy: .public)]")
        }

        // If automatic detection is enabled and we're not using Tesseract, use Vision directly
        if preferences.automaticLanguageDetection && !preferences.tesseractEnabled && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13 {
            logger.info("🛤️ OCR Path: Vision with AUTOMATIC language detection")
            return await performVisionOCR(cgImage: cgImage)
        }

        // If Tesseract is disabled, only use Vision
        if !preferences.tesseractEnabled {
            logger.info("🛤️ OCR Path: Using Apple Vision (Tesseract disabled)")
            if let visionEngine = OCRManager.shared.engines.first(where: { $0.identifier == "vision" }) {
                return await performOCR(with: visionEngine, cgImage: cgImage, languages: languages)
            } else {
                logger.warning("⚠️ Vision engine not found, falling back to legacy path")
                return await performVisionOCR(cgImage: cgImage)
            }
        }

        if let engine = OCRManager.shared.findEngine(for: languages) {
            logger.info("🛤️ OCR Path: Using \(engine.name, privacy: .public) engine with explicit languages")
            return await performOCR(with: engine, cgImage: cgImage, languages: languages)
        } else {
            logger.warning("🛤️ OCR Path: No suitable OCR engine found for languages, falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        }
    }
    
    
    private func performOCR(with engine: OCREngine, cgImage: CGImage, languages: [String]) async -> String? {
        logger.info("🔧 performOCR called with engine: \(engine.name, privacy: .public)")
        do {
            // Use timeout utility for 5 second timeout
            let result = try await withTimeout(seconds: 5.0) {
                try await engine.recognizeText(
                    in: cgImage,
                    languages: languages,
                    recognitionLevel: .accurate
                )
            }

            logger.info("✅ \(engine.name, privacy: .public) OCR successful!")
            logger.info("  → Result length: \(result.text.count, privacy: .public) characters")
            logger.info("  → Confidence: \(String(format: "%.2f", result.confidence), privacy: .public)")
            logger.info("  → Recognized languages: \(result.recognizedLanguages.joined(separator: ", "), privacy: .public)")

            // Handle URL opening if needed
            if preferences.autoOpenCapturedURL {
                detectAndOpenURL(text: result.text)
            }

            return result.text
        } catch TimeoutError.timedOut {
            logger.error("⏱️ OCR timed out after 5 seconds, falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        } catch {
            logger.error("❌ \(engine.name, privacy: .public) failed with error: \(error.localizedDescription, privacy: .public)")
            logger.error("  → Falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        }
    }

    private func performVisionOCR(cgImage: CGImage) async -> String? {
        logger.info("🔧 performVisionOCR (legacy path) called")
        return await withCheckedContinuation { continuation in
            detectText(in: cgImage) { result in
                if let result = result {
                    self.logger.info("✅ Legacy Vision OCR successful, result length: \(result.count, privacy: .public)")
                } else {
                    self.logger.warning("⚠️ Legacy Vision OCR returned no text")
                }
                continuation.resume(returning: result)
            }
        }
    }

    func processDetectedText(_ text: String) {
        showNotification(text: text)

        defer {
            try? FileManager.default.removeItem(atPath: screenShotFilePath)
        }

        // Choose between automation and clipboard
        guard invocationRequiresAutomation, hasAutomationsConfigured else {
            let pasteBoard = NSPasteboard.general
            pasteBoard.clearContents()
            pasteBoard.setString(text, forType: .string)
            // output to STDOUT for CLI
            if BundleIdentifiers.isCLI {
                print(text)
            }
            return
        }

        if #available(macOS 12, *) {
            // run shortcuts
            ShortcutsManager.shared.runShortcut(inputText: text)
        }
        var text = text

        if preferences.autoOpenProvidedURLAddNewLine {
            text.append("\n")
        }
        if case let urlStr = preferences.autoOpenProvidedURL.replacingOccurrences(of: "{text}", with: text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""),
           let url = URL(string: urlStr)
        {
            NSWorkspace.shared.open(url)
        }

        return
    }

    private func detectAndOpenURL(text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))

        matches?.forEach { match in
            guard let range = Range(match.range, in: text),
                  case let urlStr = String(text[range]),
                  let url = URL(string: urlStr)
            else { return }
            if url.scheme == nil,
               case let urlStr = "https://\(url.absoluteString)",
               let newUrl = URL(string: urlStr)
            {
                NSWorkspace.shared.open(newUrl)
                return
            }
            NSWorkspace.shared.open(url)
        }
    }

    func parseQR(image: CGImage) -> String {
        let image = CIImage(cgImage: image)

        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

        let features = detector?.features(in: image) ?? []

        return features.compactMap { feature in
            (feature as? CIQRCodeFeature)?.messageString
        }.joined(separator: " ")
    }

    func detectText(in image: CGImage, completionHandler: @escaping (String?) -> Void) {
        logger.info("🔍 detectText (legacy Vision path) called")
        logger.info("  → Image size: \(image.width, privacy: .public)x\(image.height, privacy: .public)")

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                self.logger.error("❌ Vision text detection failed: \(error.localizedDescription, privacy: .public)")
                completionHandler(nil)
                return
            }

            guard let result = self.handleDetectionResults(results: request.results) else {
                self.logger.warning("⚠️ No results from handleDetectionResults")
                completionHandler(nil)
                return
            }

            self.logger.info("✅ Legacy Vision path succeeded: \(result.count, privacy: .public) characters")

            if self.preferences.autoOpenCapturedURL {
                self.detectAndOpenURL(text: result)
            }
            completionHandler(result)
        }

        // Configure language detection
        if preferences.automaticLanguageDetection, #available(macOS 13.0, *) {
            logger.info("🌍 Vision: Automatic language detection ENABLED")
            request.automaticallyDetectsLanguage = true
            // Don't set recognitionLanguages when using automatic detection
        } else {
            let normalizedLanguage = LanguageCodeMapper.standardize(preferences.recognitionLanguageCode)
            logger.info("🔤 Vision: Using specific language: \(self.preferences.recognitionLanguageCode, privacy: .public) → normalized to: \(normalizedLanguage, privacy: .public)")
            request.automaticallyDetectsLanguage = false
            request.recognitionLanguages = [normalizedLanguage]
        }

        request.usesLanguageCorrection = true
        request.recognitionLevel = .accurate
        request.customWords = preferences.customWordsList

        logger.debug("🔧 Vision request configuration:")
        logger.debug("  → recognitionLevel: accurate")
        logger.debug("  → usesLanguageCorrection: true")
        logger.debug("  → customWords count: \(self.preferences.customWordsList.count, privacy: .public)")

        performDetection(request: request, image: image)
    }

    private func performDetection(request: VNRecognizeTextRequest, image: CGImage) {
        let requests = [request]

        let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])

        do {
            try handler.perform(requests)
        } catch {
            logger.error("Vision handler failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func handleDetectionResults(results: [Any]?) -> String? {
        guard let results = results, results.count > 0 else {
            return nil
        }

        var output: String = ""
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1) {
                    if !output.isEmpty {
                        output.append(preferences.ignoreLineBreaks ? " " : "\n")
                    }
                    output.append(text.string)
                }
            }
        }
        return output
    }
}

// MARK: Notifications

extension TRex {
    class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
        static let shared = NotificationDelegate()
        
        override init() {
            super.init()
            UNUserNotificationCenter.current().delegate = self
        }
        
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            completionHandler([.banner, .sound])
        }
    }
    
    func showNotification(text: String) {
        guard preferences.resultNotification else { return }
        guard !BundleIdentifiers.isCLI else { return }
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Set delegate to handle foreground notifications
        notificationCenter.delegate = NotificationDelegate.shared
        
        // Request authorization if not already granted
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "TRex"
            content.subtitle = "Captured text"
            content.body = text
            content.sound = .default
            
            let uuidString = UUID().uuidString
            // Using immediate trigger instead of nil
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: uuidString,
                                                content: content,
                                                trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    self.logger.error("Failed to show notification: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
}
