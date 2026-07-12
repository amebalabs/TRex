import OSLog
import SwiftUI
@preconcurrency import UserNotifications
import Vision
import TRexLLM

/// Bundle identifiers for TRex apps
enum BundleIdentifiers {
    static let gui = "com.ameba.TRex"
    static let cli = "com.ameba.TRex.cli"

    /// Check if current process is the CLI tool
    static var isCLI: Bool {
        Bundle.main.bundleIdentifier == cli
    }
}

// Timeout error for async operations
enum TimeoutError: Error {
    case timedOut
}

// Async timeout utility
func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    guard seconds.isFinite, seconds > 0 else {
        throw TimeoutError.timedOut
    }

    let operationTask = Task { try await operation() }
    let timeoutTask = Task<T, Error> {
        try await Task.sleep(for: .seconds(seconds))
        throw TimeoutError.timedOut
    }

    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            let race = ContinuationRace(continuation)

            Task {
                do {
                    race.resume(with: .success(try await operationTask.value))
                } catch {
                    race.resume(with: .failure(error))
                }
                timeoutTask.cancel()
            }

            Task {
                do {
                    race.resume(with: .success(try await timeoutTask.value))
                } catch {
                    race.resume(with: .failure(error))
                }
                operationTask.cancel()
            }
        }
    } onCancel: {
        operationTask.cancel()
        timeoutTask.cancel()
    }
}

private final class ContinuationRace<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?

    init(_ continuation: CheckedContinuation<Value, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<Value, Error>) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }
}

/// Observable state for LLM processing activity, used to drive menu bar animations.
/// All access is confined to the main actor to ensure thread-safe UI updates.
@MainActor
public final class LLMProcessingState: ObservableObject {
    @Published public var isProcessing: Bool = false

    nonisolated public init() {}

    public func set(_ value: Bool) {
        isProcessing = value
    }
}

@MainActor
public class TRex: NSObject {
    public static let shared = TRex()
    let preferences = Preferences.shared
    private var currentInvocationMode: InvocationMode = .captureScreen
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ameba.TRex", category: "TRexCore")
    private var llmEngine: LLMOCREngine?
    private var llmPostProcessor: LLMPostProcessor?
    public let llmProcessingState = LLMProcessingState()
    public let captureHistoryStore = CaptureHistoryStore()
    public let watchModeManager = WatchModeManager()

    internal private(set) var isCaptureInProgress = false
    let screenCaptureURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

    /// Generate a unique temporary file path for each screen capture.
    private func makeScreenshotFilePath() -> String {
        let directory = NSTemporaryDirectory()
        return NSURL.fileURL(withPathComponents: [directory, "capture-\(UUID().uuidString).png"])!.path
    }

    private func screenCaptureArguments(outputPath: String) -> [String] {
        var out = ["-i"] // capture screen interactively, by selection or window
        if !preferences.captureSound {
            out.append("-x") // do not play sounds
        }
        out.append(outputPath)
        return out
    }

    var hasAutomationsConfigured: Bool {
        Self.hasConfiguredAutomation(
            autoOpenProvidedURL: preferences.autoOpenProvidedURL,
            autoRunShortcut: preferences.autoRunShortcut
        )
    }

    var invocationRequiresAutomation: Bool {
        Self.invocationRequiresAutomation(currentInvocationMode)
    }

    nonisolated static func hasConfiguredAutomation(autoOpenProvidedURL: String, autoRunShortcut: String) -> Bool {
        !autoOpenProvidedURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !autoRunShortcut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    nonisolated static func invocationRequiresAutomation(_ mode: InvocationMode) -> Bool {
        mode == .captureClipboardAndTriggerAutomation ||
            mode == .captureScreenAndTriggerAutomation ||
            mode == .captureFromFileAndTriggerAutomation ||
            mode == .captureMultiRegionAndTriggerAutomation
    }

    nonisolated static func shouldRouteToAutomation(
        mode: InvocationMode,
        autoOpenProvidedURL: String,
        autoRunShortcut: String
    ) -> Bool {
        invocationRequiresAutomation(mode) && hasConfiguredAutomation(
            autoOpenProvidedURL: autoOpenProvidedURL,
            autoRunShortcut: autoRunShortcut
        )
    }

    // MARK: - LLM Integration

    public func initializeLLM() {
        // Auto-enable if either feature is enabled
        let shouldEnable = preferences.llmEnableOCR || preferences.llmEnablePostProcessing

        if !shouldEnable {
            llmEngine = nil
            llmPostProcessor = nil
            return
        }

        // Enable the master flag if needed
        if !preferences.llmEnabled {
            preferences.llmEnabled = true
        }

        let config = createLLMConfiguration()

        // Create LLM engine if OCR is enabled
        if preferences.llmEnableOCR {
            let fallbackEngine = OCRManager.shared.engines.first(where: { $0.identifier == "vision" })
            llmEngine = LLMOCREngine(config: config, fallbackEngine: fallbackEngine)

            // Register with OCRManager
            if let engine = llmEngine {
                OCRManager.shared.registerEngine(engine)
            }
        } else {
            llmEngine = nil
        }

        // Create post-processor if enabled
        if preferences.llmEnablePostProcessing {
            llmPostProcessor = LLMPostProcessor(config: config)
        } else {
            llmPostProcessor = nil
        }

        logger.info("🤖 LLM initialized: OCR=\(self.preferences.llmEnableOCR, privacy: .public), PostProcess=\(self.preferences.llmEnablePostProcessing, privacy: .public)")
    }

    private func createLLMConfiguration() -> LLMConfiguration {
        // Parse OCR provider
        let ocrProviderType: LLMProviderType
        switch preferences.llmOCRProvider {
        case "OpenAI":
            ocrProviderType = .openai
        case "Anthropic":
            ocrProviderType = .anthropic
        case "Custom":
            ocrProviderType = .custom
        case "Apple":
            ocrProviderType = .apple
        default:
            ocrProviderType = .openai
        }

        // Parse post-processing provider
        let postProcessProviderType: LLMProviderType
        switch preferences.llmPostProcessProvider {
        case "OpenAI":
            postProcessProviderType = .openai
        case "Anthropic":
            postProcessProviderType = .anthropic
        case "Custom":
            postProcessProviderType = .custom
        case "Apple":
            postProcessProviderType = .apple
        default:
            postProcessProviderType = .openai
        }

        return LLMConfiguration(
            ocrProvider: ocrProviderType,
            ocrAPIKey: preferences.llmOCRAPIKey.isEmpty ? nil : preferences.llmOCRAPIKey,
            ocrCustomEndpoint: preferences.llmOCRCustomEndpoint.isEmpty ? nil : preferences.llmOCRCustomEndpoint,
            postProcessProvider: postProcessProviderType,
            postProcessAPIKey: preferences.llmPostProcessAPIKey.isEmpty ? nil : preferences.llmPostProcessAPIKey,
            postProcessCustomEndpoint: preferences.llmPostProcessCustomEndpoint.isEmpty ? nil : preferences.llmPostProcessCustomEndpoint,
            ocrModel: preferences.llmOCRModel,
            postProcessModel: preferences.llmPostProcessModel,
            enableLLMOCR: preferences.llmEnableOCR,
            enablePostProcessing: preferences.llmEnablePostProcessing,
            ocrPrompt: preferences.llmOCRPrompt,
            postProcessPrompt: preferences.llmPostProcessPrompt,
            fallbackToBuiltInOCR: preferences.llmFallbackToBuiltIn
        )
    }

    // MARK: - Table Detection

    private static let tableDetectionPrompt = """
        Analyze the following OCR text for tabular data. If you find tables:
        - Extract the table structure (headers and rows)
        - Format each table in {format} format
        - Preserve all non-table text in its original position
        - Output the full text with tables replaced by their formatted version
        - If no table is found, return the original text unchanged

        OCR Text:
        {text}
        """

    /// Detect tables in the captured content and format them.
    /// Detect tables in the captured content and format them.
    /// Returns combined text with formatted tables, or nil if no tables were detected.
    /// Tries Vision document recognition first (macOS 26+), then falls back to LLM.
    private func detectAndFormatTables(ocrText: String, capturedImage: CGImage?) async -> String? {
        let format = preferences.tableOutputFormat

        if #available(macOS 26, *),
           let cgImage = capturedImage,
           let visionResult = await detectTablesViaVision(in: cgImage, format: format) {
            return visionResult
        }

        // Fall back to the configured post-processor when Vision is unavailable,
        // fails, or finds no tables. This does not require LLM OCR to be enabled.
        if llmPostProcessor != nil {
            return await detectTablesViaLLM(ocrText: ocrText, format: format)
        }

        return nil
    }

    /// Use Vision's RecognizeDocumentsRequest (macOS 26+) for structural table detection.
    @available(macOS 26, *)
    private func detectTablesViaVision(in cgImage: CGImage, format: TableOutputFormat) async -> String? {
        logger.info("📊 Using Vision RecognizeDocumentsRequest for table detection")
        do {
            let visionEngine = VisionOCREngine()
            guard let result = try await visionEngine.recognizeDocument(in: cgImage),
                  !result.tables.isEmpty else {
                return nil
            }

            let formattedTables = result.tables.map { $0.formatted(as: format) }
                .joined(separator: "\n\n")

            // plainText is already filtered to exclude text inside tables
            // (using bounding region overlap in recognizeDocument).
            // Note: relative ordering between text and tables is not preserved;
            // plain text appears first, followed by all formatted tables.
            var parts: [String] = []
            if !result.plainText.isEmpty {
                parts.append(result.plainText)
            }
            parts.append(formattedTables)
            return parts.joined(separator: "\n\n")
        } catch {
            logger.error("📊 Vision document recognition failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Use LLM with a table detection prompt for pre-macOS 26.
    /// Returns nil if LLM is not configured or if no tables were detected.
    private func detectTablesViaLLM(ocrText: String, format: TableOutputFormat) async -> String? {
        guard let postProcessor = llmPostProcessor else {
            return nil
        }

        logger.info("📊 Using LLM for table detection (Vision unavailable fallback)")
        let processingState = llmProcessingState
        processingState.set(true)
        let prompt = Self.tableDetectionPrompt
            .replacingOccurrences(of: "{format}", with: format.rawValue)
            .replacingOccurrences(of: "{text}", with: ocrText)
        let result = await postProcessor.processSilently(ocrText, prompt: prompt)
        processingState.set(false)

        // Only return if the LLM actually modified the text (i.e. found tables)
        guard result != ocrText else { return nil }
        return result
    }

    public func capture(_ mode: InvocationMode, imagePath: String? = nil) async {
        switch mode {
        case .captureMultiRegion, .captureMultiRegionAndTriggerAutomation:
            await captureMultiRegion(mode)
        default:
            await captureSingle(mode, imagePath: imagePath)
        }
    }

    private func captureSingle(_ mode: InvocationMode, imagePath: String? = nil) async {
        guard beginCaptureTransaction() else { return }
        defer { endCaptureTransaction() }

        currentInvocationMode = mode

        guard let ocrResult = await getText(imagePath) else { return }
        guard var text = await recognizeAndProcessOCR(from: ocrResult) else { return }

        // Apply LLM post-processing if enabled (runs after table detection)
        if preferences.llmEnablePostProcessing, let postProcessor = llmPostProcessor {
            logger.info("📝 Applying LLM post-processing...")
            let processingState = llmProcessingState
            processingState.set(true)
            let metadata = ocrResult.contextDescription()
            text = await postProcessor.processSilently(text, metadata: metadata)
            processingState.set(false)
            logger.info("✅ Post-processing complete")
        }

        processDetectedText(text, ocrResult: ocrResult)
    }

    /// Capture multiple screen regions in a loop, OCR each one, and combine results.
    /// The loop continues until the user cancels (presses Escape) in the screencapture UI,
    /// or the maximum region limit is reached.
    private static let maxMultiRegionCaptures = 50

    private func captureMultiRegion(_ mode: InvocationMode) async {
        var allTexts: [String] = []

        guard beginCaptureTransaction() else { return }
        defer { endCaptureTransaction() }

        currentInvocationMode = mode

        while allTexts.count < Self.maxMultiRegionCaptures {
            guard let nsImage = await captureScreenInteractively() else {
                break // User pressed Escape or capture failed
            }
            guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continue
            }

            if let text = await recognizeAndProcessOCR(cgImage) {
                allTexts.append(text)
            }
        }

        if allTexts.count >= Self.maxMultiRegionCaptures {
            logger.warning("⚠️ Multi-region capture reached maximum of \(Self.maxMultiRegionCaptures, privacy: .public) regions")
        }

        guard !allTexts.isEmpty else { return }
        var combined = allTexts.joined(separator: "\n\n")

        // Apply LLM post-processing once on the combined text
        if preferences.llmEnablePostProcessing, let postProcessor = llmPostProcessor {
            let processingState = llmProcessingState
            processingState.set(true)
            let metadata = "Multi-region capture (\(allTexts.count) regions)"
            combined = await postProcessor.processSilently(combined, metadata: metadata)
            processingState.set(false)
        }

        processDetectedText(combined)
    }

    /// Run OCR on a CGImage and apply table detection if enabled.
    /// Shared helper used by both single capture and multi-region capture paths.
    private func recognizeAndProcessOCR(_ cgImage: CGImage) async -> String? {
        guard let ocrResult = await recognizeImage(cgImage) else { return nil }
        return await recognizeAndProcessOCR(from: ocrResult)
    }

    /// Apply table detection to an existing OCR result if enabled.
    /// Returns the text with tables formatted if detected, or the plain OCR text otherwise.
    private func recognizeAndProcessOCR(from ocrResult: OCRResult) async -> String? {
        var text = ocrResult.text

        if preferences.tableDetectionEnabled {
            logger.info("📊 Table detection enabled, analyzing for tables...")
            if let tableText = await detectAndFormatTables(ocrText: text, capturedImage: ocrResult.sourceImage) {
                text = tableText
                logger.info("✅ Table detection complete, using formatted output")
            } else {
                logger.info("📊 No tables detected, using plain OCR text")
            }
        }

        return text
    }

    /// Launch `screencapture -i` interactively and return the captured image.
    /// Returns nil if the user cancelled (pressed Escape) or if the capture failed.
    private func captureScreenInteractively() async -> NSImage? {
        logger.info("📸 captureScreenInteractively — freezeEnabled=\(self.preferences.freezeScreenDuringSelection, privacy: .public)")
        if preferences.freezeScreenDuringSelection {
            return await FrozenScreenSelectionOverlay.selectRegion()
        }

        let filePath = makeScreenshotFilePath()
        let process = Process()
        process.executableURL = screenCaptureURL
        process.arguments = screenCaptureArguments(outputPath: filePath)
        let logger = self.logger

        return await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                guard FileManager.default.fileExists(atPath: filePath) else {
                    continuation.resume(returning: nil)
                    return
                }

                let image = NSImage(contentsOfFile: filePath)

                // Clean up temp file immediately after loading the image
                do {
                    try FileManager.default.removeItem(atPath: filePath)
                } catch {
                    logger.warning("Failed to clean up temp screenshot file: \(error.localizedDescription, privacy: .public)")
                }

                continuation.resume(returning: image)
            }

            do {
                try process.run()
            } catch {
                logger.error("Screen capture command failed: \(error.localizedDescription, privacy: .public)")
                continuation.resume(returning: nil)
            }
        }
    }

    private func getImage(_ imagePath: String? = nil) async -> NSImage? {
        switch currentInvocationMode {
        case .captureScreen, .captureScreenAndTriggerAutomation:
            return await captureScreenInteractively()
        case .captureClipboard, .captureClipboardAndTriggerAutomation:
            if let url = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil)?.first as? NSURL,
               url.isFileURL, let path = url.path
            {
                return NSImage(contentsOfFile: path)
            }

            if let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                return image
            }

            return nil
        case .captureFromFile, .captureFromFileAndTriggerAutomation:
            guard let imagePath = imagePath, FileManager.default.fileExists(atPath: imagePath) else {
                return nil
            }
            return NSImage(contentsOfFile: imagePath)
        case .captureMultiRegion, .captureMultiRegionAndTriggerAutomation:
            return await captureScreenInteractively()
        }
    }

    private func getText(_ imagePath: String? = nil) async -> OCRResult? {
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("🚀 getText called - starting OCR process")
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        guard let nsImage = await getImage(imagePath) else {
            logger.error("❌ Failed to get image")
            return nil
        }

        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            logger.error("❌ Failed to convert NSImage to CGImage")
            return nil
        }

        return await recognizeImage(cgImage)
    }

    @discardableResult
    func beginCaptureTransaction() -> Bool {
        guard !isCaptureInProgress else {
            logger.warning("⚠️ Capture already in progress, returning early")
            return false
        }

        isCaptureInProgress = true
        return true
    }

    func endCaptureTransaction() {
        isCaptureInProgress = false
    }

    /// Run OCR on a CGImage for watch mode. Delegates to the standard recognition pipeline
    /// and applies table detection if enabled. Does not modify clipboard or trigger automation.
    func recognizeImageForWatchMode(_ cgImage: CGImage) async -> OCRResult? {
        guard let ocrResult = await recognizeImage(cgImage) else { return nil }

        // Apply table detection if enabled, returning a modified result
        if let processedText = await recognizeAndProcessOCR(from: ocrResult), processedText != ocrResult.text {
            return ocrResult.with(text: processedText)
        }

        return ocrResult
    }

    /// Run OCR on a CGImage: QR detection first, then engine selection and text recognition.
    private func recognizeImage(_ cgImage: CGImage) async -> OCRResult? {
        logger.info("📐 Image loaded: \(cgImage.width, privacy: .public)x\(cgImage.height, privacy: .public)")

        // Always check for QR codes first
        let text = parseQR(image: cgImage)
        guard text.isEmpty else {
            logger.info("📱 QR code detected, result length: \(text.count, privacy: .public)")
            if preferences.autoOpenQRCodeURL {
                detectAndOpenURL(text: text)
            }
            return OCRResult(
                text: text,
                confidence: 1.0,
                recognizedLanguages: [],
                engineName: "QR Code Detector",
                recognitionLevel: "exact",
                sourceImage: cgImage
            )
        }

        logger.info("📝 No QR code detected, proceeding with text recognition")
        logger.info("⚙️ Current settings:")
        logger.info("  → Tesseract enabled: \(self.preferences.tesseractEnabled, privacy: .public)")
        logger.info("  → Automatic language detection: \(self.preferences.automaticLanguageDetection, privacy: .public)")
        logger.info("  → Selected language code: \(self.preferences.recognitionLanguageCode, privacy: .public)")
        logger.info("  → macOS version: \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion, privacy: .public)")

        // Use OCRManager to select appropriate engine
        let languages = preferences.tesseractEnabled && !preferences.tesseractLanguages.isEmpty
            ? preferences.tesseractLanguages.map { LanguageCodeMapper.fromTesseract($0) }
            : (preferences.automaticLanguageDetection && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13
                ? [] // Empty array means automatic detection for Vision
                : [LanguageCodeMapper.standardize(preferences.recognitionLanguageCode)])

        if languages.isEmpty {
            logger.info("🌍 Languages array is EMPTY - will use automatic detection")
        } else {
            logger.info("🔤 Languages array: [\(languages.joined(separator: ", "), privacy: .public)]")
        }

        let useTesseract = preferences.tesseractEnabled && !preferences.tesseractLanguages.isEmpty

        // If automatic detection is enabled and we're not using Tesseract, use Vision directly
        if preferences.automaticLanguageDetection && !useTesseract && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13 {
            logger.info("🛤️ OCR Path: Vision with AUTOMATIC language detection")
            return await performVisionOCR(cgImage: cgImage)
        }

        // If LLM OCR is enabled and available, use it
        if preferences.llmEnabled && preferences.llmEnableOCR, let llmEngine = llmEngine {
            logger.info("🛤️ OCR Path: Using LLM OCR engine")
            let processingState = llmProcessingState
            processingState.set(true)
            let result = await performOCR(with: llmEngine, cgImage: cgImage, languages: languages)
            processingState.set(false)
            return result
        }

        // If Tesseract is disabled, only use Vision
        if !useTesseract {
            logger.info("🛤️ OCR Path: Using Apple Vision (Tesseract disabled)")
            if let visionEngine = OCRManager.shared.engines.first(where: { $0.identifier == "vision" }) {
                return await performOCR(with: visionEngine, cgImage: cgImage, languages: languages)
            } else {
                logger.warning("⚠️ Vision engine not found, falling back to legacy path")
                return await performVisionOCR(cgImage: cgImage)
            }
        }

        if let engine = OCRManager.shared.findEngine(for: languages) {
            logger.info("🛤️ OCR Path: Using \(engine.name, privacy: .public) engine with explicit languages")
            return await performOCR(with: engine, cgImage: cgImage, languages: languages)
        } else {
            logger.warning("🛤️ OCR Path: No suitable OCR engine found for languages, falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        }
    }
    
    
    private func performOCR(with engine: OCREngine, cgImage: CGImage, languages: [String]) async -> OCRResult? {
        logger.info("🔧 performOCR called with engine: \(engine.name, privacy: .public)")
        do {
            // Use timeout utility for 5 second timeout
            var result = try await withTimeout(seconds: 5.0) {
                try await engine.recognizeText(
                    in: cgImage,
                    languages: languages,
                    recognitionLevel: .accurate
                )
            }

            logger.info("✅ \(engine.name, privacy: .public) OCR successful!")
            logger.info("  → Result length: \(result.text.count, privacy: .public) characters")
            logger.info("  → Confidence: \(String(format: "%.2f", result.confidence), privacy: .public)")
            logger.info("  → Recognized languages: \(result.recognizedLanguages.joined(separator: ", "), privacy: .public)")

            // Attach source image for downstream processing (e.g. table detection)
            result = result.with(sourceImage: cgImage)

            // Handle URL opening if needed
            if preferences.autoOpenCapturedURL {
                detectAndOpenURL(text: result.text)
            }

            return result
        } catch TimeoutError.timedOut {
            logger.error("⏱️ OCR timed out after 5 seconds, falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        } catch {
            logger.error("❌ \(engine.name, privacy: .public) failed with error: \(error.localizedDescription, privacy: .public)")
            logger.error("  → Falling back to Vision")
            return await performVisionOCR(cgImage: cgImage)
        }
    }

    private func performVisionOCR(cgImage: CGImage) async -> OCRResult? {
        logger.info("🔧 performVisionOCR called")
        let automaticallyDetectsLanguage = preferences.automaticLanguageDetection
        let languages = automaticallyDetectsLanguage
            ? []
            : [LanguageCodeMapper.standardize(preferences.recognitionLanguageCode)]

        do {
            var result = try await VisionOCREngine().recognizeText(
                in: cgImage,
                languages: languages,
                recognitionLevel: .accurate,
                customWords: preferences.customWordsList,
                automaticallyDetectsLanguage: automaticallyDetectsLanguage
            )
            if preferences.ignoreLineBreaks {
                result = result.with(text: result.text.replacingOccurrences(of: "\n", with: " "))
            }
            guard !result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logger.info("Vision OCR found no text")
                return nil
            }
            result = result.with(sourceImage: cgImage)
            if preferences.autoOpenCapturedURL {
                detectAndOpenURL(text: result.text)
            }
            return result
        } catch {
            logger.error("Vision OCR failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    @MainActor
    func processDetectedText(_ text: String, ocrResult: OCRResult? = nil) {
        showNotification(text: text)

        // Save to capture history (GUI only)
        if preferences.captureHistoryEnabled, !BundleIdentifiers.isCLI {
            captureHistoryStore.addEntry(
                text: text,
                ocrResult: ocrResult,
                maxEntries: preferences.captureHistoryMaxEntries
            )
        }

        // Choose between automation and clipboard
        guard Self.shouldRouteToAutomation(
            mode: currentInvocationMode,
            autoOpenProvidedURL: preferences.autoOpenProvidedURL,
            autoRunShortcut: preferences.autoRunShortcut
        ) else {
            let pasteBoard = NSPasteboard.general
            pasteBoard.clearContents()
            pasteBoard.setString(text, forType: .string)
            // output to STDOUT for CLI
            if BundleIdentifiers.isCLI {
                print(text)
            }
            return
        }

        if #available(macOS 12, *) {
            // run shortcuts
            ShortcutsManager.shared.runShortcut(inputText: text)
        }
        var text = text

        if preferences.autoOpenProvidedURLAddNewLine {
            text.append("\n")
        }
        if case let urlStr = preferences.autoOpenProvidedURL.replacingOccurrences(of: "{text}", with: text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""),
           let url = URL(string: urlStr)
        {
            NSWorkspace.shared.open(url)
        }

        return
    }

    static func detectedURLs(in text: String) -> [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.utf16.count)
        ) ?? []

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text),
                  case let urlStr = String(text[range]),
                  let url = URL(string: urlStr)
            else { return nil }
            if url.scheme == nil,
               case let urlStr = "https://\(url.absoluteString)",
               let newUrl = URL(string: urlStr)
            {
                return newUrl
            }
            return url
        }
    }

    private func detectAndOpenURL(text: String) {
        Self.detectedURLs(in: text).forEach { url in
            NSWorkspace.shared.open(url)
        }
    }

    func parseQR(image: CGImage) -> String {
        let image = CIImage(cgImage: image)

        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

        let features = detector?.features(in: image) ?? []

        return features.compactMap { feature in
            (feature as? CIQRCodeFeature)?.messageString
        }.joined(separator: " ")
    }

}

// MARK: Notifications

extension TRex {
    class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
        nonisolated(unsafe) static let shared = NotificationDelegate()
        
        override init() {
            super.init()
            UNUserNotificationCenter.current().delegate = self
        }
        
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            completionHandler([.banner, .sound])
        }
    }
    
    public func showNotification(text: String) {
        guard preferences.resultNotification else { return }
        guard !BundleIdentifiers.isCLI else { return }
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Set delegate to handle foreground notifications
        notificationCenter.delegate = NotificationDelegate.shared
        
        // Request authorization if not already granted
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "TRex"
            content.subtitle = "Captured text"
            content.body = text
            content.sound = .default
            
            let uuidString = UUID().uuidString
            // Using immediate trigger instead of nil
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: uuidString,
                                                content: content,
                                                trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    self.logger.error("Failed to show notification: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
}
