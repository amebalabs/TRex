import XCTest
@testable import TRexLLM

final class LLMConfigurationTests: XCTestCase {
    func testDefaultConfiguration() {
        let config = LLMConfiguration()

        XCTAssertEqual(config.ocrProvider, .openai)
        XCTAssertEqual(config.postProcessProvider, .openai)
        XCTAssertEqual(config.ocrModel, "gpt-4.1-mini")
        XCTAssertEqual(config.postProcessModel, "gpt-4.1-mini")
        XCTAssertFalse(config.enableLLMOCR)
        XCTAssertFalse(config.enablePostProcessing)
        XCTAssertTrue(config.fallbackToBuiltInOCR)
        XCTAssertTrue(config.showProcessingIndicator)
    }

    func testResolveOCRAPIKeyFromConfiguration() {
        let config = LLMConfiguration(
            ocrProvider: .openai,
            ocrAPIKey: "test-key"
        )

        XCTAssertEqual(config.resolveOCRAPIKey(), "test-key")
    }

    func testResolvePostProcessAPIKeyFromConfiguration() {
        let config = LLMConfiguration(
            postProcessProvider: .anthropic,
            postProcessAPIKey: "anthropic-key"
        )

        XCTAssertEqual(config.resolvePostProcessAPIKey(), "anthropic-key")
    }

    func testResolveOCRAPIKeyFromEnvironment() {
        setenv("OPENAI_API_KEY", "env-key", 1)
        defer { unsetenv("OPENAI_API_KEY") }

        let config = LLMConfiguration(ocrProvider: .openai)
        XCTAssertEqual(config.resolveOCRAPIKey(), "env-key")
    }

    func testResolvePostProcessAPIKeyFromEnvironment() {
        setenv("ANTHROPIC_API_KEY", "env-anthropic-key", 1)
        defer { unsetenv("ANTHROPIC_API_KEY") }

        let config = LLMConfiguration(postProcessProvider: .anthropic)
        XCTAssertEqual(config.resolvePostProcessAPIKey(), "env-anthropic-key")
    }

    func testConfiguredKeyTakesPrecedenceOverEnvironment() {
        setenv("OPENAI_API_KEY", "env-key", 1)
        defer { unsetenv("OPENAI_API_KEY") }

        let config = LLMConfiguration(
            ocrProvider: .openai,
            ocrAPIKey: "explicit-key"
        )
        XCTAssertEqual(config.resolveOCRAPIKey(), "explicit-key")
    }

    func testCustomProviderReturnsNilAPIKey() {
        let config = LLMConfiguration(ocrProvider: .custom)
        XCTAssertNil(config.resolveOCRAPIKey())
    }

    func testAppleProviderReturnsNilAPIKey() {
        let config = LLMConfiguration(postProcessProvider: .apple)
        XCTAssertNil(config.resolvePostProcessAPIKey())
    }

    func testProviderTypeDisplayNames() {
        XCTAssertEqual(LLMProviderType.openai.displayName, "OpenAI")
        XCTAssertEqual(LLMProviderType.anthropic.displayName, "Anthropic")
        XCTAssertEqual(LLMProviderType.custom.displayName, "Custom")
        XCTAssertEqual(LLMProviderType.apple.displayName, "Apple")
    }

    func testPromptTemplates() {
        XCTAssertFalse(PromptTemplates.defaultOCRPrompt.isEmpty)
        XCTAssertFalse(PromptTemplates.defaultPostProcessPrompt.isEmpty)
        XCTAssertTrue(PromptTemplates.defaultPostProcessPrompt.contains("{text}"))
    }

    func testSeparateProviderConfiguration() {
        let config = LLMConfiguration(
            ocrProvider: .openai,
            ocrAPIKey: "openai-key",
            postProcessProvider: .anthropic,
            postProcessAPIKey: "anthropic-key",
            ocrModel: "gpt-5.2",
            postProcessModel: "claude-sonnet-4-5-20250929"
        )

        XCTAssertEqual(config.ocrProvider, .openai)
        XCTAssertEqual(config.postProcessProvider, .anthropic)
        XCTAssertEqual(config.resolveOCRAPIKey(), "openai-key")
        XCTAssertEqual(config.resolvePostProcessAPIKey(), "anthropic-key")
        XCTAssertEqual(config.ocrModel, "gpt-5.2")
        XCTAssertEqual(config.postProcessModel, "claude-sonnet-4-5-20250929")
    }
}
