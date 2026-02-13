import XCTest
import Vision
import AppKit
@testable import TRexCore
import TRexLLM

/// Tests for LLMOCREngine fallback behavior when the remote LLM call fails.
final class LLMOCRFallbackTests: XCTestCase {

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

    // MARK: - Fallback on invalid API key

    func testFallbackToVisionOnInvalidAPIKey() async throws {
        // Configure with a bogus API key — the LLM call will fail
        let config = LLMConfiguration(
            ocrProvider: .openai,
            ocrAPIKey: "sk-invalid-key-that-will-fail",
            ocrModel: "gpt-4.1-mini",
            enableLLMOCR: true,
            fallbackToBuiltInOCR: true
        )

        let fallbackEngine = VisionOCREngine()
        let engine = LLMOCREngine(config: config, fallbackEngine: fallbackEngine)

        let testImage = createTestImage(text: "Hello World")

        let result = try await engine.recognizeText(
            in: testImage,
            languages: ["en-US"],
            recognitionLevel: .accurate
        )

        // Fallback should have kicked in and returned Vision OCR results
        XCTAssertFalse(result.text.isEmpty, "Fallback should return text, got empty")
        XCTAssertTrue(
            result.engineName?.contains("Vision") == true,
            "Should have fallen back to Vision engine, got: \(result.engineName ?? "nil")"
        )
    }

    // MARK: - No fallback throws error

    func testNoFallbackThrowsOnFailure() async {
        // Configure with a bogus key and NO fallback
        let config = LLMConfiguration(
            ocrProvider: .openai,
            ocrAPIKey: "sk-invalid-key-that-will-fail",
            ocrModel: "gpt-4.1-mini",
            enableLLMOCR: true,
            fallbackToBuiltInOCR: false
        )

        let engine = LLMOCREngine(config: config, fallbackEngine: nil)

        let testImage = createTestImage(text: "Hello World")

        do {
            _ = try await engine.recognizeText(
                in: testImage,
                languages: ["en-US"],
                recognitionLevel: .accurate
            )
            XCTFail("Should have thrown an error without fallback")
        } catch {
            // Expected: error propagated since fallback is disabled
        }
    }

    // MARK: - Fallback disabled but engine provided

    func testFallbackDisabledDoesNotUseFallbackEngine() async {
        // fallbackToBuiltInOCR = false, even with a fallback engine provided
        let config = LLMConfiguration(
            ocrProvider: .openai,
            ocrAPIKey: "sk-invalid-key-that-will-fail",
            ocrModel: "gpt-4.1-mini",
            enableLLMOCR: true,
            fallbackToBuiltInOCR: false
        )

        let fallbackEngine = VisionOCREngine()
        let engine = LLMOCREngine(config: config, fallbackEngine: fallbackEngine)

        let testImage = createTestImage(text: "Hello World")

        do {
            _ = try await engine.recognizeText(
                in: testImage,
                languages: ["en-US"],
                recognitionLevel: .accurate
            )
            XCTFail("Should have thrown an error with fallback disabled")
        } catch {
            // Expected: fallback not used because config says not to
        }
    }

    // MARK: - Fallback on provider not initialized

    func testFallbackWhenProviderNotInitialized() async throws {
        // Use a provider type that requires an API key but don't provide one
        // This causes provider init to fail internally, setting provider = nil
        let config = LLMConfiguration(
            ocrProvider: .anthropic,
            ocrAPIKey: nil,
            ocrModel: "claude-sonnet-4-5-20250929",
            enableLLMOCR: true,
            fallbackToBuiltInOCR: true
        )

        let fallbackEngine = VisionOCREngine()
        let engine = LLMOCREngine(config: config, fallbackEngine: fallbackEngine)

        let testImage = createTestImage(text: "Test Fallback")

        let result = try await engine.recognizeText(
            in: testImage,
            languages: ["en-US"],
            recognitionLevel: .accurate
        )

        XCTAssertFalse(result.text.isEmpty, "Fallback should return text when provider is nil")
        XCTAssertTrue(
            result.engineName?.contains("Vision") == true,
            "Should have fallen back to Vision, got: \(result.engineName ?? "nil")"
        )
    }
}
