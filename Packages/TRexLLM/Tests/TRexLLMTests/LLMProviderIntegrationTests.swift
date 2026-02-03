import XCTest
import AppKit
@testable import TRexLLM

/// Integration tests that make real API calls to LLM providers.
///
/// These tests require environment variables to be set:
/// - OPENAI_API_KEY for OpenAI tests
/// - ANTHROPIC_API_KEY for Anthropic tests
///
/// Tests are skipped if the corresponding API key is not available.
final class LLMProviderIntegrationTests: XCTestCase {

    // MARK: - Test Helpers

    private func openAIKey() throws -> String {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty else {
            throw XCTSkip("OPENAI_API_KEY not set")
        }
        return key
    }

    private func anthropicKey() throws -> String {
        guard let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty else {
            throw XCTSkip("ANTHROPIC_API_KEY not set")
        }
        return key
    }

    /// Create a test image with rendered text for OCR testing
    private func createTestImageWithText(_ text: String) -> NSImage {
        let size = NSSize(width: 400, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()

        // White background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()

        // Draw text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.black,
        ]
        let nsText = text as NSString
        nsText.draw(at: NSPoint(x: 20, y: 40), withAttributes: attributes)

        image.unlockFocus()
        return image
    }

    // MARK: - Provider Initialization

    func testOpenAIProviderInitialization() throws {
        let key = try openAIKey()

        let provider = try UnifiedLanguageModelProvider(
            providerType: .openai,
            apiKey: key,
            endpoint: nil,
            modelName: "gpt-4o"
        )

        XCTAssertEqual(provider.name, "OpenAI")
    }

    func testAnthropicProviderInitialization() throws {
        let key = try anthropicKey()

        let provider = try UnifiedLanguageModelProvider(
            providerType: .anthropic,
            apiKey: key,
            endpoint: nil,
            modelName: "claude-sonnet-4-5-20250929"
        )

        XCTAssertEqual(provider.name, "Anthropic")
    }

    func testProviderInitFailsWithoutAPIKey() {
        XCTAssertThrowsError(
            try UnifiedLanguageModelProvider(
                providerType: .openai,
                apiKey: nil,
                endpoint: nil,
                modelName: "gpt-4o"
            )
        ) { error in
            XCTAssertTrue(error is LLMError)
            if case LLMError.invalidAPIKey = error {
                // Expected
            } else {
                XCTFail("Expected invalidAPIKey error, got: \(error)")
            }
        }
    }

    func testProviderInitFailsWithEmptyAPIKey() {
        XCTAssertThrowsError(
            try UnifiedLanguageModelProvider(
                providerType: .anthropic,
                apiKey: "",
                endpoint: nil,
                modelName: "claude-sonnet-4-5-20250929"
            )
        ) { error in
            if case LLMError.invalidAPIKey = error {
                // Expected
            } else {
                XCTFail("Expected invalidAPIKey error, got: \(error)")
            }
        }
    }

    // MARK: - Text Processing (OpenAI)

    func testOpenAITextProcessing() async throws {
        let key = try openAIKey()

        let provider = try UnifiedLanguageModelProvider(
            providerType: .openai,
            apiKey: key,
            endpoint: nil,
            modelName: "gpt-4o"
        )

        let result = try await provider.processText(
            "Helo wrld, ths is a tset.",
            prompt: "Fix the spelling errors in this text. Return only the corrected text:\n{text}",
            model: "gpt-4o"
        )

        XCTAssertFalse(result.isEmpty, "Response should not be empty")
        // The corrected text should contain "Hello" and "world"
        let lowered = result.lowercased()
        XCTAssertTrue(lowered.contains("hello"), "Corrected text should contain 'hello', got: \(result)")
        XCTAssertTrue(lowered.contains("world"), "Corrected text should contain 'world', got: \(result)")
    }

    // MARK: - Text Processing (Anthropic)

    func testAnthropicTextProcessing() async throws {
        let key = try anthropicKey()

        let provider = try UnifiedLanguageModelProvider(
            providerType: .anthropic,
            apiKey: key,
            endpoint: nil,
            modelName: "claude-sonnet-4-5-20250929"
        )

        let result = try await provider.processText(
            "Helo wrld, ths is a tset.",
            prompt: "Fix the spelling errors in this text. Return only the corrected text:\n{text}",
            model: "claude-sonnet-4-5-20250929"
        )

        XCTAssertFalse(result.isEmpty, "Response should not be empty")
        let lowered = result.lowercased()
        XCTAssertTrue(lowered.contains("hello"), "Corrected text should contain 'hello', got: \(result)")
        XCTAssertTrue(lowered.contains("world"), "Corrected text should contain 'world', got: \(result)")
    }

    // MARK: - OCR (OpenAI)

    func testOpenAIOCR() async throws {
        let key = try openAIKey()

        let provider = try UnifiedLanguageModelProvider(
            providerType: .openai,
            apiKey: key,
            endpoint: nil,
            modelName: "gpt-4o"
        )

        let testImage = createTestImageWithText("Hello TRex")

        let result = try await provider.performOCR(
            image: testImage,
            prompt: nil,
            model: "gpt-4o"
        )

        XCTAssertFalse(result.isEmpty, "OCR result should not be empty")
        let lowered = result.lowercased()
        XCTAssertTrue(
            lowered.contains("hello") || lowered.contains("trex"),
            "OCR should recognize text from image, got: \(result)"
        )
    }

    // MARK: - OCR (Anthropic)

    func testAnthropicOCR() async throws {
        let key = try anthropicKey()

        let provider = try UnifiedLanguageModelProvider(
            providerType: .anthropic,
            apiKey: key,
            endpoint: nil,
            modelName: "claude-sonnet-4-5-20250929"
        )

        let testImage = createTestImageWithText("Hello TRex")

        let result = try await provider.performOCR(
            image: testImage,
            prompt: nil,
            model: "claude-sonnet-4-5-20250929"
        )

        XCTAssertFalse(result.isEmpty, "OCR result should not be empty")
        let lowered = result.lowercased()
        XCTAssertTrue(
            lowered.contains("hello") || lowered.contains("trex"),
            "OCR should recognize text from image, got: \(result)"
        )
    }

    // MARK: - Connectivity

    func testOpenAIConnectivity() async throws {
        let key = try openAIKey()

        let provider = try UnifiedLanguageModelProvider(
            providerType: .openai,
            apiKey: key,
            endpoint: nil,
            modelName: "gpt-4o"
        )

        let connected = await provider.checkConnectivity()
        XCTAssertTrue(connected)
    }

    func testAnthropicConnectivity() async throws {
        let key = try anthropicKey()

        let provider = try UnifiedLanguageModelProvider(
            providerType: .anthropic,
            apiKey: key,
            endpoint: nil,
            modelName: "claude-sonnet-4-5-20250929"
        )

        let connected = await provider.checkConnectivity()
        XCTAssertTrue(connected)
    }

    // MARK: - NetworkChecker

    func testNetworkCheckerDetectsConnectivity() async {
        let checker = NetworkChecker()
        // Give the monitor a moment to initialize
        try? await Task.sleep(nanoseconds: 500_000_000)
        // On a machine with internet, this should be true
        XCTAssertTrue(checker.isNetworkAvailable(), "Network should be available on test machine")
    }

    func testNetworkCheckerCanReachPublicHost() async {
        let checker = NetworkChecker()
        try? await Task.sleep(nanoseconds: 500_000_000)
        // Use a host that reliably responds to HEAD requests
        let reachable = await checker.checkConnectivity(to: URL(string: "https://www.apple.com")!)
        XCTAssertTrue(reachable, "Public host should be reachable")
    }

    // MARK: - Configuration Resolution Integration

    func testConfigurationResolvesOCRKeyFromEnvironment() {
        let existingKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]

        setenv("OPENAI_API_KEY", "integration-test-key", 1)
        defer {
            if let existing = existingKey {
                setenv("OPENAI_API_KEY", existing, 1)
            } else {
                unsetenv("OPENAI_API_KEY")
            }
        }

        let config = LLMConfiguration(ocrProvider: .openai)
        XCTAssertEqual(config.resolveOCRAPIKey(), "integration-test-key")
    }

    func testConfigurationResolvesPostProcessKeyFromEnvironment() {
        let existingKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]

        setenv("ANTHROPIC_API_KEY", "integration-test-anthropic", 1)
        defer {
            if let existing = existingKey {
                setenv("ANTHROPIC_API_KEY", existing, 1)
            } else {
                unsetenv("ANTHROPIC_API_KEY")
            }
        }

        let config = LLMConfiguration(postProcessProvider: .anthropic)
        XCTAssertEqual(config.resolvePostProcessAPIKey(), "integration-test-anthropic")
    }
}
