import Foundation
import TesseractSwift

/// Language management for OCR engines
public class LanguageManager {
    public nonisolated(unsafe) static let shared = LanguageManager()
    
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
        var addedDisplayNames = Set<String>()

        // Get Vision Framework languages dynamically
        let visionEngine = VisionOCREngine()
        let visionLanguageCodes = visionEngine.availableLanguages()

        // Get downloaded Tesseract languages
        let downloadedTesseractLanguages = Set(tesseractEngine.availableLanguages())

        // Add Vision languages
        for rawCode in visionLanguageCodes {
            let mapped = LanguageCodeMapper.standardize(rawCode)
            let code = normalizeIdentifier(mapped)
            
            // Skip if we've already added this exact code
            if addedCodes.contains(code) {
                continue
            }
            
            let displayName = resolveDisplayName(for: code, fallback: rawCode)
            
            // Skip duplicate display names (e.g., ar-SA and ars-SA both resolve to "Arabic")
            // Keep the first one we encounter
            if addedDisplayNames.contains(displayName) {
                continue
            }
            
            let flagEmoji = getFlagEmoji(for: code)
            let tesseractCode = LanguageCodeMapper.toTesseract(code)
            let isDownloaded = downloadedTesseractLanguages.contains(tesseractCode)

            languages.append(Language(
                code: code,
                displayName: displayName,
                flagEmoji: flagEmoji,
                source: isDownloaded ? .both : .vision,
                isDownloaded: true,
                fileSize: nil
            ))
            addedCodes.insert(code)
            addedDisplayNames.insert(displayName)
        }

        // Add all available Tesseract languages
        for langInfo in LanguageDownloader.allAvailableLanguages() {
            let normalizedTesseract = LanguageCodeMapper.standardize(LanguageCodeMapper.fromTesseract(langInfo.code))
            let standardCode = normalizeIdentifier(normalizedTesseract)
            
            // Skip if we've already added this exact code
            if addedCodes.contains(standardCode) {
                continue
            }
            
            let displayName = resolveDisplayName(for: standardCode, fallback: langInfo.name)
            
            // Skip duplicate display names
            if addedDisplayNames.contains(displayName) {
                continue
            }
            
            let isDownloaded = downloadedTesseractLanguages.contains(langInfo.code)
            let flagEmoji = getFlagEmoji(for: standardCode)

            languages.append(Language(
                code: standardCode,
                displayName: displayName,
                flagEmoji: flagEmoji,
                source: .tesseract,
                isDownloaded: isDownloaded,
                fileSize: langInfo.fileSize
            ))
            addedCodes.insert(standardCode)
            addedDisplayNames.insert(displayName)
        }

        return languages.sorted { $0.displayNameWithFlag.localizedCaseInsensitiveCompare($1.displayNameWithFlag) == .orderedAscending }
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
    
    /// Resolve a user-facing display name for a language code
    private func resolveDisplayName(for code: String, fallback: String?) -> String {
        let normalizedCode = normalizeIdentifier(code)

        // Complete overrides for all Vision-supported languages
        let overrides: [String: String] = [
            // English
            "en-US": "English",
            "en": "English",
            
            // European Languages
            "fr-FR": "French",
            "fr": "French",
            "de-DE": "German",
            "de": "German",
            "es-ES": "Spanish", 
            "es": "Spanish",
            "it-IT": "Italian",
            "it": "Italian",
            "pt-BR": "Portuguese (Brazil)",
            "pt-PT": "Portuguese",
            "pt": "Portuguese",
            
            // Chinese variants
            "zh-Hans": "Chinese, Simplified",
            "zh-Hant": "Chinese, Traditional",
            "zh": "Chinese",
            "yue-Hans": "Cantonese (Simplified)",
            "yue-Hant": "Cantonese (Traditional)",
            "yue": "Cantonese",
            
            // Asian Languages
            "ja-JP": "Japanese",
            "ja": "Japanese",
            "ko-KR": "Korean",
            "ko": "Korean",
            "th-TH": "Thai",
            "th": "Thai",
            "vi-VT": "Vietnamese",
            "vi-VN": "Vietnamese",
            "vi": "Vietnamese",
            "id-ID": "Indonesian",
            "id": "Indonesian",
            "ms-MY": "Malay",
            "ms": "Malay",
            
            // Middle Eastern
            "ar-SA": "Arabic",
            "ars-SA": "Arabic",
            "ar": "Arabic",
            "he-IL": "Hebrew",
            "he": "Hebrew",
            "tr-TR": "Turkish",
            "tr": "Turkish",
            
            // Slavic Languages
            "ru-RU": "Russian",
            "ru": "Russian",
            "uk-UA": "Ukrainian",
            "uk": "Ukrainian",
            "pl-PL": "Polish",
            "pl": "Polish",
            "cs-CZ": "Czech",
            "cs": "Czech",
            
            // Nordic Languages
            "sv-SE": "Swedish",
            "sv": "Swedish",
            "da-DK": "Danish",
            "da": "Danish",
            "no-NO": "Norwegian",
            "nb-NO": "Norwegian Bokmål",
            "nn-NO": "Norwegian Nynorsk",
            "no": "Norwegian",
            "nb": "Norwegian Bokmål",
            "nn": "Norwegian Nynorsk",
            "fi-FI": "Finnish",
            "fi": "Finnish",
            
            // Other European
            "nl-NL": "Dutch",
            "nl": "Dutch",
            "ro-RO": "Romanian",
            "ro": "Romanian",
            "hu-HU": "Hungarian",
            "hu": "Hungarian",
            "el-GR": "Greek",
            "el": "Greek"
        ]

        // Use our override if available
        if let explicit = overrides[normalizedCode] {
            return explicit
        }
        
        // Try base language code
        let components = Locale.components(fromIdentifier: normalizedCode)
        if let languageCode = components[NSLocale.Key.languageCode.rawValue], 
           let explicit = overrides[languageCode] {
            return explicit
        }

        // Last resort fallbacks
        if let fallback = fallback {
            return fallback
        }

        return normalizedCode.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
    }

    private func cleanedDisplayName(_ name: String, regionHint: String?) -> String {
        guard let open = name.firstIndex(of: "("),
              let close = name[open...].firstIndex(of: ")") else {
            return name
        }

        let inside = name[name.index(after: open)..<close].trimmingCharacters(in: .whitespacesAndNewlines)
        let base = name[..<open].trimmingCharacters(in: .whitespacesAndNewlines)

        let regionCodePattern = try? NSRegularExpression(pattern: "^[A-Z0-9]{2,3}$")
        let isRegionCode = regionCodePattern?.firstMatch(in: inside, range: NSRange(location: 0, length: inside.utf16.count)) != nil

        if isRegionCode && (regionHint == nil || inside == regionHint) {
            return String(base)
        }

        return name
    }

    /// Normalize codes like "cs_CZ" into "cs-CZ"
    private func normalizeIdentifier(_ code: String) -> String {
        var components = Locale.components(fromIdentifier: code.replacingOccurrences(of: "_", with: "-"))
        if let lang = components[NSLocale.Key.languageCode.rawValue] {
            components[NSLocale.Key.languageCode.rawValue] = lang.lowercased()
        }
        if let script = components[NSLocale.Key.scriptCode.rawValue] {
            components[NSLocale.Key.scriptCode.rawValue] = script.capitalized
        }
        if let region = components[NSLocale.Key.countryCode.rawValue] {
            components[NSLocale.Key.countryCode.rawValue] = region.uppercased()
        }
        return Locale.identifier(fromComponents: components)
    }
    
    /// Get flag emoji for a language code
    private func getFlagEmoji(for code: String) -> String? {
        // Try to extract country code and convert to flag emoji
        let normalized = normalizeIdentifier(code)
        let parts = normalized.split(separator: "-")
        
        // Handle specific language codes with their appropriate flags
        let specificMappings: [String: String] = [
            "en-US": "US",
            "fr-FR": "FR",
            "it-IT": "IT",
            "de-DE": "DE",
            "es-ES": "ES",
            "pt-BR": "BR",
            "pt-PT": "PT",
            "zh-Hans": "CN",  // Simplified Chinese
            "zh-Hant": "TW",  // Traditional Chinese
            "yue-Hans": "CN", // Cantonese Simplified (China)
            "yue-Hant": "HK", // Cantonese Traditional (Hong Kong)
            "ko-KR": "KR",
            "ja-JP": "JP",
            "ru-RU": "RU",
            "uk-UA": "UA",
            "th-TH": "TH",
            "vi-VT": "VN",  // Vietnamese
            "vi-VN": "VN",
            "ar-SA": "SA",
            "ars-SA": "SA", // Arabic variant
            "tr-TR": "TR",
            "id-ID": "ID",
            "cs-CZ": "CZ",
            "da-DK": "DK",
            "nl-NL": "NL",
            "no-NO": "NO",
            "nn-NO": "NO",  // Norwegian Nynorsk
            "nb-NO": "NO",  // Norwegian Bokmål
            "ms-MY": "MY",
            "pl-PL": "PL",
            "ro-RO": "RO",
            "sv-SE": "SE",
            "he-IL": "IL",
            "hi-IN": "IN",
            "hu-HU": "HU",
            "el-GR": "GR",
            "fi-FI": "FI",
            "bg-BG": "BG",
            "hr-HR": "HR",
            "sr-RS": "RS",
            "sk-SK": "SK",
            "sl-SI": "SI",
            "et-EE": "EE",
            "lv-LV": "LV",
            "lt-LT": "LT"
        ]
        
        // First check for exact match
        if let countryCode = specificMappings[normalized] {
            return countryCodeToFlag(countryCode)
        }
        
        // Handle special cases and common mappings for base language codes
        let baseMappings: [String: String] = [
            "en": "US",  // English defaults to US
            "fr": "FR",  // French defaults to France
            "de": "DE",  // German defaults to Germany
            "es": "ES",  // Spanish defaults to Spain
            "it": "IT",  // Italian defaults to Italy
            "pt": "PT",  // Portuguese defaults to Portugal
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
            "nb": "NO",  // Norwegian Bokmål
            "nn": "NO",  // Norwegian Nynorsk
            "da": "DK",  // Danish
            "fi": "FI",  // Finnish
            "pl": "PL",  // Polish
            "tr": "TR",  // Turkish
            "he": "IL",  // Hebrew defaults to Israel
            "yue": "HK", // Cantonese defaults to Hong Kong
            "hi": "IN",  // Hindi defaults to India
            "cs": "CZ",  // Czech
            "hu": "HU",  // Hungarian
            "el": "GR",  // Greek
            "ro": "RO",  // Romanian
            "id": "ID",  // Indonesian
            "ms": "MY",  // Malay
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
            let possibleCountry = String(parts.last ?? "")
            // Check if it's a 2-letter country code
            if possibleCountry.count == 2 && possibleCountry.uppercased() == possibleCountry {
                countryCode = possibleCountry
            }
        }
        
        // Otherwise, try to map from language code
        if countryCode == nil, let firstPart = parts.first {
            countryCode = baseMappings[String(firstPart).lowercased()]
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
