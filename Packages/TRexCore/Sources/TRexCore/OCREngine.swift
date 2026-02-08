import Foundation
import OSLog
import Vision
import CoreImage

// Protocol for OCR engines
public protocol OCREngine: Sendable {
    var name: String { get }
    var identifier: String { get }
    var priority: Int { get }

    func supportsLanguage(_ language: String) -> Bool
    func recognizeText(in image: CGImage, languages: [String], recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult
    func recognizeText(in image: CGImage, recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult
}

// Result type for OCR operations
public struct OCRResult: Sendable {
    public let text: String
    public let confidence: Float
    public let recognizedLanguages: [String]
    public let engineName: String?
    public let recognitionLevel: String?
    /// The source image used for OCR, retained for downstream processing (e.g. table detection).
    public let sourceImage: CGImage?

    public init(
        text: String,
        confidence: Float,
        recognizedLanguages: [String],
        engineName: String? = nil,
        recognitionLevel: String? = nil,
        sourceImage: CGImage? = nil
    ) {
        self.text = text
        self.confidence = confidence
        self.recognizedLanguages = recognizedLanguages
        self.engineName = engineName
        self.recognitionLevel = recognitionLevel
        self.sourceImage = sourceImage
    }

    /// Return a copy with the text replaced, preserving all other fields.
    public func with(text: String) -> OCRResult {
        OCRResult(
            text: text,
            confidence: confidence,
            recognizedLanguages: recognizedLanguages,
            engineName: engineName,
            recognitionLevel: recognitionLevel,
            sourceImage: sourceImage
        )
    }

    /// Return a copy with the source image replaced, preserving all other fields.
    public func with(sourceImage: CGImage?) -> OCRResult {
        OCRResult(
            text: text,
            confidence: confidence,
            recognizedLanguages: recognizedLanguages,
            engineName: engineName,
            recognitionLevel: recognitionLevel,
            sourceImage: sourceImage
        )
    }

    /// Create a contextualized description of this OCR result for LLM processing
    public func contextDescription() -> String {
        var parts: [String] = []

        if let engine = engineName {
            parts.append("OCR Engine: \(engine)")
        }

        if confidence > 0 {
            let confidencePercent = Int(confidence * 100)
            parts.append("Confidence: \(confidencePercent)%")
        }

        if !recognizedLanguages.isEmpty {
            parts.append("Language(s): \(recognizedLanguages.joined(separator: ", "))")
        }

        if let level = recognitionLevel {
            parts.append("Recognition Level: \(level)")
        }

        return parts.isEmpty ? "No OCR metadata available" : parts.joined(separator: ", ")
    }
}

// Manager to handle multiple OCR engines
public final class OCRManager: Sendable {
    public static let shared = OCRManager()

    private let _engines: OSAllocatedUnfairLock<[OCREngine]>

    public var engines: [OCREngine] {
        _engines.withLock { $0 }
    }

    private init() {
        _engines = OSAllocatedUnfairLock(initialState: [])

        // Register engines
        registerEngine(VisionOCREngine())

        // Register Tesseract engine (always available with TesseractSwift)
        registerEngine(TesseractOCREngine())
    }

    public func registerEngine(_ engine: OCREngine) {
        _engines.withLock { engines in
            engines.append(engine)
            engines.sort { $0.priority > $1.priority }
        }
    }

    public func findEngine(for languages: [String]) -> OCREngine? {
        _engines.withLock { engines in
            // Find the first engine that supports all requested languages
            for engine in engines {
                let supportsAll = languages.allSatisfy { engine.supportsLanguage($0) }
                if supportsAll {
                    return engine
                }
            }
            return nil
        }
    }

    public func defaultEngine() -> OCREngine? {
        _engines.withLock { $0.first }
    }
}

// Apple Vision framework OCR engine
public final class VisionOCREngine: OCREngine {
    public var name: String { "Apple Vision" }
    public var identifier: String { "vision" }
    public var priority: Int { 50 } // Lower priority than Tesseract
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ameba.TRex", category: "VisionOCREngine")
    private static let cachedSupportedLanguages: Set<String> = {
        return fetchSupportedLanguages()
    }()
    private let supportedLanguages: Set<String>

    public init() {
        self.supportedLanguages = Self.cachedSupportedLanguages
    }

    // Dynamically fetch supported languages from Vision framework
    private static func fetchSupportedLanguages() -> Set<String> {
        // Fallback for older macOS versions that don't support the API
        guard #available(macOS 10.15, *) else {
            // Return hardcoded set for older OS versions
            return Set([
                "en-US", "fr-FR", "de-DE", "es-ES", "it-IT",
                "pt-BR", "zh-Hans", "zh-Hant", "ja-JP", "ko-KR",
                "ru-RU", "uk-UA", "th-TH", "vi-VN", "tr-TR"
            ])
        }

        do {
            let request = VNRecognizeTextRequest()
            let languages = try request.supportedRecognitionLanguages()
            
            // Map Vision language codes to standard format
            var standardLanguages = Set<String>()
            for language in languages {
                // Vision returns codes like "en-US", "zh-Hans", etc.
                // Map duplicates to a single standard code
                let standardCode = mapVisionLanguageCode(language)
                standardLanguages.insert(standardCode)
            }
            
            return standardLanguages
        } catch {
            logger.error("Failed to fetch Vision supported languages: \(error.localizedDescription, privacy: .public)")
            // Fallback to known set if query fails
            return Set([
                "en-US", "fr-FR", "de-DE", "es-ES", "it-IT",
                "pt-BR", "zh-Hans", "zh-Hant", "ja-JP", "ko-KR",
                "ru-RU", "uk-UA", "th-TH", "vi-VN", "tr-TR"
            ])
        }
    }
    
    // Map Vision language codes to our standard format
    private static func mapVisionLanguageCode(_ visionCode: String) -> String {
        // Most codes are already in the right format
        // Special cases:
        switch visionCode {
        case "vi-VT": return "vi-VN"  // Vietnamese
        case "ars-SA": return "ar-SA"  // Arabic (secondary variant maps to primary)
        default: return visionCode
        }
    }
    
    public func supportsLanguage(_ language: String) -> Bool {
        return supportedLanguages.contains(language)
    }
    
    // Get all supported languages (for external use)
    public func availableLanguages() -> [String] {
        return Array(supportedLanguages).sorted()
    }
    
    public func recognizeText(in image: CGImage, languages: [String], recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        Self.logger.info("🔍 VisionOCREngine.recognizeText called")
        Self.logger.info("  → Languages: \(languages.joined(separator: ", "), privacy: .public)")
        let levelString = recognitionLevel == .accurate ? "accurate" : "fast"
        Self.logger.info("  → Recognition level: \(levelString, privacy: .public)")
        Self.logger.info("  → Image size: \(image.width, privacy: .public)x\(image.height, privacy: .public)")

        // Enhance image contrast for better recognition
        let enhancedImage = enhanceImageContrast(image)
        Self.logger.debug("🎨 Image contrast enhanced")

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    Self.logger.error("❌ Vision request failed: \(error.localizedDescription, privacy: .public)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    Self.logger.warning("⚠️ No observations returned from Vision")
                    continuation.resume(returning: OCRResult(
                        text: "",
                        confidence: 0,
                        recognizedLanguages: languages,
                        engineName: "Apple Vision",
                        recognitionLevel: levelString
                    ))
                    return
                }

                Self.logger.info("📊 Vision returned \(observations.count, privacy: .public) text observations")

                var text = ""
                var totalConfidence: Float = 0
                var count = 0

                for (index, observation) in observations.enumerated() {
                    let candidates = observation.topCandidates(3)
                    if let topCandidate = candidates.first {
                        if !text.isEmpty {
                            text.append("\n")
                        }
                        text.append(topCandidate.string)
                        totalConfidence += topCandidate.confidence
                        count += 1

                        // Log first 5 observations with their top candidates
                        if index < 5 {
                            Self.logger.debug("  Line \(index, privacy: .public): '\(topCandidate.string, privacy: .public)' (confidence: \(String(format: "%.2f", topCandidate.confidence), privacy: .public))")
                            if candidates.count > 1 {
                                let alternates = candidates.dropFirst().map { "'\($0.string)' (\(String(format: "%.2f", $0.confidence)))" }.joined(separator: ", ")
                                Self.logger.debug("    Alternates: \(alternates, privacy: .public)")
                            }
                        }
                    }
                }

                let avgConfidence = count > 0 ? totalConfidence / Float(count) : 0
                Self.logger.info("✅ Recognition complete: \(count, privacy: .public) lines, avg confidence: \(String(format: "%.2f", avgConfidence), privacy: .public)")
                Self.logger.info("  → Total text length: \(text.count, privacy: .public) characters")

                continuation.resume(returning: OCRResult(
                    text: text,
                    confidence: avgConfidence,
                    recognizedLanguages: languages,
                    engineName: "Apple Vision",
                    recognitionLevel: levelString
                ))
            }

            request.recognitionLanguages = languages
            request.recognitionLevel = recognitionLevel
            request.usesLanguageCorrection = true

            // Improve recognition of individual characters and symbols
            if #available(macOS 13.0, *) {
                request.minimumTextHeight = 0.0  // Recognize even small text
            }

            Self.logger.debug("🔧 Vision request configured:")
            Self.logger.debug("  → recognitionLanguages: \(request.recognitionLanguages.joined(separator: ", "), privacy: .public)")
            Self.logger.debug("  → usesLanguageCorrection: \(request.usesLanguageCorrection, privacy: .public)")
            Self.logger.debug("  → minimumTextHeight: 0.0 (recognize small text)")

            let handler = VNImageRequestHandler(cgImage: enhancedImage, orientation: .up)

            do {
                try handler.perform([request])
            } catch {
                Self.logger.error("❌ Vision handler.perform failed: \(error.localizedDescription, privacy: .public)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func recognizeText(in image: CGImage, recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        return try await recognizeText(in: image, languages: ["en-US"], recognitionLevel: recognitionLevel)
    }

    // MARK: - Document Recognition (macOS 26+)

    @available(macOS 26, *)
    public func recognizeDocument(in image: CGImage) async throws -> DocumentResult? {
        Self.logger.info("📄 VisionOCREngine.recognizeDocument called")
        Self.logger.info("  → Image size: \(image.width, privacy: .public)x\(image.height, privacy: .public)")

        let request = RecognizeDocumentsRequest()
        let observations = try await request.perform(on: image)

        var tables: [DetectedTable] = []
        var plainTextParts: [String] = []

        for observation in observations {
            let doc = observation.document

            // Collect table bounding boxes to filter overlapping paragraphs
            var tableBoundingBoxes: [NormalizedRect] = []
            for table in doc.tables {
                let detectedTable = extractTable(from: table)
                // Skip empty tables (no rows at all)
                guard detectedTable.headers != nil || !detectedTable.rows.isEmpty else { continue }
                tables.append(detectedTable)
                if let bbox = boundingBox(for: table) {
                    tableBoundingBoxes.append(bbox)
                }
            }

            // Extract plain text only from paragraphs that don't overlap with tables
            for paragraph in doc.paragraphs {
                guard let paraBBox = boundingBox(for: paragraph) else { continue }
                let overlapsTable = tableBoundingBoxes.contains { tableBBox in
                    bboxOverlaps(paraBBox, tableBBox)
                }
                if !overlapsTable {
                    plainTextParts.append(paragraph.transcript)
                }
            }
        }

        let plainText = plainTextParts.joined(separator: "\n")
        Self.logger.info("📄 Document recognition complete: \(tables.count, privacy: .public) tables, \(plainText.count, privacy: .public) chars plain text")

        return DocumentResult(tables: tables, plainText: plainText)
    }

    /// Compute a NormalizedRect enclosing all the given bounding boxes.
    /// Returns nil if the array is empty (no geometry available).
    /// All coordinates are in Vision's normalized coordinate space.
    @available(macOS 26, *)
    private func enclosingRect(of boxes: [NormalizedRect]) -> NormalizedRect? {
        guard !boxes.isEmpty else { return nil }
        var minX: Double = .greatestFiniteMagnitude
        var minY: Double = .greatestFiniteMagnitude
        var maxX: Double = -.greatestFiniteMagnitude
        var maxY: Double = -.greatestFiniteMagnitude
        for box in boxes {
            minX = min(minX, box.origin.x)
            minY = min(minY, box.origin.y)
            maxX = max(maxX, box.origin.x + box.width)
            maxY = max(maxY, box.origin.y + box.height)
        }
        return NormalizedRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    @available(macOS 26, *)
    private func boundingBox(for table: DocumentObservation.Container.Table) -> NormalizedRect? {
        let lineBoxes = table.rows.flatMap { row in
            row.flatMap { cell in cell.content.text.lines.map(\.boundingBox) }
        }
        return enclosingRect(of: lineBoxes)
    }

    @available(macOS 26, *)
    private func boundingBox(for paragraph: DocumentObservation.Container.Text) -> NormalizedRect? {
        return enclosingRect(of: paragraph.lines.map(\.boundingBox))
    }

    /// Check if two normalized rects overlap
    @available(macOS 26, *)
    private func bboxOverlaps(_ a: NormalizedRect, _ b: NormalizedRect) -> Bool {
        let aMaxX = a.origin.x + a.width
        let aMaxY = a.origin.y + a.height
        let bMaxX = b.origin.x + b.width
        let bMaxY = b.origin.y + b.height
        return a.origin.x < bMaxX && aMaxX > b.origin.x &&
               a.origin.y < bMaxY && aMaxY > b.origin.y
    }

    @available(macOS 26, *)
    private func extractTable(from table: DocumentObservation.Container.Table) -> DetectedTable {
        // Use rows property which gives [[Table.Cell]]
        var allRows: [[String]] = []
        for row in table.rows {
            let rowCells = row.map { $0.content.text.transcript }
            allRows.append(rowCells)
        }

        // Treat the first row as headers (heuristic: no explicit header API)
        let headers: [String]?
        let dataRows: [[String]]
        if allRows.count > 1 {
            headers = allRows.first
            dataRows = Array(allRows.dropFirst())
        } else {
            headers = nil
            dataRows = allRows
        }

        return DetectedTable(headers: headers, rows: dataRows)
    }

    // MARK: - Image Enhancement

    private func enhanceImageContrast(_ image: CGImage) -> CGImage {
        let ciImage = CIImage(cgImage: image)

        // Apply contrast and brightness adjustments
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.3, forKey: kCIInputContrastKey)        // Increase contrast by 30%
        filter?.setValue(0.1, forKey: kCIInputBrightnessKey)      // Slightly increase brightness
        filter?.setValue(1.1, forKey: kCIInputSaturationKey)      // Slightly increase saturation

        guard let outputImage = filter?.outputImage else {
            Self.logger.warning("⚠️ Filter failed, using original")
            return image
        }

        // Convert back to CGImage
        let context = CIContext(options: nil)
        guard let enhancedCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            Self.logger.warning("⚠️ Failed to create enhanced CGImage, using original")
            return image
        }

        return enhancedCGImage
    }
}
