import AppKit
import Vision
import XCTest

@testable import TRexCore

/// Regression tests for OCR failure recovery (issue #92: Vision text recognition can
/// fail or stall on macOS 27 with E5RT Neural Engine errors).
final class VisionFailureRecoveryTests: XCTestCase {

    /// Create a test image with rendered text
    private func createTestImage(text: String) -> CGImage {
        let size = NSSize(width: 400, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: NSColor.black,
        ]
        (text as NSString).draw(at: NSPoint(x: 20, y: 35), withAttributes: attributes)

        image.unlockFocus()

        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    }

    // MARK: - Fallback engine selection

    func testFallbackPrefersLLMWhenConfigured() {
        XCTAssertEqual(
            TRex.visionFallbackEngineIdentifier(excluding: nil, llmOCRConfigured: true, tesseractConfigured: true),
            "llm"
        )
    }

    func testFallbackUsesTesseractWhenLLMNotConfigured() {
        XCTAssertEqual(
            TRex.visionFallbackEngineIdentifier(excluding: nil, llmOCRConfigured: false, tesseractConfigured: true),
            "tesseract"
        )
    }

    func testFallbackSkipsEngineThatAlreadyFailed() {
        XCTAssertEqual(
            TRex.visionFallbackEngineIdentifier(excluding: "llm", llmOCRConfigured: true, tesseractConfigured: true),
            "tesseract"
        )
        XCTAssertNil(
            TRex.visionFallbackEngineIdentifier(excluding: "llm", llmOCRConfigured: true, tesseractConfigured: false)
        )
        XCTAssertNil(
            TRex.visionFallbackEngineIdentifier(excluding: "tesseract", llmOCRConfigured: false, tesseractConfigured: true)
        )
    }

    func testFallbackReturnsNilWhenNothingConfigured() {
        XCTAssertNil(
            TRex.visionFallbackEngineIdentifier(excluding: nil, llmOCRConfigured: false, tesseractConfigured: false)
        )
    }

    // MARK: - Fallback engine execution (injected test doubles)

    @MainActor
    func testRunFallbackOCRReturnsResultFromInjectedEngine() async {
        let engine = FixedResultOCREngine(text: "Hello from fallback")
        let image = createTestImage(text: "irrelevant")

        let result = await TRex.shared.runFallbackOCR(engine: engine, cgImage: image, languages: ["en-US"])

        XCTAssertEqual(result?.text, "Hello from fallback")
        XCTAssertNotNil(result?.sourceImage, "Fallback result must retain the source image for table detection")
    }

    @MainActor
    func testRunFallbackOCRReturnsNilWhenEngineThrows() async {
        let engine = FailingOCREngine()
        let image = createTestImage(text: "irrelevant")

        let result = await TRex.shared.runFallbackOCR(engine: engine, cgImage: image, languages: ["en-US"])

        XCTAssertNil(result)
    }

    @MainActor
    func testRunFallbackOCRReturnsNilWhenEngineFindsNoText() async {
        let engine = FixedResultOCREngine(text: "   \n  ")
        let image = createTestImage(text: "irrelevant")

        let result = await TRex.shared.runFallbackOCR(engine: engine, cgImage: image, languages: ["en-US"])

        XCTAssertNil(result)
    }

    // MARK: - Vision recognition levels

    /// Both the primary (.accurate) and the retry (.fast) recognition levels must work,
    /// since .fast is the recovery path when .accurate fails at the Neural Engine layer.
    func testVisionRecognizesTextAtBothRecognitionLevels() async throws {
        let engine = VisionOCREngine()
        let image = createTestImage(text: "Hello World")

        let accurate = try await engine.recognizeText(in: image, languages: ["en-US"], recognitionLevel: .accurate)
        XCTAssertTrue(accurate.text.contains("Hello"), "Accurate level should recognize text, got: \(accurate.text)")

        let fast = try await engine.recognizeText(in: image, languages: ["en-US"], recognitionLevel: .fast)
        XCTAssertTrue(fast.text.contains("Hello"), "Fast level should recognize text, got: \(fast.text)")
    }

    // MARK: - Capture state recovery

    /// A failed capture must never leave the in-progress flag set, otherwise every
    /// subsequent menu action is silently ignored until the app restarts.
    @MainActor
    func testFailedCaptureResetsInProgressState() async {
        await TRex.shared.capture(.captureFromFile, imagePath: "/nonexistent/path/\(UUID().uuidString).png")

        XCTAssertFalse(TRex.shared.isCaptureInProgress, "Failed capture left isCaptureInProgress set")
        XCTAssertTrue(TRex.shared.beginCaptureTransaction(), "A new capture must be possible after a failed one")
        TRex.shared.endCaptureTransaction()
    }
}

// MARK: - Test doubles

private struct FixedResultOCREngine: OCREngine {
    let text: String
    let name = "Fixed Result"
    let identifier = "test-fixed"
    let priority = 0

    func supportsLanguage(_ language: String) -> Bool { true }

    func recognizeText(
        in image: CGImage,
        languages: [String],
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> OCRResult {
        OCRResult(text: text, confidence: 1.0, recognizedLanguages: languages, engineName: name)
    }

    func recognizeText(
        in image: CGImage,
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> OCRResult {
        try await recognizeText(in: image, languages: [], recognitionLevel: recognitionLevel)
    }
}

private struct FailingOCREngine: OCREngine {
    struct SimulatedError: Error {}

    let name = "Always Failing"
    let identifier = "test-failing"
    let priority = 0

    func supportsLanguage(_ language: String) -> Bool { true }

    func recognizeText(
        in image: CGImage,
        languages: [String],
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> OCRResult {
        throw SimulatedError()
    }

    func recognizeText(
        in image: CGImage,
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> OCRResult {
        throw SimulatedError()
    }
}
