import Foundation
import AppKit
import AnyLanguageModel

/// Unified provider using AnyLanguageModel for all backends
public final class UnifiedLanguageModelProvider: LLMProvider, @unchecked Sendable {
    struct PreparedOCRRequest {
        let prompt: String
        let imageData: Data
        let mimeType: String
    }

    public var name: String
    public var supportedModels: [String]

    private var model: any LanguageModel
    private var session: LanguageModelSession

    /// Initialize with provider type
    public init(providerType: LLMProviderType, apiKey: String?, endpoint: String?, modelName: String) throws {
        switch providerType {
        case .openai:
            guard let key = apiKey, !key.isEmpty else {
                throw LLMError.invalidAPIKey
            }

            self.name = "OpenAI"
            self.supportedModels = ["gpt-5.2", "gpt-4.1-mini", "gpt-4-turbo", "gpt-4"]

            // Use custom endpoint if provided (for OpenAI-compatible services)
            if let customEndpoint = endpoint, !customEndpoint.isEmpty {
                self.model = OpenAILanguageModel(
                    baseURL: URL(string: customEndpoint)!,
                    apiKey: key,
                    model: modelName
                )
            } else {
                self.model = OpenAILanguageModel(
                    apiKey: key,
                    model: modelName
                )
            }

        case .anthropic:
            guard let key = apiKey, !key.isEmpty else {
                throw LLMError.invalidAPIKey
            }

            self.name = "Anthropic"
            self.supportedModels = ["claude-sonnet-4-5-20250929", "claude-haiku-4-5", "claude-sonnet-4-20250514"]

            self.model = AnthropicLanguageModel(
                apiKey: key,
                model: modelName
            )

        case .custom:
            self.name = "Custom (OpenAI-compatible)"
            self.supportedModels = ["llama3.2", "qwen3", "mistral"]

            // OpenAI-compatible servers (LM Studio, Ollama, vLLM, etc.) expose
            // a /chat/completions endpoint. Default to Ollama's local OpenAI
            // bridge so a bare install still talks to a local server.
            let baseURL: URL
            if let customEndpoint = endpoint, !customEndpoint.isEmpty {
                guard let url = URL(string: customEndpoint) else {
                    throw LLMError.invalidEndpoint
                }
                baseURL = url
            } else {
                baseURL = URL(string: "http://localhost:11434/v1")!
            }

            // Local servers ignore the key; remote ones (OpenRouter, hosted
            // vLLM) require it, so forward whatever the user configured.
            self.model = OpenAILanguageModel(
                baseURL: baseURL,
                apiKey: apiKey ?? "",
                model: modelName
            )

        case .apple:
            self.name = "Apple Foundation Models"
            self.supportedModels = ["apple-intelligence"]

            if #available(macOS 26.0, *) {
                self.model = SystemLanguageModel.default
            } else {
                throw LLMError.modelNotAvailable("Apple Intelligence requires macOS 15.1 (Sequoia) or later")
            }
        }

        self.session = LanguageModelSession(model: model)
    }

    init(model: any LanguageModel) {
        self.name = "Test"
        self.supportedModels = []
        self.model = model
        self.session = LanguageModelSession(model: model)
    }

    /// Perform OCR using a vision-capable LLM.
    public func performOCR(
        image: NSImage,
        prompt: String?,
        model: String
    ) async throws -> String {
        let request = try Self.prepareOCRRequest(image: image, prompt: prompt)
        let imageSegment = Transcript.ImageSegment(
            data: request.imageData,
            mimeType: request.mimeType
        )
        let ocrSession = LanguageModelSession(model: self.model)
        let response = try await ocrSession.respond(
            to: request.prompt,
            image: imageSegment
        )
        return response.content
    }

    static func prepareOCRRequest(image: NSImage, prompt: String?) throws -> PreparedOCRRequest {
        let trimmedPrompt = prompt?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPrompt: String
        if let trimmedPrompt, !trimmedPrompt.isEmpty {
            resolvedPrompt = trimmedPrompt
        } else {
            resolvedPrompt = PromptTemplates.defaultOCRPrompt
        }

        return PreparedOCRRequest(
            prompt: resolvedPrompt,
            imageData: try ImagePreprocessor().preprocess(image),
            mimeType: "image/jpeg"
        )
    }

    /// Process text with LLM
    public func processText(
        _ text: String,
        prompt: String,
        model: String
    ) async throws -> String {
        // Replace {text} placeholder in prompt
        let fullPrompt = prompt.replacingOccurrences(of: "{text}", with: text)

        // For Apple, use instructions-based approach
        if case .apple = self.getProviderType() {
            if #available(macOS 26.0, *) {
                let instructions = Instructions(prompt)
                let sessionWithInstructions = LanguageModelSession(
                    model: self.model,
                    instructions: instructions
                )
                let response = try await sessionWithInstructions.respond(to: Prompt(text))
                return response.content
            } else {
                throw LLMError.modelNotAvailable("Apple Intelligence requires macOS 15.1 (Sequoia) or later")
            }
        }

        // For other providers, use the full prompt directly
        let response = try await session.respond(to: Prompt(fullPrompt))
        return response.content
    }

    /// Configure the provider (no-op for AnyLanguageModel)
    public func configure(apiKey: String?, endpoint: String?) {
        // Configuration happens at init time with AnyLanguageModel
        // This method is kept for protocol compatibility
    }

    /// Check if provider can connect
    public func checkConnectivity() async -> Bool {
        // For Apple, check availability
        if case .apple = self.getProviderType() {
            if #available(macOS 26.0, *) {
                return SystemLanguageModel.default.isAvailable
            }
            return false
        }

        // For other providers, assume connectivity if model was created successfully
        return true
    }

    // Helper to determine provider type from model
    private func getProviderType() -> LLMProviderType {
        if model is OpenAILanguageModel {
            return .openai
        } else if model is AnthropicLanguageModel {
            return .anthropic
        } else if model is OllamaLanguageModel {
            return .custom
        } else if #available(macOS 26.0, *), model is SystemLanguageModel {
            return .apple
        }
        return .openai // fallback
    }
}
