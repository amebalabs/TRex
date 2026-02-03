import Foundation

/// TRexLLM - LLM integration for TRex OCR
///
/// This package provides LLM-powered OCR and post-processing capabilities.
///
/// Features:
/// - LLM OCR Engine: Use vision-capable LLMs for text recognition
/// - Post-Processing: Enhance OCR results with error correction and formatting
/// - Multiple Providers: OpenAI, Anthropic, and OpenAI-compatible endpoints
///
/// Usage:
/// ```swift
/// // Configure LLM
/// let config = LLMConfiguration(
///     provider: .openai,
///     enableLLMOCR: true,
///     enablePostProcessing: true
/// )
///
/// // Create OCR engine
/// let engine = LLMOCREngine(config: config, fallbackEngine: VisionOCREngine())
///
/// // Create post-processor
/// let processor = LLMPostProcessor(config: config)
/// ```
public struct TRexLLM {
    public static let version = "1.0.0"
}
