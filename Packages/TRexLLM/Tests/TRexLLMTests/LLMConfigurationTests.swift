import XCTest
@testable import TRexLLM

final class LLMConfigurationTests: XCTestCase {
    func testDefaultConfiguration() {
        let config = LLMConfiguration()

        XCTAssertEqual(config.provider, .openai)
        XCTAssertEqual(config.ocrModel, "gpt-4o")
        XCTAssertEqual(config.postProcessModel, "gpt-4o")
        XCTAssertFalse(config.enableLLMOCR)
        XCTAssertFalse(config.enablePostProcessing)
        XCTAssertTrue(config.fallbackToBuiltInOCR)
        XCTAssertTrue(config.showProcessingIndicator)
    }

    func testResolveAPIKeyFromConfiguration() {
        let config = LLMConfiguration(
            provider: .openai,
            apiKey: "test-key"
        )

        XCTAssertEqual(config.resolveAPIKey(), "test-key")
    }

    func testResolveAPIKeyFromEnvironment() {
        setenv("OPENAI_API_KEY", "env-key", 1)
        defer { unsetenv("OPENAI_API_KEY") }

        let config = LLMConfiguration(provider: .openai)
        XCTAssertEqual(config.resolveAPIKey(), "env-key")
    }

    func testProviderTypeDisplayNames() {
        XCTAssertEqual(LLMProviderType.openai.displayName, "OpenAI")
        XCTAssertEqual(LLMProviderType.anthropic.displayName, "Anthropic")
        XCTAssertEqual(LLMProviderType.custom.displayName, "Custom")
    }

    func testPromptTemplates() {
        XCTAssertFalse(PromptTemplates.defaultOCRPrompt.isEmpty)
        XCTAssertFalse(PromptTemplates.defaultPostProcessPrompt.isEmpty)
        XCTAssertTrue(PromptTemplates.defaultPostProcessPrompt.contains("{text}"))
    }
}
