import AppKit
import Vision
import XCTest
@testable import TRexCore

final class TesseractOCREngineTests: XCTestCase {
    private func makeGrayscaleImage(with text: String) -> CGImage {
        let width = 1_400
        let height = 320
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        (text as NSString).draw(
            at: NSPoint(x: 80, y: 120),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 56),
                .foregroundColor: NSColor.black,
            ]
        )
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage()!
    }

    func testFallbackRespectsTesseractPreferenceAndDoesNotReenter() {
        XCTAssertFalse(
            TRex.shouldAttemptTesseractFallback(
                attemptedEngineID: "vision",
                tesseractEnabled: false,
                tesseractLanguagesConfigured: true
            )
        )
        XCTAssertFalse(
            TRex.shouldAttemptTesseractFallback(
                attemptedEngineID: "tesseract",
                tesseractEnabled: true,
                tesseractLanguagesConfigured: true
            )
        )
        // Enabled but with every language unticked must not run Tesseract:
        // recognition would fall back to a stale language code and could
        // trigger a traineddata download mid-capture.
        XCTAssertFalse(
            TRex.shouldAttemptTesseractFallback(
                attemptedEngineID: "vision",
                tesseractEnabled: true,
                tesseractLanguagesConfigured: false
            )
        )
        XCTAssertTrue(
            TRex.shouldAttemptTesseractFallback(
                attemptedEngineID: "vision",
                tesseractEnabled: true,
                tesseractLanguagesConfigured: true
            )
        )
    }

    // MARK: - Empty result recovery

    // An empty OCR result must be carried forward — not dropped — so that
    // macOS 26 document/table recognition can still inspect the captured image
    // before the pipeline's final empty-text handling decides the outcome.

    private func makeResult(text: String, engineName: String, sourceImage: CGImage? = nil) -> OCRResult {
        OCRResult(
            text: text,
            confidence: 0,
            recognizedLanguages: [],
            engineName: engineName,
            sourceImage: sourceImage
        )
    }

    func testNonEmptyTesseractFallbackReplacesEmptyResult() {
        let recovered = TRex.resolveEmptyOCRRecovery(
            original: makeResult(text: " \n", engineName: "Vision"),
            fallback: makeResult(text: "Recovered", engineName: "Tesseract")
        )

        XCTAssertEqual(recovered?.text, "Recovered")
        XCTAssertEqual(recovered?.engineName, "Tesseract")
    }

    func testEmptyResultIsCarriedForwardWhenFallbackIsMissing() {
        let sourceImage = makeGrayscaleImage(with: "table cells only")
        let recovered = TRex.resolveEmptyOCRRecovery(
            original: makeResult(text: "", engineName: "Vision", sourceImage: sourceImage),
            fallback: nil
        )

        XCTAssertNotNil(recovered)
        XCTAssertEqual(recovered?.engineName, "Vision")
        // Table detection reads the captured image off the carried result.
        XCTAssertTrue(recovered?.sourceImage === sourceImage)
    }

    func testEmptyTesseractFallbackKeepsOriginalEmptyResult() {
        let sourceImage = makeGrayscaleImage(with: "table cells only")
        let recovered = TRex.resolveEmptyOCRRecovery(
            original: makeResult(text: "", engineName: "Vision", sourceImage: sourceImage),
            fallback: makeResult(text: "  ", engineName: "Tesseract")
        )

        XCTAssertEqual(recovered?.engineName, "Vision")
        XCTAssertTrue(recovered?.sourceImage === sourceImage)
    }

    // MARK: - recoverEmptyOCRResult (instance-level recovery)

    /// Preferences.shared persists to UserDefaults; restore the touched key so
    /// tests never change the developer's real settings.
    @MainActor
    private func withTesseractEnabled<T>(_ enabled: Bool, _ body: () async -> T) async -> T {
        let original = Preferences.shared.tesseractEnabled
        Preferences.shared.tesseractEnabled = enabled
        defer { Preferences.shared.tesseractEnabled = original }
        return await body()
    }

    @MainActor
    func testRecoveryCarriesEmptyResultForwardWhenTesseractIsUnavailable() async {
        let trex = TRex()
        let sourceImage = makeGrayscaleImage(with: "table cells only")
        let original = makeResult(text: "", engineName: "Vision", sourceImage: sourceImage)

        let recovered = await withTesseractEnabled(false) {
            await trex.recoverEmptyOCRResult(
                original,
                cgImage: sourceImage,
                languages: [],
                attemptedEngineID: "vision"
            )
        }

        XCTAssertEqual(recovered?.engineName, "Vision")
        XCTAssertTrue(recovered?.sourceImage === sourceImage,
                      "Carry-through must preserve the captured image for table detection")
    }

    @MainActor
    func testRecoveryDoesNotRetryAfterHardRecognitionFailure() async {
        let trex = TRex()
        let image = makeGrayscaleImage(with: "irrelevant")

        // nil means recognition failed and engine fallback already ran inside
        // that path; recovery must not launch a second Tesseract attempt.
        let recovered = await withTesseractEnabled(true) {
            await trex.recoverEmptyOCRResult(
                nil,
                cgImage: image,
                languages: [],
                attemptedEngineID: "vision"
            )
        }

        XCTAssertNil(recovered)
    }
}
