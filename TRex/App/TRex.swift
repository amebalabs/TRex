import SwiftUI
import Vision

class TRex: NSObject {
    public static let shared = TRex()
    let preferences = Preferences.shared
    private var currentInvocationMode: InvocationMode = .captureScreen
    
    var task: Process?
    let sceenCaptureURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    
    lazy var screenShotFilePath: String = {
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
    
    func capture(_ mode: InvocationMode) {
        currentInvocationMode = mode
        _capture() { [weak self] text in
            guard let text = text else { return }
            self?.precessDetectedText(text  )
        }
    }
    
    private func getImage() -> NSImage? {
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
        case .captureClipboard:
            if let url = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil)?.first as? NSURL,
               let path = url.path {
                return NSImage(contentsOfFile: path)
            }
            if let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                return image
            }
            return nil
        }
    }
    
    private func _capture(completionHandler: (String?) -> Void) {
        guard task == nil else { return }
        
        guard let image = getImage()?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completionHandler(nil)
            return
        }
        
        let text = parseQR(image: image)
        guard text.isEmpty else {
            completionHandler(text)
            if preferences.autoOpenQRCodeURL {
                detectAndOpenURL(text: text)
            }
            return
        }
        detectText(in: image)
    }
    
    func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    func precessDetectedText(_ text: String) {
        var text = text
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(text, forType: .string)
        
        if preferences.autoOpenProvidedURLAddNewLine {
            text.append("\n")
        }
        if currentInvocationMode == .captureScreenAndTriggerAutomation && !preferences.autoOpenProvidedURL.isEmpty,
           case let urlStr =  preferences.autoOpenProvidedURL.replacingOccurrences(of: "{text}", with: text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""),
           let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
        try? FileManager.default.removeItem(atPath: screenShotFilePath)
    }
    
    private func detectAndOpenURL(text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf8.count))
        
        matches?.forEach{ match in
            guard let range = Range(match.range, in: text),
                  case let urlStr = String(text[range]),
                  let url = URL(string: urlStr)
            else {return}
            
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
    
    func detectText(in image: CGImage) {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Error detecting text: \(error)")
            } else {
                if let result = self.handleDetectionResults(results: request.results) {
                    if self.preferences.autoOpenCapturedURL {
                        self.detectAndOpenURL(text: result)
                    }
                    self.precessDetectedText(result)
                }
            }
        }
        
        request.recognitionLanguages = [preferences.recongitionLanguage.languageCode()]
        request.recognitionLevel = .accurate
        
        performDetection(request: request, image: image)
    }
    
    private func performDetection(request: VNRecognizeTextRequest, image: CGImage) {
        let requests = [request]
        
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform(requests)
            } catch {
                print("Error: \(error)")
            }
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
                        output.append(preferences.ignoreLineBreaks ? " ":"\n")
                    }
                    output.append(text.string)
                }
            }
        }
        return output
    }
}
