import OSLog
import SwiftUI
import UserNotifications
import Vision

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
        
        // Process results back on main thread for UI updates
        await MainActor.run {
            self.precessDetectedText(text)
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
        guard task == nil else { return nil }

        guard let nsImage = getImage(imagePath) else {
            return nil
        }
        
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            logger.error("Failed to convert NSImage to CGImage")
            return nil
        }

        // Always check for QR codes first
        let text = parseQR(image: cgImage)
        guard text.isEmpty else {
            logger.info("QR code detected, result length: \(text.count, privacy: .public)")
            if preferences.autoOpenQRCodeURL {
                detectAndOpenURL(text: text)
            }
            return text
        }

        logger.debug("No QR code detected, proceeding with text recognition")
        logger.debug("Tesseract enabled: \(self.preferences.tesseractEnabled, privacy: .public)")
        
        // Use OCRManager to select appropriate engine
        let languages = preferences.tesseractEnabled && !preferences.tesseractLanguages.isEmpty
            ? preferences.tesseractLanguages.map { LanguageCodeMapper.fromTesseract($0) }
            : (preferences.automaticLanguageDetection && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13 
                ? [] // Empty array means automatic detection for Vision
                : [preferences.recognitionLanguageCode])
        
        logger.debug("Requested languages: \(languages.joined(separator: ","), privacy: .public)")
        logger.debug("Automatic detection: \(self.preferences.automaticLanguageDetection, privacy: .public)")
        
        // If automatic detection is enabled and we're not using Tesseract, use Vision directly
        if preferences.automaticLanguageDetection && !preferences.tesseractEnabled && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13 {
            logger.info("Using Vision with automatic language detection")
            return await performVisionOCR(cgImage: cgImage)
        }
        
        if let engine = OCRManager.shared.findEngine(for: languages) {
            logger.info("Using \(engine.name, privacy: .public) engine")
            return await performOCR(with: engine, cgImage: cgImage, languages: languages)
        } else {
            logger.info("No suitable OCR engine found, falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        }
    }
    
    
    private func performOCR(with engine: OCREngine, cgImage: CGImage, languages: [String]) async -> String? {
        do {
            // Use timeout utility for 5 second timeout
            let result = try await withTimeout(seconds: 5.0) {
                try await engine.recognizeText(
                    in: cgImage,
                    languages: languages,
                    recognitionLevel: .accurate
                )
            }
            
            logger.info("\(engine.name, privacy: .public) OCR successful, result length: \(result.text.count, privacy: .public)")
            
            // Handle URL opening if needed
            if preferences.autoOpenCapturedURL {
                detectAndOpenURL(text: result.text)
            }
            
            return result.text
        } catch TimeoutError.timedOut {
            logger.error("OCR timed out after 5 seconds, falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        } catch {
            logger.error("\(engine.name, privacy: .public) failed with error: \(error.localizedDescription, privacy: .public). Falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        }
    }
    
    private func performVisionOCR(cgImage: CGImage) async -> String? {
        await withCheckedContinuation { continuation in
            detectText(in: cgImage) { result in
                if let result = result {
                    self.logger.info("Vision OCR successful, result length: \(result.count, privacy: .public)")
                } else {
                    self.logger.info("Vision OCR returned no text")
                }
                continuation.resume(returning: result)
            }
        }
    }

    func precessDetectedText(_ text: String) {
        showNotification(text: text)

        defer {
            try? FileManager.default.removeItem(atPath: screenShotFilePath)
        }

        // Choose between automation and clipboard
        guard invocationRequiresAutomation, hasAutomationsConfigured else {
            let pasteBoard = NSPasteboard.general
            pasteBoard.clearContents()
            pasteBoard.setString(text, forType: .string)
            // output to STDOUT for cli
            if Bundle.main.bundleIdentifier == "com.ameba.TRex.cli" {
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
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                self.logger.error("Vision text detection failed: \(error.localizedDescription, privacy: .public)")
                completionHandler(nil)
                return
            }

            guard let result = self.handleDetectionResults(results: request.results) else {
                completionHandler(nil)
                return
            }

            if self.preferences.autoOpenCapturedURL {
                self.detectAndOpenURL(text: result)
            }
            completionHandler(result)
        }
        
        // Configure language detection
        if preferences.automaticLanguageDetection, #available(macOS 13.0, *) {
            logger.debug("Vision: Automatic language detection ENABLED")
            request.automaticallyDetectsLanguage = true
            // Don't set recognitionLanguages when using automatic detection
        } else {
            logger.debug("Vision: Using specific language: \(self.preferences.recognitionLanguageCode, privacy: .public)")
            request.automaticallyDetectsLanguage = false
            request.recognitionLanguages = [preferences.recognitionLanguageCode]
        }
        
        request.usesLanguageCorrection = true
        request.recognitionLevel = .accurate
        request.customWords = preferences.customWordsList

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
        guard Bundle.main.bundleIdentifier != "com.ameba.TRex.cli" else { return }
        
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
