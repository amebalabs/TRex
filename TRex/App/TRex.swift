import SwiftUI
import Vision

class TRex: NSObject {
    public static let shared = TRex()
    let preferences = Preferences.shared

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
    
    func capture() {
        _capture(completionHandler: { [weak self] text in
            guard let text = text else { return }
            self?.setPasteboard(text)
        })
    }

    private func _capture(completionHandler: (String?) -> Void) {
        guard task == nil else { return }
        task = Process()
        task?.executableURL = sceenCaptureURL

        task?.arguments = screenCaptureArguments

        do {
            try task?.run()
        } catch {
            print("Failed to capture")
            task = nil
            return
        }

        task?.waitUntilExit()
        task = nil

        guard let image = NSImage(contentsOfFile: screenShotFilePath)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completionHandler(nil)
            return
        }

        let text = parseQR(image: image)
        guard text.isEmpty else {
            completionHandler(text)
            return
        }
        detectText(in: image)
    }

    func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    func setPasteboard(_ text: String) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(text, forType: .string)
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
                    let pasteBoard = NSPasteboard.general
                    pasteBoard.clearContents()
                    pasteBoard.setString(result, forType: .string)
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
                        output.append("\n")
                    }
                    output.append(text.string)
                }
            }
        }
        return output
    }
}
