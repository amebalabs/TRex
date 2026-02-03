import Foundation
import OSLog
import TRexLLM

/// Post-processes OCR text using LLM
public class LLMPostProcessor {
    private let logger = Logger(subsystem: "com.ameba.TRex", category: "LLMPostProcessor")
    private var provider: LLMProvider?
    private var config: LLMConfiguration
    private let networkChecker: NetworkChecker

    public init(config: LLMConfiguration) {
        self.config = config
        self.networkChecker = NetworkChecker()

        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("🔧 INITIALIZING LLM POST-PROCESSOR")
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("📋 Configuration:")
        logger.info("  → Provider: \(config.postProcessProvider.rawValue)")
        logger.info("  → Model: \(config.postProcessModel)")
        logger.info("  → Has API key: \(config.resolvePostProcessAPIKey() != nil)")
        logger.info("  → Has endpoint: \(config.postProcessCustomEndpoint?.isEmpty == false)")
        logger.info("  → Prompt: \(config.postProcessPrompt.isEmpty ? "(empty)" : config.postProcessPrompt.prefix(50).description + "...")")

        // Create unified provider
        do {
            self.provider = try UnifiedLanguageModelProvider(
                providerType: config.postProcessProvider,
                apiKey: config.resolvePostProcessAPIKey(),
                endpoint: config.postProcessCustomEndpoint,
                modelName: config.postProcessModel
            )
            logger.info("✅ LLM post-processor initialized successfully")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } catch {
            logger.error("❌ FAILED TO INITIALIZE POST-PROCESSOR")
            logger.error("  → Error: \(error.localizedDescription)")
            logger.error("  → Type: \(type(of: error))")
            logger.warning("⚠️ Post-processing will not be available")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            self.provider = nil
        }
    }

    /// Process OCR text with LLM
    /// - Parameters:
    ///   - text: The OCR text to process
    ///   - prompt: Optional custom prompt (uses default if nil)
    ///   - metadata: Optional OCR metadata context to help LLM understand the source
    /// - Returns: Processed text
    public func process(_ text: String, prompt: String? = nil, metadata: String? = nil) async throws -> String {
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("🤖 LLM POST-PROCESSING STARTED")
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        logger.info("📋 Configuration:")
        logger.info("  → Provider: \(self.config.postProcessProvider.rawValue)")
        logger.info("  → Model: \(self.config.postProcessModel)")
        logger.info("  → Has custom endpoint: \(self.config.postProcessCustomEndpoint?.isEmpty == false)")

        // Check if provider is available
        guard let provider = provider else {
            logger.error("❌ FAILURE: LLM provider not available")
            logger.error("  → Likely cause: Missing or invalid API key")
            logger.error("  → Check Settings > LLM > Post-Processing section")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            throw LLMError.invalidAPIKey
        }
        logger.info("✅ Provider initialized")

        // Check if text is empty
        guard !text.isEmpty else {
            logger.warning("⚠️ Empty text provided, skipping post-processing")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return text
        }
        logger.info("📝 Input text: \(text.count) characters")
        logger.debug("  → Preview: \(text.prefix(100))...")

        if let metadata = metadata {
            logger.info("📊 OCR Metadata: \(metadata)")
        } else {
            logger.debug("  → No OCR metadata provided")
        }

        // Check network connectivity
        let networkAvailable = networkChecker.isNetworkAvailable()
        logger.info("🌐 Network check: \(networkAvailable ? "✅ Available" : "❌ Unavailable")")
        guard networkAvailable else {
            logger.error("❌ FAILURE: Network unavailable")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            throw LLMError.networkUnavailable
        }

        // Check provider connectivity
        logger.info("🔌 Checking provider connectivity...")
        let canConnect = await provider.checkConnectivity()
        logger.info("  → Result: \(canConnect ? "✅ Connected" : "❌ Cannot connect")")
        guard canConnect else {
            logger.error("❌ FAILURE: Cannot connect to LLM provider")
            logger.error("  → Check API key and endpoint configuration")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            throw LLMError.networkUnavailable
        }

        do {
            var promptToUse = prompt ?? config.postProcessPrompt

            // Prepend OCR metadata context if available
            if let metadata = metadata {
                let contextPrompt = "OCR Context: \(metadata)\n\n"
                promptToUse = promptToUse.isEmpty ? contextPrompt : contextPrompt + promptToUse
            }

            logger.info("💬 Using prompt: \(promptToUse.isEmpty ? "(default/empty)" : promptToUse.prefix(50).description + "...")")

            logger.info("🚀 Sending request to LLM...")
            let processedText = try await provider.processText(
                text,
                prompt: promptToUse,
                model: config.postProcessModel
            )

            logger.info("✅ LLM POST-PROCESSING COMPLETE")
            logger.info("  → Input:  \(text.count) characters")
            logger.info("  → Output: \(processedText.count) characters")
            logger.info("  → Change: \(processedText.count - text.count) characters")
            logger.debug("  → Output preview: \(processedText.prefix(100))...")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            return processedText
        } catch {
            logger.error("❌ LLM POST-PROCESSING FAILED")
            logger.error("  → Error: \(error.localizedDescription)")
            logger.error("  → Type: \(type(of: error))")
            if let llmError = error as? LLMError {
                logger.error("  → LLM Error: \(llmError)")
            }
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            throw error
        }
    }

    /// Process text silently, returning original on failure
    /// - Parameters:
    ///   - text: The OCR text to process
    ///   - prompt: Optional custom prompt (uses default if nil)
    ///   - metadata: Optional OCR metadata context to help LLM understand the source
    /// - Returns: Processed text or original text on failure
    public func processSilently(_ text: String, prompt: String? = nil, metadata: String? = nil) async -> String {
        do {
            return try await process(text, prompt: prompt, metadata: metadata)
        } catch {
            logger.warning("⚠️ Post-processing failed silently, returning original text")
            return text
        }
    }

    /// Update configuration
    public func updateConfiguration(_ newConfig: LLMConfiguration) {
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("🔄 UPDATING LLM POST-PROCESSOR CONFIGURATION")
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("📋 Old config: Provider=\(self.config.postProcessProvider.rawValue), Model=\(self.config.postProcessModel)")
        logger.info("📋 New config: Provider=\(newConfig.postProcessProvider.rawValue), Model=\(newConfig.postProcessModel)")

        self.config = newConfig

        // Recreate provider with new configuration
        do {
            self.provider = try UnifiedLanguageModelProvider(
                providerType: newConfig.postProcessProvider,
                apiKey: newConfig.resolvePostProcessAPIKey(),
                endpoint: newConfig.postProcessCustomEndpoint,
                modelName: newConfig.postProcessModel
            )
            logger.info("✅ LLM post-processor updated successfully")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } catch {
            logger.error("❌ FAILED TO UPDATE POST-PROCESSOR")
            logger.error("  → Error: \(error.localizedDescription)")
            logger.error("  → Type: \(type(of: error))")
            logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            self.provider = nil
        }
    }
}
