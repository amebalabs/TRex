import Foundation

public class TesseractLanguageDownloader {
    public static let shared = TesseractLanguageDownloader()
    
    private let tessdataURL = "https://github.com/tesseract-ocr/tessdata/raw/main/"
    private let tessdataPath: String
    
    public struct LanguageInfo {
        public let code: String
        public let name: String
        public let fileSize: Int64? // in bytes
        public var isInstalled: Bool
        
        public var displayName: String {
            "\(name) (\(code))"
        }
    }
    
    // All available languages from tessdata repository with approximate file sizes
    public let availableLanguages: [LanguageInfo] = [
        // Most common languages
        LanguageInfo(code: "eng", name: "English", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "fra", name: "French", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "deu", name: "German", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "spa", name: "Spanish", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "ita", name: "Italian", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "por", name: "Portuguese", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "rus", name: "Russian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "jpn", name: "Japanese", fileSize: 35_000_000, isInstalled: false),
        LanguageInfo(code: "chi_sim", name: "Chinese (Simplified)", fileSize: 40_000_000, isInstalled: false),
        LanguageInfo(code: "chi_tra", name: "Chinese (Traditional)", fileSize: 45_000_000, isInstalled: false),
        LanguageInfo(code: "kor", name: "Korean", fileSize: 30_000_000, isInstalled: false),
        LanguageInfo(code: "ara", name: "Arabic", fileSize: 35_000_000, isInstalled: false),
        LanguageInfo(code: "hin", name: "Hindi", fileSize: 30_000_000, isInstalled: false),
        
        // European languages
        LanguageInfo(code: "pol", name: "Polish", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "tur", name: "Turkish", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "ukr", name: "Ukrainian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "ces", name: "Czech", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "hun", name: "Hungarian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "swe", name: "Swedish", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "dan", name: "Danish", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "nor", name: "Norwegian", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "fin", name: "Finnish", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "nld", name: "Dutch", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "ell", name: "Greek", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "bul", name: "Bulgarian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "hrv", name: "Croatian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "slk", name: "Slovak", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "slv", name: "Slovenian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "srp", name: "Serbian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "ron", name: "Romanian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "sqi", name: "Albanian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "mkd", name: "Macedonian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "bos", name: "Bosnian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "bel", name: "Belarusian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "est", name: "Estonian", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "lav", name: "Latvian", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "lit", name: "Lithuanian", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "isl", name: "Icelandic", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "mlt", name: "Maltese", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "cym", name: "Welsh", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "gle", name: "Irish", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "gla", name: "Scottish Gaelic", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "cat", name: "Catalan", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "eus", name: "Basque", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "glg", name: "Galician", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "cos", name: "Corsican", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "oci", name: "Occitan", fileSize: 15_000_000, isInstalled: false),
        
        // Asian languages
        LanguageInfo(code: "tha", name: "Thai", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "vie", name: "Vietnamese", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "heb", name: "Hebrew", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "ind", name: "Indonesian", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "msa", name: "Malay", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "tgl", name: "Tagalog", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "ceb", name: "Cebuano", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "jav", name: "Javanese", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "sun", name: "Sundanese", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "mya", name: "Burmese", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "khm", name: "Khmer", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "lao", name: "Lao", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "mon", name: "Mongolian", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "kat", name: "Georgian", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "hye", name: "Armenian", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "aze", name: "Azerbaijani", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "kaz", name: "Kazakh", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "kir", name: "Kyrgyz", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "uzb", name: "Uzbek", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "tgk", name: "Tajik", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "tat", name: "Tatar", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "uig", name: "Uyghur", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "bod", name: "Tibetan", fileSize: 30_000_000, isInstalled: false),
        LanguageInfo(code: "dzo", name: "Dzongkha", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "nep", name: "Nepali", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "sin", name: "Sinhala", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "div", name: "Dhivehi", fileSize: 20_000_000, isInstalled: false),
        
        // South Asian languages
        LanguageInfo(code: "ben", name: "Bengali", fileSize: 30_000_000, isInstalled: false),
        LanguageInfo(code: "pan", name: "Punjabi", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "guj", name: "Gujarati", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "ori", name: "Odia", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "tam", name: "Tamil", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "tel", name: "Telugu", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "kan", name: "Kannada", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "mal", name: "Malayalam", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "mar", name: "Marathi", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "asm", name: "Assamese", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "urd", name: "Urdu", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "snd", name: "Sindhi", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "pus", name: "Pashto", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "san", name: "Sanskrit", fileSize: 25_000_000, isInstalled: false),
        
        // African languages
        LanguageInfo(code: "afr", name: "Afrikaans", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "swa", name: "Swahili", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "amh", name: "Amharic", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "tir", name: "Tigrinya", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "yor", name: "Yoruba", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "hat", name: "Haitian Creole", fileSize: 15_000_000, isInstalled: false),
        
        // Pacific languages
        LanguageInfo(code: "mri", name: "Maori", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "ton", name: "Tongan", fileSize: 15_000_000, isInstalled: false),
        
        // Other languages
        LanguageInfo(code: "epo", name: "Esperanto", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "lat", name: "Latin", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "grc", name: "Ancient Greek", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "yid", name: "Yiddish", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "chr", name: "Cherokee", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "syr", name: "Syriac", fileSize: 20_000_000, isInstalled: false),
        
        // Additional script variants
        LanguageInfo(code: "chi_sim_vert", name: "Chinese Simplified (Vertical)", fileSize: 40_000_000, isInstalled: false),
        LanguageInfo(code: "chi_tra_vert", name: "Chinese Traditional (Vertical)", fileSize: 45_000_000, isInstalled: false),
        LanguageInfo(code: "jpn_vert", name: "Japanese (Vertical)", fileSize: 35_000_000, isInstalled: false),
        LanguageInfo(code: "kor_vert", name: "Korean (Vertical)", fileSize: 30_000_000, isInstalled: false),
        LanguageInfo(code: "script/Arabic", name: "Arabic Script", fileSize: 35_000_000, isInstalled: false),
        LanguageInfo(code: "script/Armenian", name: "Armenian Script", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "script/Bengali", name: "Bengali Script", fileSize: 30_000_000, isInstalled: false),
        LanguageInfo(code: "script/Canadian_Aboriginal", name: "Canadian Aboriginal Script", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "script/Cherokee", name: "Cherokee Script", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "script/Cyrillic", name: "Cyrillic Script", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "script/Devanagari", name: "Devanagari Script", fileSize: 30_000_000, isInstalled: false),
        LanguageInfo(code: "script/Ethiopic", name: "Ethiopic Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Fraktur", name: "Fraktur Script", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "script/Georgian", name: "Georgian Script", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "script/Greek", name: "Greek Script", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "script/Gujarati", name: "Gujarati Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Gurmukhi", name: "Gurmukhi Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/HanS", name: "Han Simplified Script", fileSize: 40_000_000, isInstalled: false),
        LanguageInfo(code: "script/HanT", name: "Han Traditional Script", fileSize: 45_000_000, isInstalled: false),
        LanguageInfo(code: "script/Hangul", name: "Hangul Script", fileSize: 30_000_000, isInstalled: false),
        LanguageInfo(code: "script/Hebrew", name: "Hebrew Script", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "script/Japanese", name: "Japanese Script", fileSize: 35_000_000, isInstalled: false),
        LanguageInfo(code: "script/Kannada", name: "Kannada Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Khmer", name: "Khmer Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Lao", name: "Lao Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Latin", name: "Latin Script", fileSize: 15_000_000, isInstalled: false),
        LanguageInfo(code: "script/Malayalam", name: "Malayalam Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Myanmar", name: "Myanmar Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Oriya", name: "Oriya Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Sinhala", name: "Sinhala Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Syriac", name: "Syriac Script", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "script/Tamil", name: "Tamil Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Telugu", name: "Telugu Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Thaana", name: "Thaana Script", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "script/Thai", name: "Thai Script", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "script/Tibetan", name: "Tibetan Script", fileSize: 30_000_000, isInstalled: false),
        LanguageInfo(code: "script/Vietnamese", name: "Vietnamese Script", fileSize: 20_000_000, isInstalled: false)
    ].sorted { $0.name < $1.name }
    
    private init() {
        // Set up tessdata path
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                     in: .userDomainMask).first!
        let trexPath = appSupportPath.appendingPathComponent("TRex")
        self.tessdataPath = trexPath.appendingPathComponent("tessdata").path
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(atPath: tessdataPath, withIntermediateDirectories: true)
    }
    
    public func getInstalledLanguages() -> [LanguageInfo] {
        var languages = availableLanguages
        
        // Check which languages are installed
        for i in 0..<languages.count {
            let filePath = (tessdataPath as NSString).appendingPathComponent("\(languages[i].code).traineddata")
            languages[i].isInstalled = FileManager.default.fileExists(atPath: filePath)
        }
        
        return languages
    }
    
    public func isLanguageInstalled(_ code: String) -> Bool {
        let filePath = (tessdataPath as NSString).appendingPathComponent("\(code).traineddata")
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    public func downloadLanguage(_ code: String, progress: @escaping (Double) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        let fileName = "\(code).traineddata"
        let urlString = tessdataURL + fileName
        
        guard let url = URL(string: urlString) else {
            completion(.failure(DownloadError.invalidURL))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    completion(.failure(DownloadError.noData))
                }
                return
            }
            
            let destinationPath = (self.tessdataPath as NSString).appendingPathComponent(fileName)
            let destinationURL = URL(fileURLWithPath: destinationPath)
            
            do {
                // Remove existing file if any
                try? FileManager.default.removeItem(at: destinationURL)
                
                // Move downloaded file
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        // Observe progress
        task.resume()
    }
    
    public func deleteLanguage(_ code: String) throws {
        let fileName = "\(code).traineddata"
        let filePath = (tessdataPath as NSString).appendingPathComponent(fileName)
        try FileManager.default.removeItem(atPath: filePath)
    }
    
    public var totalInstalledSize: Int64 {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: tessdataPath)
            var totalSize: Int64 = 0
            
            for file in files where file.hasSuffix(".traineddata") {
                let filePath = (tessdataPath as NSString).appendingPathComponent(file)
                if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
    
    enum DownloadError: LocalizedError {
        case invalidURL
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid download URL"
            case .noData:
                return "No data received"
            }
        }
    }
}