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
        public let flagEmoji: String?
        public let source: OCRSource
        public let isDownloaded: Bool
        public let fileSize: Int? // in bytes
        
        public enum OCRSource {
            case vision
            case tesseract
            case both
        }
        
        /// Display name with flag emoji if available
        public var displayNameWithFlag: String {
            if let flag = flagEmoji {
                return "\(flag) \(displayName)"
            }
            return displayName
        }
    }
    
    /// Get all available languages
    public func availableLanguages() -> [Language] {
        var languages: [Language] = []
        var addedCodes = Set<String>()
        
        // Get Vision Framework languages dynamically
        let visionEngine = VisionOCREngine()
        let visionLanguageCodes = visionEngine.availableLanguages()
        
        // Language display names mapping
        let languageDisplayNames: [String: String] = [
            "en-US": "English",
            "fr-FR": "French", 
            "de-DE": "German",
            "es-ES": "Spanish",
            "it-IT": "Italian",
            "pt-BR": "Portuguese (Brazil)",
            "zh-Hans": "Chinese (Simplified)",
            "zh-Hant": "Chinese (Traditional)",
            "ja-JP": "Japanese",
            "ko-KR": "Korean",
            "ru-RU": "Russian",
            "uk-UA": "Ukrainian",
            "th-TH": "Thai",
            "vi-VN": "Vietnamese",
            "ar-SA": "Arabic",
            "yue-Hans": "Cantonese (Simplified)",
            "yue-Hant": "Cantonese (Traditional)"
        ]
        
        // Flag emoji mapping for languages
        let languageFlags: [String: String] = [
            "en-US": "🇺🇸",
            "fr-FR": "🇫🇷",
            "de-DE": "🇩🇪",
            "es-ES": "🇪🇸",
            "it-IT": "🇮🇹",
            "pt-BR": "🇧🇷",
            "zh-Hans": "🇨🇳",
            "zh-Hant": "🇹🇼",
            "ja-JP": "🇯🇵",
            "ko-KR": "🇰🇷",
            "ru-RU": "🇷🇺",
            "uk-UA": "🇺🇦",
            "th-TH": "🇹🇭",
            "vi-VN": "🇻🇳",
            "ar-SA": "🇸🇦",
            "yue-Hans": "🇭🇰",  // Hong Kong for Cantonese
            "yue-Hant": "🇭🇰"   // Hong Kong for Cantonese
        ]
        
        // Get downloaded Tesseract languages
        let downloadedTesseractLanguages = Set(tesseractEngine.availableLanguages())
        
        // Add Vision languages
        for code in visionLanguageCodes {
            // Use mapped name if available, otherwise generate from code
            let displayName = languageDisplayNames[code] ?? generateDisplayName(from: code)
            let flagEmoji = languageFlags[code] ?? getFlagEmoji(for: code)
            let tesseractCode = LanguageCodeMapper.toTesseract(code)
            let isDownloaded = downloadedTesseractLanguages.contains(tesseractCode)
            
            languages.append(Language(
                code: code,
                displayName: displayName,
                flagEmoji: flagEmoji,
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
                let flagEmoji = languageFlags[standardCode] ?? getFlagEmoji(for: standardCode)
                
                languages.append(Language(
                    code: standardCode,
                    displayName: langInfo.name,
                    flagEmoji: flagEmoji,
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
    
    /// Generate a display name from a language code
    private func generateDisplayName(from code: String) -> String {
        // Try to extract meaningful name from code
        // e.g., "en-US" -> "English (US)", "zh-Hans" -> "Chinese (Hans)"
        
        // Common language code prefixes
        let languageNames: [String: String] = [
            "en": "English",
            "fr": "French",
            "de": "German",
            "es": "Spanish",
            "it": "Italian",
            "pt": "Portuguese",
            "zh": "Chinese",
            "ja": "Japanese",
            "ko": "Korean",
            "ru": "Russian",
            "uk": "Ukrainian",
            "th": "Thai",
            "vi": "Vietnamese",
            "ar": "Arabic",
            "yue": "Cantonese",
            "nl": "Dutch",
            "sv": "Swedish",
            "no": "Norwegian",
            "da": "Danish",
            "fi": "Finnish",
            "pl": "Polish",
            "tr": "Turkish",
            "he": "Hebrew",
            "hi": "Hindi"
        ]
        
        // Split by hyphen
        let parts = code.split(separator: "-")
        if let firstPart = parts.first {
            let langCode = String(firstPart).lowercased()
            if let baseName = languageNames[langCode] {
                if parts.count > 1 {
                    let region = parts[1...].joined(separator: "-")
                    return "\(baseName) (\(region))"
                }
                return baseName
            }
        }
        
        // If no mapping found, return the code itself but formatted
        return code.replacingOccurrences(of: "-", with: " ")
    }
    
    /// Get flag emoji for a language code
    private func getFlagEmoji(for code: String) -> String? {
        // Try to extract country code and convert to flag emoji
        let parts = code.split(separator: "-")
        
        // Handle special cases and common mappings
        let countryMappings: [String: String] = [
            "en": "US",  // English defaults to US
            "fr": "FR",  // French defaults to France
            "de": "DE",  // German defaults to Germany
            "es": "ES",  // Spanish defaults to Spain
            "it": "IT",  // Italian defaults to Italy
            "pt": "PT",  // Portuguese defaults to Portugal (though we use BR for pt-BR)
            "zh": "CN",  // Chinese defaults to China
            "ja": "JP",  // Japanese
            "ko": "KR",  // Korean
            "ru": "RU",  // Russian
            "uk": "UA",  // Ukrainian
            "th": "TH",  // Thai
            "vi": "VN",  // Vietnamese
            "ar": "SA",  // Arabic defaults to Saudi Arabia
            "nl": "NL",  // Dutch defaults to Netherlands
            "sv": "SE",  // Swedish
            "no": "NO",  // Norwegian
            "da": "DK",  // Danish
            "fi": "FI",  // Finnish
            "pl": "PL",  // Polish
            "tr": "TR",  // Turkish
            "he": "IL",  // Hebrew defaults to Israel
            "hi": "IN",  // Hindi defaults to India
            "cs": "CZ",  // Czech
            "hu": "HU",  // Hungarian
            "el": "GR",  // Greek
            "ro": "RO",  // Romanian
            "bg": "BG",  // Bulgarian
            "hr": "HR",  // Croatian
            "sr": "RS",  // Serbian
            "sk": "SK",  // Slovak
            "sl": "SI",  // Slovenian
            "et": "EE",  // Estonian
            "lv": "LV",  // Latvian
            "lt": "LT"   // Lithuanian
        ]
        
        var countryCode: String?
        
        // If code has a country part (e.g., en-US), use it
        if parts.count > 1 {
            let possibleCountry = String(parts[1])
            // Check if it's a 2-letter country code
            if possibleCountry.count == 2 && possibleCountry.uppercased() == possibleCountry {
                countryCode = possibleCountry
            }
        }
        
        // Otherwise, try to map from language code
        if countryCode == nil, let firstPart = parts.first {
            countryCode = countryMappings[String(firstPart).lowercased()]
        }
        
        // Convert country code to flag emoji
        if let country = countryCode {
            return countryCodeToFlag(country)
        }
        
        return nil
    }
    
    /// Convert ISO country code to flag emoji
    private func countryCodeToFlag(_ countryCode: String) -> String? {
        let base = UInt32(127397)  // Unicode base for regional indicator symbols
        var flag = ""
        
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicodeScalar = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicodeScalar))
            }
        }
        
        return flag.isEmpty ? nil : flag
    }
}