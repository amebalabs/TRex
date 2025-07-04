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
    
    // Common languages with approximate file sizes
    public let availableLanguages: [LanguageInfo] = [
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
        LanguageInfo(code: "tha", name: "Thai", fileSize: 25_000_000, isInstalled: false),
        LanguageInfo(code: "vie", name: "Vietnamese", fileSize: 20_000_000, isInstalled: false),
        LanguageInfo(code: "heb", name: "Hebrew", fileSize: 15_000_000, isInstalled: false),
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
        LanguageInfo(code: "ell", name: "Greek", fileSize: 20_000_000, isInstalled: false)
    ]
    
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