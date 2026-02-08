import Foundation
import AppKit

/// Protocol for LLM providers
public protocol LLMProvider {
    /// Provider name
    var name: String { get }

    /// Supported models
    var supportedModels: [String] { get }

    /// Perform OCR using vision-capable LLM
    /// - Parameters:
    ///   - image: The image to perform OCR on
    ///   - prompt: Optional custom prompt (uses default if nil)
    ///   - model: The model to use
    /// - Returns: Extracted text
    func performOCR(
        image: NSImage,
        prompt: String?,
        model: String
    ) async throws -> String

    /// Process text with LLM
    /// - Parameters:
    ///   - text: The text to process
    ///   - prompt: The prompt to use (should include {text} placeholder)
    ///   - model: The model to use
    /// - Returns: Processed text
    func processText(
        _ text: String,
        prompt: String,
        model: String
    ) async throws -> String

    /// Configure the provider
    /// - Parameters:
    ///   - apiKey: API key (optional for custom endpoints)
    ///   - endpoint: Custom endpoint URL (optional)
    func configure(apiKey: String?, endpoint: String?)

    /// Check if provider can connect
    /// - Returns: True if connection successful
    func checkConnectivity() async -> Bool
}
