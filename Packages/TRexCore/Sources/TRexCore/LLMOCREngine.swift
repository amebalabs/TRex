import Foundation
import AppKit
import Vision
import OSLog
import TRexLLM

/// OCR engine that uses LLM vision capabilities
public final class LLMOCREngine: @unchecked Sendable, OCREngine {
    public var name: String { "LLM Vision" }
    public var identifier: String { "llm" }
    public var priority: Int { 60 } // Higher priority than Vision/Tesseract

    private let logger = Logger(subsystem: "com.ameba.TRex", category: "LLMOCREngine")
    private var provider: LLMProvider?
    private var config: LLMConfiguration
    private let networkChecker: NetworkChecker
    private let fallbackEngine: OCREngine?

    public init(config: LLMConfiguration, fallbackEngine: OCREngine? = nil) {
        self.config = config
        self.networkChecker = NetworkChecker()
        self.fallbackEngine = fallbackEngine

        // Create unified provider
        do {
            self.provider = try UnifiedLanguageModelProvider(
                providerType: config.ocrProvider,
                apiKey: config.resolveOCRAPIKey(),
                endpoint: config.ocrCustomEndpoint,
                modelName: config.ocrModel
            )
            logger.info("✅ LLM OCR provider initialized: \(config.ocrProvider.rawValue)")
        } catch {
            logger.error("❌ Failed to create LLM provider: \(error.localizedDescription, privacy: .public)")
            self.provider = nil

            if fallbackEngine == nil {
                logger.warning("⚠️ No fallback engine available, LLM OCR will not function")
            }
        }
    }

    public func supportsLanguage(_ language: String) -> Bool {
        // LLMs support all languages
        return true
    }

    public func recognizeText(in image: CGImage, languages: [String], recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        logger.info("🤖 LLM OCR starting")

        // Check if provider is available
        guard let provider = provider else {
            logger.warning("⚠️ LLM provider not available, attempting fallback")
            return try await fallbackIfNeeded(image: image, languages: languages, recognitionLevel: recognitionLevel, error: LLMError.invalidAPIKey)
        }

        // Check network connectivity
        guard networkChecker.isNetworkAvailable() else {
            logger.warning("⚠️ Network unavailable, attempting fallback")
            return try await fallbackIfNeeded(image: image, languages: languages, recognitionLevel: recognitionLevel, error: LLMError.networkUnavailable)
        }

        // Check provider connectivity
        let canConnect = await provider.checkConnectivity()
        guard canConnect else {
            logger.warning("⚠️ Cannot connect to LLM provider, attempting fallback")
            return try await fallbackIfNeeded(image: image, languages: languages, recognitionLevel: recognitionLevel, error: LLMError.networkUnavailable)
        }

        do {
            // Convert CGImage to NSImage
            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))

            // Perform LLM OCR
            let text = try await provider.performOCR(
                image: nsImage,
                prompt: config.ocrPrompt.isEmpty ? nil : config.ocrPrompt,
                model: config.ocrModel
            )

            logger.info("✅ LLM OCR complete: \(text.count, privacy: .public) characters")

            return OCRResult(
                text: text,
                confidence: 0.95, // LLMs typically have high confidence
                recognizedLanguages: languages,
                engineName: "LLM Vision (\(config.ocrProvider.rawValue))",
                recognitionLevel: "high-accuracy"
            )
        } catch {
            logger.error("❌ LLM OCR failed: \(error.localizedDescription, privacy: .public)")
            return try await fallbackIfNeeded(image: image, languages: languages, recognitionLevel: recognitionLevel, error: error)
        }
    }

    public func recognizeText(in image: CGImage, recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        return try await recognizeText(in: image, languages: ["en-US"], recognitionLevel: recognitionLevel)
    }

    private func fallbackIfNeeded(image: CGImage, languages: [String], recognitionLevel: VNRequestTextRecognitionLevel, error: Error) async throws -> OCRResult {
        if config.fallbackToBuiltInOCR, let fallback = fallbackEngine {
            logger.info("🔄 Falling back to \(fallback.name, privacy: .public)")
            return try await fallback.recognizeText(in: image, languages: languages, recognitionLevel: recognitionLevel)
        } else {
            throw error
        }
    }

    /// Update configuration
    public func updateConfiguration(_ newConfig: LLMConfiguration) {
        self.config = newConfig

        // Recreate provider with new configuration
        do {
            self.provider = try UnifiedLanguageModelProvider(
                providerType: newConfig.ocrProvider,
                apiKey: newConfig.resolveOCRAPIKey(),
                endpoint: newConfig.ocrCustomEndpoint,
                modelName: newConfig.ocrModel
            )
            logger.info("✅ LLM OCR provider updated: \(newConfig.ocrProvider.rawValue)")
        } catch {
            logger.error("❌ Failed to update LLM provider: \(error.localizedDescription, privacy: .public)")
            self.provider = nil
        }
    }
}
