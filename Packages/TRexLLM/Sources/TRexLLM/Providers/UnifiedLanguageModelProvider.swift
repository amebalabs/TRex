import Foundation
import AppKit
import AnyLanguageModel

/// Unified provider using AnyLanguageModel for all backends
public class UnifiedLanguageModelProvider: LLMProvider {
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
            self.supportedModels = ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"]

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
            self.supportedModels = ["claude-sonnet-4-5-20250929", "claude-3-5-sonnet-20241022", "claude-3-opus-20240229", "claude-3-haiku-20240307"]

            self.model = AnthropicLanguageModel(
                apiKey: key,
                model: modelName
            )

        case .custom:
            self.name = "Ollama"
            self.supportedModels = ["llama3.2", "llama3.2-vision", "qwen3", "mistral"]

            if let customEndpoint = endpoint, !customEndpoint.isEmpty {
                self.model = OllamaLanguageModel(
                    baseURL: URL(string: customEndpoint)!,
                    model: modelName
                )
            } else {
                // Default Ollama endpoint
                self.model = OllamaLanguageModel(
                    model: modelName
                )
            }

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

    /// Perform OCR using vision-capable LLM
    public func performOCR(
        image: NSImage,
        prompt: String?,
        model: String
    ) async throws -> String {
        // Check if the provider supports vision
        if case .apple = self.getProviderType() {
            throw LLMError.unsupportedOperation("Apple Foundation Models do not support vision/OCR")
        }

        // Convert NSImage to data
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            throw LLMError.imageProcessingFailed
        }

        // Convert to JPEG for efficient transfer
        guard let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
            throw LLMError.imageProcessingFailed
        }

        // Create image segment for AnyLanguageModel
        let imageSegment = Transcript.ImageSegment(
            source: .data(jpegData, mimeType: "image/jpeg")
        )

        // Use provided prompt or default
        let promptText = prompt ?? "Extract all visible text from this image. Preserve the layout and formatting as much as possible. Return only the extracted text without any additional commentary."

        // Perform OCR
        let response = try await session.respond(
            to: promptText,
            image: imageSegment
        )

        return response.content
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
