import Foundation

/// Configuration for LLM integration
public struct LLMConfiguration: Codable {
    // OCR Provider settings
    public var ocrProvider: LLMProviderType
    public var ocrAPIKey: String?
    public var ocrCustomEndpoint: String?

    // Post-processing Provider settings
    public var postProcessProvider: LLMProviderType
    public var postProcessAPIKey: String?
    public var postProcessCustomEndpoint: String?

    // Model selection
    public var ocrModel: String
    public var postProcessModel: String

    // Feature flags
    public var enableLLMOCR: Bool
    public var enablePostProcessing: Bool

    // Prompts (user-editable)
    public var ocrPrompt: String
    public var postProcessPrompt: String

    // Behavior
    public var fallbackToBuiltInOCR: Bool
    public var showProcessingIndicator: Bool

    // Environment variable keys
    public static let openAIKeyEnvVar = "OPENAI_API_KEY"
    public static let anthropicKeyEnvVar = "ANTHROPIC_API_KEY"

    public init(
        ocrProvider: LLMProviderType = .openai,
        ocrAPIKey: String? = nil,
        ocrCustomEndpoint: String? = nil,
        postProcessProvider: LLMProviderType = .openai,
        postProcessAPIKey: String? = nil,
        postProcessCustomEndpoint: String? = nil,
        ocrModel: String = "gpt-4o",
        postProcessModel: String = "gpt-4o",
        enableLLMOCR: Bool = false,
        enablePostProcessing: Bool = false,
        ocrPrompt: String = PromptTemplates.defaultOCRPrompt,
        postProcessPrompt: String = PromptTemplates.defaultPostProcessPrompt,
        fallbackToBuiltInOCR: Bool = true,
        showProcessingIndicator: Bool = true
    ) {
        self.ocrProvider = ocrProvider
        self.ocrAPIKey = ocrAPIKey
        self.ocrCustomEndpoint = ocrCustomEndpoint
        self.postProcessProvider = postProcessProvider
        self.postProcessAPIKey = postProcessAPIKey
        self.postProcessCustomEndpoint = postProcessCustomEndpoint
        self.ocrModel = ocrModel
        self.postProcessModel = postProcessModel
        self.enableLLMOCR = enableLLMOCR
        self.enablePostProcessing = enablePostProcessing
        self.ocrPrompt = ocrPrompt
        self.postProcessPrompt = postProcessPrompt
        self.fallbackToBuiltInOCR = fallbackToBuiltInOCR
        self.showProcessingIndicator = showProcessingIndicator
    }

    /// Get API key for OCR provider from configuration or environment
    public func resolveOCRAPIKey() -> String? {
        if let key = ocrAPIKey, !key.isEmpty {
            return key
        }

        // Try environment variables
        switch ocrProvider {
        case .openai:
            return ProcessInfo.processInfo.environment[Self.openAIKeyEnvVar]
        case .anthropic:
            return ProcessInfo.processInfo.environment[Self.anthropicKeyEnvVar]
        case .custom, .apple:
            return nil // Custom endpoints and Apple don't need API keys
        }
    }

    /// Get API key for post-processing provider from configuration or environment
    public func resolvePostProcessAPIKey() -> String? {
        if let key = postProcessAPIKey, !key.isEmpty {
            return key
        }

        // Try environment variables
        switch postProcessProvider {
        case .openai:
            return ProcessInfo.processInfo.environment[Self.openAIKeyEnvVar]
        case .anthropic:
            return ProcessInfo.processInfo.environment[Self.anthropicKeyEnvVar]
        case .custom, .apple:
            return nil // Custom endpoints and Apple don't need API keys
        }
    }
}

/// LLM provider types
public enum LLMProviderType: String, Codable, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case custom = "Custom"
    case apple = "Apple"

    public var displayName: String {
        return rawValue
    }
}

/// Prompt templates
public struct PromptTemplates {
    public static let defaultOCRPrompt = """
    Extract all visible text from this image. Preserve the layout and formatting as much as possible. Return only the extracted text without any additional commentary.
    """

    public static let defaultPostProcessPrompt = """
    You are given OCR output that may contain errors. Please:
    1. Correct any obvious spelling or recognition errors
    2. Fix formatting issues (spacing, line breaks)
    3. Preserve the original structure and meaning
    4. Return only the corrected text without explanations

    OCR Text:
    {text}
    """
}
