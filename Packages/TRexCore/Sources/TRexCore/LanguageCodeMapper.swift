import Foundation

/// Centralized utility for language code mapping between different formats
public enum LanguageCodeMapper {
    /// Maps standard language codes (e.g., "en-US") to Tesseract language codes (e.g., "eng")
    public static func toTesseract(_ code: String) -> String {
        let mapping: [String: String] = [
            "en-US": "eng",
            "en": "eng",
            "fr-FR": "fra",
            "fr": "fra",
            "de-DE": "deu",
            "de": "deu",
            "es-ES": "spa",
            "es": "spa",
            "it-IT": "ita",
            "it": "ita",
            "pt-BR": "por",
            "pt": "por",
            "ru-RU": "rus",
            "ru": "rus",
            "ja-JP": "jpn",
            "ja": "jpn",
            "zh-Hans": "chi_sim",
            "zh-CN": "chi_sim",
            "zh-Hant": "chi_tra",
            "zh-TW": "chi_tra",
            "ko-KR": "kor",
            "ko": "kor",
            "ar-SA": "ara",
            "ar": "ara",
            "hi-IN": "hin",
            "hi": "hin",
            "th-TH": "tha",
            "th": "tha",
            "vi-VN": "vie",
            "vi": "vie",
            "he-IL": "heb",
            "he": "heb",
            "pl-PL": "pol",
            "pl": "pol",
            "tr-TR": "tur",
            "tr": "tur",
            "uk-UA": "ukr",
            "uk": "ukr",
            "cs-CZ": "ces",
            "cs": "ces",
            "hu-HU": "hun",
            "hu": "hun",
            "sv-SE": "swe",
            "sv": "swe",
            "da-DK": "dan",
            "da": "dan",
            "no-NO": "nor",
            "no": "nor",
            "fi-FI": "fin",
            "fi": "fin",
            "nl-NL": "nld",
            "nl": "nld",
            "el-GR": "ell",
            "el": "ell"
        ]
        
        return mapping[code] ?? code
    }
    
    /// Maps Tesseract language codes (e.g., "eng") to standard language codes (e.g., "en-US")
    public static func fromTesseract(_ tesseractCode: String) -> String {
        let mapping: [String: String] = [
            "eng": "en-US",
            "fra": "fr-FR",
            "deu": "de-DE",
            "spa": "es-ES",
            "ita": "it-IT",
            "por": "pt-BR",
            "rus": "ru-RU",
            "jpn": "ja-JP",
            "chi_sim": "zh-Hans",
            "chi_tra": "zh-Hant",
            "kor": "ko-KR",
            "ara": "ar-SA",
            "hin": "hi-IN",
            "tha": "th-TH",
            "vie": "vi-VN",
            "heb": "he-IL",
            "pol": "pl-PL",
            "tur": "tr-TR",
            "ukr": "uk-UA",
            "ces": "cs-CZ",
            "hun": "hu-HU",
            "swe": "sv-SE",
            "dan": "da-DK",
            "nor": "no-NO",
            "fin": "fi-FI",
            "nld": "nl-NL",
            "ell": "el-GR"
        ]
        
        return mapping[tesseractCode] ?? tesseractCode
    }
}