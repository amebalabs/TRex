import Foundation
import Cocoa
import Vision
@preconcurrency import TesseractSwift

public final class TesseractOCREngine: @unchecked Sendable, OCREngine {
    private let tessdataPath: URL
    private let engineCoordinator: TesseractEngineCoordinator
    private let languageDownloader = LanguageDownloader.shared
    
    public init() {
        // Always use Library/Application Support for tessdata
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                     in: .userDomainMask).first!
        let trexPath = appSupportPath.appendingPathComponent("TRex")
        self.tessdataPath = trexPath.appendingPathComponent("tessdata")
        
        // Ensure tessdata directory exists
        try? FileManager.default.createDirectory(at: tessdataPath, withIntermediateDirectories: true)
        
        // Initialize Tesseract engine
        self.engineCoordinator = TesseractEngineCoordinator(dataPath: tessdataPath.path)
    }
    
    public var name: String { "Tesseract OCR" }
    
    public var identifier: String { "tesseract" }
    
    public var priority: Int { 100 }
    
    public var isAvailable: Bool {
        // TesseractSwift is always available as a direct dependency
        return true
    }
    
    public func availableLanguages() -> [String] {
        // Get list of downloaded languages
        return languageDownloader.downloadedLanguages(in: tessdataPath)
    }
    
    public func supportsLanguage(_ language: String) -> Bool {
        let tesseractLang = LanguageCodeMapper.toTesseract(language)
        if FileManager.default.fileExists(atPath: languageFileURL(forTesseractCode: tesseractLang).path) {
            return true
        }
        return LanguageDownloader.allAvailableLanguages().contains(where: { $0.code == tesseractLang })
    }
    
    public func recognizeText(in image: CGImage, languages: [String], recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        // Convert requested languages to Tesseract codes. Default to English if none provided.
        let requestedLanguages = languages.isEmpty ? ["en-US"] : languages
        let tesseractCodes = requestedLanguages.map { LanguageCodeMapper.toTesseract($0) }

        // Ensure every language is available locally, download if needed.
        for code in Set(tesseractCodes) {
            if !FileManager.default.fileExists(atPath: languageFileURL(forTesseractCode: code).path) {
                guard let langInfo = LanguageDownloader.allAvailableLanguages().first(where: { $0.code == code }) else {
                    throw OCRError.initializationFailed("Language not available: \(code)")
                }
                try await languageDownloader.downloadLanguage(langInfo, to: tessdataPath)
            }
        }

        let recognition = try await engineCoordinator.recognize(
            image: image,
            language: tesseractCodes.joined(separator: "+"),
            recognitionLevel: recognitionLevel
        )

        return OCRResult(
            text: recognition.text,
            confidence: recognition.confidence,
            recognizedLanguages: requestedLanguages,
            engineName: "Tesseract",
            recognitionLevel: recognitionLevel == .accurate ? "accurate" : "fast"
        )
    }
    
    public func recognizeText(in image: CGImage, recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        // Default to English if no languages specified
        return try await recognizeText(in: image, languages: ["en-US"], recognitionLevel: recognitionLevel)
    }
    
    // MARK: - Language Management
    
    public func downloadLanguage(_ code: String, progress: ((Double) -> Void)? = nil) async throws {
        let tesseractCode = LanguageCodeMapper.toTesseract(code)
        
        guard let language = LanguageDownloader.allAvailableLanguages().first(where: { $0.code == tesseractCode }) else {
            throw OCRError.initializationFailed("Language not supported: \(code)")
        }
        
        try await languageDownloader.downloadLanguage(language, to: tessdataPath, progress: progress)
    }
    
    public func deleteLanguage(_ code: String) throws {
        let tesseractCode = LanguageCodeMapper.toTesseract(code)
        
        guard let language = LanguageDownloader.allAvailableLanguages().first(where: { $0.code == tesseractCode }) else {
            throw OCRError.initializationFailed("Language not supported: \(code)")
        }
        
        try languageDownloader.deleteLanguage(language, from: tessdataPath)
    }
    
    public func supportedLanguages() -> [(code: String, name: String)] {
        return LanguageDownloader.allAvailableLanguages().map { 
            (code: $0.code, name: $0.name)
        }
    }
}

protocol TesseractEngineAdapter: AnyObject {
    func initialize(language: String) throws
    func recognize(image: CGImage, recognitionLevel: VNRequestTextRecognitionLevel) throws -> (text: String, confidence: Float)
    func clear()
}

private final class NativeTesseractEngineAdapter: TesseractEngineAdapter {
    private let engine: TesseractEngine

    init(dataPath: String) {
        engine = TesseractEngine(dataPath: dataPath)
    }

    func initialize(language: String) throws {
        try engine.initialize(language: language)
    }

    func recognize(
        image: CGImage,
        recognitionLevel: VNRequestTextRecognitionLevel
    ) throws -> (text: String, confidence: Float) {
        engine.setPageSegmentationMode(recognitionLevel == .accurate ? .auto : .sparseText)
        let text = try engine.recognize(cgImage: image)
        return (text, Float(engine.confidence()) / 100)
    }

    func clear() {
        engine.clear()
    }
}

actor TesseractEngineCoordinator {
    private let engine: any TesseractEngineAdapter

    init(dataPath: String) {
        engine = NativeTesseractEngineAdapter(dataPath: dataPath)
    }

    init(engine: any TesseractEngineAdapter) {
        self.engine = engine
    }

    func recognize(
        image: CGImage,
        language: String,
        recognitionLevel: VNRequestTextRecognitionLevel
    ) throws -> (text: String, confidence: Float) {
        // Actor queuing suspends waiters instead of blocking threads on NSLock.
        // Cancelled requests are discarded before they can touch native state.
        try Task.checkCancellation()
        try engine.initialize(language: language)
        defer { engine.clear() }

        try Task.checkCancellation()
        return try engine.recognize(image: image, recognitionLevel: recognitionLevel)
    }
}

private extension TesseractOCREngine {
    func languageFileURL(forTesseractCode code: String) -> URL {
        tessdataPath.appendingPathComponent("\(code).traineddata")
    }
}

// OCR Error types
enum OCRError: LocalizedError {
    case initializationFailed(String)
    case imageProcessingFailed(String)
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Tesseract initialization failed: \(message)"
        case .imageProcessingFailed(let message):
            return "Image processing failed: \(message)"
        case .recognitionFailed(let message):
            return "Text recognition failed: \(message)"
        }
    }
}
