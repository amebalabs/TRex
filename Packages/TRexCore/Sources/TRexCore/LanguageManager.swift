import Foundation
import TesseractSwift

/// Language management for OCR engines
public class LanguageManager {
    public static let shared = LanguageManager()
    
    private let tesseractEngine: TesseractOCREngine
    
    private init() {
        self.tesseractEngine = TesseractOCREngine()
    }
    
    /// Represents a language available for OCR
    public struct Language {
        public let code: String
        public let displayName: String
        public let source: OCRSource
        public let isDownloaded: Bool
        public let fileSize: Int? // in bytes
        
        public enum OCRSource {
            case vision
            case tesseract
            case both
        }
    }
    
    /// Get all available languages
    public func availableLanguages() -> [Language] {
        var languages: [Language] = []
        var addedCodes = Set<String>()
        
        // Vision Framework languages (hardcoded as they don't change often)
        let visionLanguages = [
            ("en-US", "English"),
            ("fr-FR", "French"),
            ("de-DE", "German"),
            ("es-ES", "Spanish"),
            ("it-IT", "Italian"),
            ("pt-BR", "Portuguese (Brazil)"),
            ("zh-Hans", "Chinese (Simplified)"),
            ("zh-Hant", "Chinese (Traditional)"),
            ("ja-JP", "Japanese"),
            ("ko-KR", "Korean"),
            ("ru-RU", "Russian"),
            ("uk-UA", "Ukrainian"),
            ("th-TH", "Thai"),
            ("vi-VN", "Vietnamese")
        ]
        
        // Get downloaded Tesseract languages
        let downloadedTesseractLanguages = Set(tesseractEngine.availableLanguages())
        
        // Add Vision languages
        for (code, name) in visionLanguages {
            let tesseractCode = LanguageCodeMapper.toTesseract(code)
            let isDownloaded = downloadedTesseractLanguages.contains(tesseractCode)
            
            languages.append(Language(
                code: code,
                displayName: name,
                source: isDownloaded ? .both : .vision,
                isDownloaded: true, // Vision languages are always available
                fileSize: nil
            ))
            addedCodes.insert(tesseractCode)
        }
        
        // Add all available Tesseract languages
        for langInfo in LanguageDownloader.allAvailableLanguages() {
            if !addedCodes.contains(langInfo.code) {
                let standardCode = LanguageCodeMapper.fromTesseract(langInfo.code)
                let isDownloaded = downloadedTesseractLanguages.contains(langInfo.code)
                
                languages.append(Language(
                    code: standardCode,
                    displayName: langInfo.name,
                    source: .tesseract,
                    isDownloaded: isDownloaded,
                    fileSize: langInfo.fileSize
                ))
            }
        }
        
        return languages.sorted { $0.displayName < $1.displayName }
    }
    
    /// Download a language for Tesseract
    public func downloadLanguage(_ code: String, progress: ((Double) -> Void)? = nil) async throws {
        try await tesseractEngine.downloadLanguage(code, progress: progress)
    }
    
    /// Delete a downloaded language
    public func deleteLanguage(_ code: String) throws {
        try tesseractEngine.deleteLanguage(code)
    }
    
    /// Check if a language is supported by any engine
    public func isLanguageSupported(_ code: String) -> Bool {
        // Check Vision first
        let visionEngine = OCRManager.shared.findEngine(for: [code])
        if visionEngine != nil {
            return true
        }
        
        // Check Tesseract
        return tesseractEngine.supportsLanguage(code)
    }
    
    /// Get the best OCR engine for a language
    public func preferredEngine(for languageCode: String) -> OCREngine? {
        return OCRManager.shared.findEngine(for: [languageCode])
    }
    
    /// Get storage info for downloaded languages
    public func storageInfo() -> (usedSpace: Int64, languageCount: Int) {
        let languages = tesseractEngine.availableLanguages()
        let usedSpace = calculateUsedSpace()
        return (usedSpace, languages.count)
    }
    
    private func calculateUsedSpace() -> Int64 {
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                     in: .userDomainMask).first!
        let tessdataPath = appSupportPath.appendingPathComponent("TRex/tessdata")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tessdataPath, 
                                                                   includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0
            
            for file in files where file.pathExtension == "traineddata" {
                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
}