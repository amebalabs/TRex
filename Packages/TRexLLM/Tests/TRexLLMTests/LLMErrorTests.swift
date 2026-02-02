import XCTest
@testable import TRexLLM

final class LLMErrorTests: XCTestCase {
    func testErrorDescriptions() {
        let errors: [(LLMError, String)] = [
            (.networkUnavailable, "Network is unavailable"),
            (.invalidAPIKey, "Invalid API key"),
            (.invalidEndpoint, "Invalid endpoint URL"),
            (.providerError("Test error"), "LLM provider error: Test error"),
            (.imageProcessingFailed, "Failed to process image"),
            (.responseParsingFailed, "Failed to parse response"),
            (.timeout, "LLM request timed out"),
            (.invalidConfiguration, "Invalid LLM configuration"),
            (.unsupportedOperation("vision not supported"), "vision not supported"),
            (.modelNotAvailable("requires macOS 15.1"), "requires macOS 15.1"),
            (.configurationError("bad config"), "bad config"),
        ]

        for (error, expectedSubstring) in errors {
            XCTAssertTrue(
                error.localizedDescription.contains(expectedSubstring),
                "Error description for \(error) should contain '\(expectedSubstring)', got: '\(error.localizedDescription)'"
            )
        }
    }
}
