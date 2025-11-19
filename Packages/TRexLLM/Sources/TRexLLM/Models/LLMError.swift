import Foundation

/// Errors that can occur during LLM operations
public enum LLMError: Error, LocalizedError {
    case networkUnavailable
    case invalidAPIKey
    case invalidEndpoint
    case providerError(String)
    case imageProcessingFailed
    case responseParsingFailed
    case timeout
    case invalidConfiguration
    case unsupportedOperation(String)
    case modelNotAvailable(String)
    case configurationError(String)

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is unavailable. Please check your internet connection."
        case .invalidAPIKey:
            return "Invalid API key. Please check your LLM provider configuration."
        case .invalidEndpoint:
            return "Invalid endpoint URL. Please check your custom endpoint configuration."
        case .providerError(let message):
            return "LLM provider error: \(message)"
        case .imageProcessingFailed:
            return "Failed to process image for LLM request."
        case .responseParsingFailed:
            return "Failed to parse response from LLM provider."
        case .timeout:
            return "LLM request timed out."
        case .invalidConfiguration:
            return "Invalid LLM configuration. Please check your settings."
        case .unsupportedOperation(let message):
            return "Unsupported operation: \(message)"
        case .modelNotAvailable(let message):
            return "Model not available: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}
