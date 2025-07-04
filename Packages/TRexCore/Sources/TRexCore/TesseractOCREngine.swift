import Foundation
import Cocoa
import Vision

// Protocol that matches the TesseractWrapper interface
@objc public protocol TesseractWrapperProtocol {
    func initialize(withDataPath dataPath: String, language: String) -> Bool
    func setImageData(_ imageData: Data, width: Int, height: Int, bytesPerRow: Int)
    func recognizedText() -> String
    func meanConfidence() -> Int
    func clear()
    static func availableLanguages(atPath dataPath: String) -> [String]
}

public class TesseractOCREngine: OCREngine {
    private let tessdataPath: String
    
    public init() {
        // Always use Library/Application Support for tessdata
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                     in: .userDomainMask).first!
        let trexPath = appSupportPath.appendingPathComponent("TRex")
        self.tessdataPath = trexPath.appendingPathComponent("tessdata").path
        
        // Ensure tessdata directory exists
        try? FileManager.default.createDirectory(atPath: tessdataPath, withIntermediateDirectories: true)
    }
    
    public var name: String { "Tesseract OCR" }
    
    public var identifier: String { "tesseract" }
    
    public var priority: Int { 100 }
    
    public var isAvailable: Bool {
        // Check if TesseractWrapper has been registered via the bridge
        return TesseractBridge.shared.isAvailable
    }
    
    public func availableLanguages() -> [String] {
        // Get list of available language files
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: tessdataPath)
            return files.compactMap { file in
                if file.hasSuffix(".traineddata") {
                    return String(file.dropLast(12)) // Remove .traineddata extension
                }
                return nil
            }
        } catch {
            return []
        }
    }
    
    public func supportsLanguage(_ language: String) -> Bool {
        // Convert language code to Tesseract format
        let tesseractLang = LanguageCodeMapper.toTesseract(language)
        
        // Check if the traineddata file exists
        let dataFile = (tessdataPath as NSString).appendingPathComponent("\(tesseractLang).traineddata")
        return FileManager.default.fileExists(atPath: dataFile)
    }
    
    public func recognizeText(in image: CGImage, languages: [String], recognitionLevel: VNRequestTextRecognitionLevel) async throws -> OCRResult {
        // Get wrapper instance from the bridge
        guard let wrapper = TesseractBridge.shared.createWrapper() else {
            throw OCRError.initializationFailed("TesseractWrapper not available. Please ensure the library is properly linked.")
        }
        
        // Languages should be in standard format (e.g., "en-US"), convert to Tesseract format
        let tesseractLangs = languages.map { LanguageCodeMapper.toTesseract($0) }
        let langString = tesseractLangs.joined(separator: "+")
        
        // Initialize Tesseract
        guard wrapper.initialize(withDataPath: tessdataPath, language: langString) else {
            throw OCRError.initializationFailed("Failed to initialize Tesseract with languages: \(langString)")
        }
        
        // Convert CGImage to raw pixel data
        let width = image.width
        let height = image.height
        let bitsPerComponent = 8
        let bytesPerPixel = 4 // RGBA
        let bytesPerRow = bytesPerPixel * width
        
        // Create bitmap context
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: bitsPerComponent,
                                     bytesPerRow: bytesPerRow,
                                     space: colorSpace,
                                     bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw OCRError.imageProcessingFailed("Failed to create bitmap context")
        }
        
        // Draw image into context
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Get pixel data
        guard let pixelData = context.data else {
            throw OCRError.imageProcessingFailed("Failed to get pixel data")
        }
        
        // Convert to NSData for Objective-C bridge
        let imageData = NSData(bytes: pixelData, length: height * bytesPerRow)
        
        // Process with Tesseract
        wrapper.setImageData(imageData as Data, width: width, height: height, bytesPerRow: bytesPerRow)
        
        // Get recognized text
        let text = wrapper.recognizedText()
        let confidence = Float(wrapper.meanConfidence()) / 100.0
        
        // Clear for memory efficiency
        wrapper.clear()
        
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