import Foundation
import Cocoa
import Vision
import TesseractSwift

public class TesseractOCREngine: OCREngine {
    private let tessdataPath: URL
    private let tesseractEngine: TesseractEngine
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
        self.tesseractEngine = TesseractEngine(dataPath: tessdataPath.path)
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
        // Convert language code to Tesseract format
        let tesseractLang = LanguageCodeMapper.toTesseract(language)
        
        // Check if the language file exists
        let languageFile = tessdataPath.appendingPathComponent("\(tesseractLang).traineddata")
        return FileManager.default.fileExists(atPath: languageFile.path)
    }
    
    public func recognizeText(in image: CGImage, languages: [String], recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        // Languages should be in standard format (e.g., "en-US"), convert to Tesseract format
        let tesseractLangs = languages.map { LanguageCodeMapper.toTesseract($0) }
        let primaryLang = tesseractLangs.first ?? "eng"
        
        // Ensure the language is downloaded
        if !supportsLanguage(languages.first ?? "en-US") {
            // Try to download the language
            if let langInfo = LanguageDownloader.allAvailableLanguages().first(where: { $0.code == primaryLang }) {
                try await languageDownloader.downloadLanguage(langInfo, to: tessdataPath)
            } else {
                throw OCRError.initializationFailed("Language not available: \(primaryLang)")
            }
        }
        
        // Initialize Tesseract with the language
        try tesseractEngine.initialize(language: primaryLang)
        
        // Set page segmentation mode based on recognition level
        if recognitionLevel == .accurate {
            tesseractEngine.setPageSegmentationMode(.auto)
        } else {
            tesseractEngine.setPageSegmentationMode(.sparseText)
        }
        
        // Perform OCR
        let text = try tesseractEngine.recognize(cgImage: image)
        let confidence = Float(tesseractEngine.confidence()) / 100.0
        
        // Clear for memory efficiency
        tesseractEngine.clear()
        
        // Return result
        return OCRResult(
            text: text,
            confidence: confidence,
            recognizedLanguages: languages
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
