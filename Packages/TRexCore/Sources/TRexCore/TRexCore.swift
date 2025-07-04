import SwiftUI
import UserNotifications
import Vision

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
        let text = getText(imagePath)
        guard let text = text else { return }
        precessDetectedText(text)
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
        
        // Simple logic: Use Tesseract if enabled, otherwise use Vision
        if preferences.tesseractEnabled {
            print("[TRex] Using Tesseract OCR")
            return performTesseractOCR(cgImage: cgImage)
        } else {
            print("[TRex] Using Vision framework")
            return performVisionOCR(cgImage: cgImage)
        }
    }
    
    private func tesseractToLanguageCode(_ tesseractCode: String) -> String {
        // Map Tesseract language codes back to standard language codes
        let mapping: [String: String] = [
            "eng": "en-US",
            "fra": "fr-FR",
            "deu": "de-DE",
            "spa": "es-ES",
            "ita": "it-IT",
            "por": "pt-BR",
            "rus": "ru-RU",
            "jpn": "ja-JP",
            "chi_sim": "zh-Hans",
            "chi_tra": "zh-Hant",
            "kor": "ko-KR",
            "ara": "ar-SA",
            "hin": "hi-IN",
            "tha": "th-TH",
            "vie": "vi-VN",
            "heb": "he-IL",
            "pol": "pl-PL",
            "tur": "tr-TR",
            "ukr": "uk-UA",
            "ces": "cs-CZ",
            "hun": "hu-HU",
            "swe": "sv-SE",
            "dan": "da-DK",
            "nor": "no-NO",
            "fin": "fi-FI",
            "nld": "nl-NL",
            "ell": "el-GR"
        ]
        
        // Return mapped code or original if not found
        return mapping[tesseractCode] ?? tesseractCode
    }
    
    private func performTesseractOCR(cgImage: CGImage) -> String? {
        let tesseractEngine = TesseractOCREngine()
        
        // Check if Tesseract is available
        guard tesseractEngine.isAvailable else {
            print("[TRex] Tesseract is not available, falling back to Vision")
            return performVisionOCR(cgImage: cgImage)
        }
        
        // Convert Tesseract language codes from preferences to standard format for OCREngine API
        let languages = preferences.tesseractLanguages.isEmpty ? ["en-US"] : preferences.tesseractLanguages.map { tesseractToLanguageCode($0) }
        
        // Perform OCR synchronously
        var ocrResult: String?
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                let result = try await tesseractEngine.recognizeText(
                    in: cgImage,
                    languages: languages,
                    recognitionLevel: .accurate
                )
                ocrResult = result.text
                print("[TRex] Tesseract OCR successful, result length: \(result.text.count)")
            } catch {
                print("[TRex] Tesseract OCR failed: \(error)")
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5) // 5 second timeout
        
        if let result = ocrResult {
            if preferences.autoOpenCapturedURL {
                detectAndOpenURL(text: result)
            }
            return result
        }
        
        // If Tesseract fails, fall back to Vision
        print("[TRex] Tesseract failed, falling back to Vision")
        return performVisionOCR(cgImage: cgImage)
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
