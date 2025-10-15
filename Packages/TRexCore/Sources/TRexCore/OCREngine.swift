import Foundation
import OSLog
import Vision

// Protocol for OCR engines
public protocol OCREngine {
    var name: String { get }
    var identifier: String { get }
    var priority: Int { get }
    
    func supportsLanguage(_ language: String) -> Bool
    func recognizeText(in image: CGImage, languages: [String], recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult
    func recognizeText(in image: CGImage, recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult
}

// Result type for OCR operations
public struct OCRResult {
    public let text: String
    public let confidence: Float
    public let recognizedLanguages: [String]
    
    public init(text: String, confidence: Float, recognizedLanguages: [String]) {
        self.text = text
        self.confidence = confidence
        self.recognizedLanguages = recognizedLanguages
    }
}

// Manager to handle multiple OCR engines
public class OCRManager {
    public static let shared = OCRManager()
    
    private var engines: [OCREngine] = []
    
    private init() {
        // Register engines
        registerEngine(VisionOCREngine())
        
        // Register Tesseract engine (always available with TesseractSwift)
        registerEngine(TesseractOCREngine())
    }
    
    public func registerEngine(_ engine: OCREngine) {
        engines.append(engine)
        engines.sort { $0.priority > $1.priority }
    }
    
    public func findEngine(for languages: [String]) -> OCREngine? {
        // Find the first engine that supports all requested languages
        for engine in engines {
            let supportsAll = languages.allSatisfy { engine.supportsLanguage($0) }
            if supportsAll {
                return engine
            }
        }
        return nil
    }
    
    public func defaultEngine() -> OCREngine? {
        return engines.first
    }
}

// Apple Vision framework OCR engine
public class VisionOCREngine: OCREngine {
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
                "ru-RU", "uk-UA", "th-TH", "vi-VN"
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
                "ru-RU", "uk-UA", "th-TH", "vi-VN"
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
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(text: "", confidence: 0, recognizedLanguages: languages))
                    return
                }
                
                var text = ""
                var totalConfidence: Float = 0
                var count = 0
                
                for observation in observations {
                    if let candidate = observation.topCandidates(1).first {
                        if !text.isEmpty {
                            text.append("\n")
                        }
                        text.append(candidate.string)
                        totalConfidence += candidate.confidence
                        count += 1
                    }
                }
                
                let avgConfidence = count > 0 ? totalConfidence / Float(count) : 0
                continuation.resume(returning: OCRResult(
                    text: text,
                    confidence: avgConfidence,
                    recognizedLanguages: languages
                ))
            }
            
            request.recognitionLanguages = languages
            request.recognitionLevel = recognitionLevel
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func recognizeText(in image: CGImage, recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        return try await recognizeText(in: image, languages: ["en-US"], recognitionLevel: recognitionLevel)
    }
}
