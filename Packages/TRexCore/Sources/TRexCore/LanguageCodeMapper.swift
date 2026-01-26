import Foundation

/// Centralized utility for language code mapping between different formats
public enum LanguageCodeMapper {
    /// Normalizes identifiers to a consistent "lang[-Script][-REGION]" format with hyphens
    public static func standardize(_ identifier: String) -> String {
        // First, replace underscores with hyphens
        let normalized = identifier.replacingOccurrences(of: "_", with: "-")

        // Parse components
        var components = Locale.components(fromIdentifier: normalized)
        if let language = components[NSLocale.Key.languageCode.rawValue] {
            components[NSLocale.Key.languageCode.rawValue] = language.lowercased()
        }
        if let script = components[NSLocale.Key.scriptCode.rawValue] {
            components[NSLocale.Key.scriptCode.rawValue] = script.capitalized
        }
        if let region = components[NSLocale.Key.countryCode.rawValue] {
            components[NSLocale.Key.countryCode.rawValue] = region.uppercased()
        }

        // Build the identifier manually to ensure hyphen format
        var parts: [String] = []
        if let language = components[NSLocale.Key.languageCode.rawValue] {
            parts.append(language.lowercased())
        }
        if let script = components[NSLocale.Key.scriptCode.rawValue] {
            parts.append(script.capitalized)
        }
        if let region = components[NSLocale.Key.countryCode.rawValue] {
            parts.append(region.uppercased())
        }

        return parts.isEmpty ? identifier : parts.joined(separator: "-")
    }

    /// Maps standard language codes (e.g., "en-US") to Tesseract language codes (e.g., "eng")
    public static func toTesseract(_ code: String) -> String {
        let normalizedCode = code.replacingOccurrences(of: "_", with: "-")
        let mapping: [String: String] = [
            // Common languages with region codes
            "en-US": "eng", "en": "eng",
            "fr-FR": "fra", "fr": "fra",
            "de-DE": "deu", "de": "deu",
            "es-ES": "spa", "es": "spa",
            "it-IT": "ita", "it": "ita",
            "pt-BR": "por", "pt": "por",
            "ru-RU": "rus", "ru": "rus",
            "ja-JP": "jpn", "ja": "jpn",
            "zh-Hans": "chi_sim", "zh-CN": "chi_sim",
            "zh-Hant": "chi_tra", "zh-TW": "chi_tra",
            "ko-KR": "kor", "ko": "kor",
            "ar-SA": "ara", "ar": "ara",
            "hi-IN": "hin", "hi": "hin",
            "th-TH": "tha", "th": "tha",
            "vi-VN": "vie", "vi-VT": "vie", "vi": "vie",
            "he-IL": "heb", "he": "heb",
            "pl-PL": "pol", "pl": "pol",
            "tr-TR": "tur", "tr": "tur",
            "uk-UA": "ukr", "uk": "ukr",
            "cs-CZ": "ces", "cs": "ces",
            "hu-HU": "hun", "hu": "hun",
            "sv-SE": "swe", "sv": "swe",
            "da-DK": "dan", "da": "dan",
            "no-NO": "nor", "no": "nor", "nb": "nor", "nn": "nor",
            "fi-FI": "fin", "fi": "fin",
            "nl-NL": "nld", "nl": "nld",
            "el-GR": "ell", "el": "ell",

            // Vision framework variants
            "ars-SA": "ara",  // Arabic secondary variant
            "yue-Hans": "chi_sim",  // Cantonese Simplified
            "yue-Hant": "chi_tra",  // Cantonese Traditional

            // Comprehensive ISO 639-1 to ISO 639-3 mapping
            "af": "afr",  // Afrikaans
            "am": "amh",  // Amharic
            "as": "asm",  // Assamese
            "az": "aze",  // Azerbaijani
            "be": "bel",  // Belarusian
            "bn": "ben",  // Bengali
            "bo": "bod",  // Tibetan
            "bs": "bos",  // Bosnian
            "br": "bre",  // Breton
            "bg": "bul",  // Bulgarian
            "ca": "cat",  // Catalan
            "cy": "cym",  // Welsh
            "et": "est",  // Estonian
            "eu": "eus",  // Basque
            "fo": "fao",  // Faroese
            "fa": "fas",  // Persian
            "fy": "fry",  // Frisian
            "gd": "gla",  // Scottish Gaelic
            "ga": "gle",  // Irish
            "gl": "glg",  // Galician
            "gu": "guj",  // Gujarati
            "ht": "hat",  // Haitian Creole
            "hr": "hrv",  // Croatian
            "hy": "hye",  // Armenian
            "iu": "iku",  // Inuktitut
            "id": "ind",  // Indonesian
            "is": "isl",  // Icelandic
            "jv": "jav",  // Javanese
            "kn": "kan",  // Kannada
            "ka": "kat",  // Georgian
            "kk": "kaz",  // Kazakh
            "km": "khm",  // Khmer
            "ky": "kir",  // Kyrgyz
            "ku": "kmr",  // Kurdish
            "lo": "lao",  // Lao
            "la": "lat",  // Latin
            "lv": "lav",  // Latvian
            "lt": "lit",  // Lithuanian
            "lb": "ltz",  // Luxembourgish
            "ml": "mal",  // Malayalam
            "mr": "mar",  // Marathi
            "mk": "mkd",  // Macedonian
            "mt": "mlt",  // Maltese
            "mn": "mon",  // Mongolian
            "mi": "mri",  // Maori
            "ms": "msa",  // Malay
            "my": "mya",  // Burmese
            "ne": "nep",  // Nepali
            "oc": "oci",  // Occitan
            "or": "ori",  // Odia
            "pa": "pan",  // Punjabi
            "ps": "pus",  // Pashto
            "qu": "que",  // Quechua
            "ro": "ron",  // Romanian
            "sa": "san",  // Sanskrit
            "si": "sin",  // Sinhala
            "sk": "slk",  // Slovak
            "sl": "slv",  // Slovenian
            "sd": "snd",  // Sindhi
            "sq": "sqi",  // Albanian
            "sr": "srp",  // Serbian
            "su": "sun",  // Sundanese
            "sw": "swa",  // Swahili
            "syr": "syr", // Syriac
            "ta": "tam",  // Tamil
            "tt": "tat",  // Tatar
            "te": "tel",  // Telugu
            "tg": "tgk",  // Tajik
            "ti": "tir",  // Tigrinya
            "to": "ton",  // Tongan
            "ug": "uig",  // Uyghur
            "ur": "urd",  // Urdu
            "uz": "uzb",  // Uzbek
            "yi": "yid",  // Yiddish
            "yo": "yor"   // Yoruba
        ]

        return mapping[normalizedCode] ?? normalizedCode
    }
    
    /// Maps Tesseract language codes (e.g., "eng") to standard language codes (e.g., "en-US")
    public static func fromTesseract(_ tesseractCode: String) -> String {
        let mapping: [String: String] = [
            // Major languages with region codes
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
            "ell": "el-GR",

            // Comprehensive ISO 639-3 to ISO 639-1 mapping
            "afr": "af",  // Afrikaans
            "amh": "am",  // Amharic
            "asm": "as",  // Assamese
            "aze": "az",  // Azerbaijani
            "bel": "be",  // Belarusian
            "ben": "bn",  // Bengali
            "bod": "bo",  // Tibetan
            "bos": "bs",  // Bosnian
            "bre": "br",  // Breton
            "bul": "bg",  // Bulgarian
            "cat": "ca",  // Catalan
            "cym": "cy",  // Welsh
            "est": "et",  // Estonian
            "eus": "eu",  // Basque
            "fao": "fo",  // Faroese
            "fas": "fa",  // Persian
            "fry": "fy",  // Frisian
            "gla": "gd",  // Scottish Gaelic
            "gle": "ga",  // Irish
            "glg": "gl",  // Galician
            "guj": "gu",  // Gujarati
            "hat": "ht",  // Haitian Creole
            "hrv": "hr",  // Croatian
            "hye": "hy",  // Armenian
            "iku": "iu",  // Inuktitut
            "ind": "id",  // Indonesian
            "isl": "is",  // Icelandic
            "jav": "jv",  // Javanese
            "kan": "kn",  // Kannada
            "kat": "ka",  // Georgian
            "kaz": "kk",  // Kazakh
            "khm": "km",  // Khmer
            "kir": "ky",  // Kyrgyz
            "kmr": "ku",  // Kurdish
            "lao": "lo",  // Lao
            "lat": "la",  // Latin
            "lav": "lv",  // Latvian
            "lit": "lt",  // Lithuanian
            "ltz": "lb",  // Luxembourgish
            "mal": "ml",  // Malayalam
            "mar": "mr",  // Marathi
            "mkd": "mk",  // Macedonian
            "mlt": "mt",  // Maltese
            "mon": "mn",  // Mongolian
            "mri": "mi",  // Maori
            "msa": "ms",  // Malay
            "mya": "my",  // Burmese
            "nep": "ne",  // Nepali
            "oci": "oc",  // Occitan
            "ori": "or",  // Odia
            "pan": "pa",  // Punjabi
            "pus": "ps",  // Pashto
            "que": "qu",  // Quechua
            "ron": "ro",  // Romanian
            "san": "sa",  // Sanskrit
            "sin": "si",  // Sinhala
            "slk": "sk",  // Slovak
            "slv": "sl",  // Slovenian
            "snd": "sd",  // Sindhi
            "sqi": "sq",  // Albanian
            "srp": "sr",  // Serbian
            "sun": "su",  // Sundanese
            "swa": "sw",  // Swahili
            "syr": "syr", // Syriac
            "tam": "ta",  // Tamil
            "tat": "tt",  // Tatar
            "tel": "te",  // Telugu
            "tgk": "tg",  // Tajik
            "tir": "ti",  // Tigrinya
            "ton": "to",  // Tongan
            "uig": "ug",  // Uyghur
            "urd": "ur",  // Urdu
            "uzb": "uz",  // Uzbek
            "yid": "yi",  // Yiddish
            "yor": "yo"   // Yoruba
        ]

        return mapping[tesseractCode] ?? tesseractCode
    }
}
