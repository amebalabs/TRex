import SwiftUI
import UserNotifications
import Vision

// Helper extension to bridge async/sync code
extension NSObject {
    static func awaitTaskResult<T>(_ task: Task<T, Never>, timeout: TimeInterval) throws -> T? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: T?
        var taskCompleted = false
        
        Task {
            result = await task.value
            taskCompleted = true
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + timeout)
        
        // Return nil only if task didn't complete, not if result is nil
        return taskCompleted ? result : nil
    }
}

public class TRex: NSObject {
    public static let shared = TRex()
    let preferences = Preferences.shared
    private var currentInvocationMode: InvocationMode = .captureScreen

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

    public func capture(_ mode: InvocationMode, imagePath: String? = nil) {
        currentInvocationMode = mode
        
        // Dispatch to background queue to avoid blocking main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let text = self.getText(imagePath)
            guard let text = text else { return }
            
            // Process results back on main thread for UI updates
            DispatchQueue.main.async {
                self.precessDetectedText(text)
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
                print("Failed to capture")
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

    private func getText(_ imagePath: String? = nil) -> String? {
        guard task == nil else { return nil }

        guard let nsImage = getImage(imagePath) else {
            return nil
        }
        
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("[TRex] Failed to convert NSImage to CGImage")
            return nil
        }

        // Always check for QR codes first
        let text = parseQR(image: cgImage)
        guard text.isEmpty else {
            print("[TRex] QR code detected: \(text)")
            if preferences.autoOpenQRCodeURL {
                detectAndOpenURL(text: text)
            }
            return text
        }

        print("[TRex] No QR code detected, proceeding with text recognition")
        print("[TRex] Tesseract enabled: \(preferences.tesseractEnabled)")
        
        // Use OCRManager to select appropriate engine
        let languages = preferences.tesseractEnabled && !preferences.tesseractLanguages.isEmpty
            ? preferences.tesseractLanguages.map { LanguageCodeMapper.fromTesseract($0) }
            : [preferences.recongitionLanguage.languageCode()]
        
        print("[TRex] Requested languages: \(languages)")
        
        if let engine = OCRManager.shared.findEngine(for: languages) {
            print("[TRex] Using \(engine.name) engine")
            return performOCR(with: engine, cgImage: cgImage, languages: languages)
        } else {
            print("[TRex] No suitable engine found, falling back to Vision")
            return performVisionOCR(cgImage: cgImage)
        }
    }
    
    
    private func performOCR(with engine: OCREngine, cgImage: CGImage, languages: [String]) -> String? {
        // Use async/await properly without blocking
        let task = Task { () -> String? in
            do {
                let result = try await engine.recognizeText(
                    in: cgImage,
                    languages: languages,
                    recognitionLevel: .accurate
                )
                print("[TRex] \(engine.name) OCR successful, result length: \(result.text.count)")
                return result.text
            } catch {
                print("[TRex] \(engine.name) OCR failed: \(error)")
                return nil
            }
        }
        
        // Block the current thread to wait for async result (necessary for current architecture)
        // This is not ideal but maintains compatibility with existing synchronous API
        // Use 5 second timeout for better UI responsiveness
        let taskResult = try? NSObject.awaitTaskResult(task, timeout: 5.0)
        
        // Check if task timed out
        if taskResult == nil {
            print("[TRex] OCR timed out after 5 seconds, falling back to Vision")
            task.cancel()
            return performVisionOCR(cgImage: cgImage)
        }
        
        // Task completed but returned nil (OCR failed)
        if let result = taskResult, result == nil {
            print("[TRex] \(engine.name) failed, falling back to Vision")
            return performVisionOCR(cgImage: cgImage)
        }
        
        // Success - handle URL opening if needed
        if let result = taskResult!, preferences.autoOpenCapturedURL {
            detectAndOpenURL(text: result)
        }
        
        return taskResult!
    }
    
    private func performVisionOCR(cgImage: CGImage) -> String? {
        var out: String?
        let group = DispatchGroup()
        group.enter()
        detectText(in: cgImage) { result in
            if let result = result {
                print("[TRex] Vision OCR successful, result length: \(result.count)")
            } else {
                print("[TRex] Vision OCR returned nil")
            }
            out = result
            group.leave()
        }
        _ = group.wait(timeout: .now() + 2)
        return out
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
                print("Error detecting text: \(error)")
            } else {
                if let result = self.handleDetectionResults(results: request.results) {
                    if self.preferences.autoOpenCapturedURL {
                        self.detectAndOpenURL(text: result)
                    }
                    completionHandler(result)
                }
            }
        }
        if preferences.automaticLanguageDetection, #available(macOS 13.0, *) {
            request.automaticallyDetectsLanguage = true
        } else {
            request.recognitionLanguages = [preferences.recongitionLanguage.languageCode()]
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
            print("Error: \(error)")
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
                    print("Error showing notification: \(error.localizedDescription)")
                }
            }
        }
    }
}
