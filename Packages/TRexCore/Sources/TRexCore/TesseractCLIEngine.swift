import Foundation
import Cocoa

public class TesseractCLIEngine {
    public static let shared = TesseractCLIEngine()
    
    private let tesseractPaths = [
        "/usr/local/bin/tesseract",
        "/opt/homebrew/bin/tesseract",
        "/usr/bin/tesseract"
    ]
    
    public struct TesseractInfo {
        public let path: String
        public let version: String
        public let availableLanguages: [String]
    }
    
    public struct Language {
        public let code: String
        public let displayName: String
        
        public static let commonLanguages = [
            Language(code: "eng", displayName: "English"),
            Language(code: "fra", displayName: "French"),
            Language(code: "deu", displayName: "German"),
            Language(code: "spa", displayName: "Spanish"),
            Language(code: "ita", displayName: "Italian"),
            Language(code: "por", displayName: "Portuguese"),
            Language(code: "rus", displayName: "Russian"),
            Language(code: "jpn", displayName: "Japanese"),
            Language(code: "chi_sim", displayName: "Chinese (Simplified)"),
            Language(code: "chi_tra", displayName: "Chinese (Traditional)"),
            Language(code: "kor", displayName: "Korean"),
            Language(code: "ara", displayName: "Arabic"),
            Language(code: "hin", displayName: "Hindi"),
            Language(code: "tha", displayName: "Thai"),
            Language(code: "vie", displayName: "Vietnamese"),
            Language(code: "heb", displayName: "Hebrew"),
            Language(code: "pol", displayName: "Polish"),
            Language(code: "tur", displayName: "Turkish"),
            Language(code: "ukr", displayName: "Ukrainian"),
            Language(code: "ces", displayName: "Czech"),
            Language(code: "hun", displayName: "Hungarian"),
            Language(code: "swe", displayName: "Swedish"),
            Language(code: "dan", displayName: "Danish"),
            Language(code: "nor", displayName: "Norwegian"),
            Language(code: "fin", displayName: "Finnish"),
            Language(code: "nld", displayName: "Dutch"),
            Language(code: "ell", displayName: "Greek")
        ]
        
        public static func displayName(for code: String) -> String {
            commonLanguages.first(where: { $0.code == code })?.displayName ?? code
        }
    }
    
    private init() {}
    
    private func resolvingSymlinks(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let resolvedURL = url.resolvingSymlinksInPath()
        return resolvedURL.path
    }
    
    public func detectTesseract() -> TesseractInfo? {
        for path in tesseractPaths {
            if FileManager.default.fileExists(atPath: path) {
                let version = getTesseractVersion(at: path)
                let languages = getAvailableLanguages(at: path)
                return TesseractInfo(path: path, version: version, availableLanguages: languages)
            }
        }
        
        // Try which command as fallback
        if let path = getPathFromWhich() {
            let version = getTesseractVersion(at: path)
            let languages = getAvailableLanguages(at: path)
            return TesseractInfo(path: path, version: version, availableLanguages: languages)
        }
        
        return nil
    }
    
    private func getPathFromWhich() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["tesseract"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Error finding tesseract: \(error)")
        }
        
        return nil
    }
    
    private func getTesseractVersion(at path: String) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = ["--version"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Extract version from first line
                let lines = output.components(separatedBy: .newlines)
                if let firstLine = lines.first {
                    let components = firstLine.components(separatedBy: " ")
                    if components.count >= 2 {
                        return components[1]
                    }
                }
            }
        } catch {
            print("Error getting tesseract version: \(error)")
        }
        
        return "Unknown"
    }
    
    private func getAvailableLanguages(at path: String) -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = ["--list-langs"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                // Skip first line (header) and filter empty lines
                return lines.dropFirst().filter { !$0.isEmpty }
            }
        } catch {
            print("Error getting tesseract languages: \(error)")
        }
        
        return []
    }
    
    public func performOCR(on image: NSImage, languages: [String], tesseractPath: String) -> String? {
        print("[TesseractCLI] Starting OCR with languages: \(languages)")
        print("[TesseractCLI] Tesseract path: \(tesseractPath)")
        
        // Try to use the original path first (for symlinks in allowed paths)
        var actualTesseractPath = tesseractPath
        
        // Check if the path exists and is executable
        if !FileManager.default.isExecutableFile(atPath: tesseractPath) {
            print("[TesseractCLI] Path not executable, trying to resolve symlinks")
            actualTesseractPath = resolvingSymlinks(for: tesseractPath)
            print("[TesseractCLI] Resolved tesseract path: \(actualTesseractPath)")
        }
        
        // Save image to temporary file
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("[TesseractCLI] Failed to convert NSImage to PNG data")
            return nil
        }
        
        let tempDir = NSTemporaryDirectory()
        let inputPath = (tempDir as NSString).appendingPathComponent("trex_tesseract_input.png")
        let outputPath = (tempDir as NSString).appendingPathComponent("trex_tesseract_output")
        
        print("[TesseractCLI] Input image path: \(inputPath)")
        print("[TesseractCLI] Output base path: \(outputPath)")
        
        defer {
            // Clean up temporary files
            try? FileManager.default.removeItem(atPath: inputPath)
            try? FileManager.default.removeItem(atPath: outputPath + ".txt")
        }
        
        do {
            try pngData.write(to: URL(fileURLWithPath: inputPath))
            print("[TesseractCLI] Successfully wrote input image, size: \(pngData.count) bytes")
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: actualTesseractPath)
            
            var args = [inputPath, outputPath]
            
            // Add language parameter if specified
            if !languages.isEmpty {
                args.append("-l")
                args.append(languages.joined(separator: "+"))
            }
            
            task.arguments = args
            print("[TesseractCLI] Running command: \(actualTesseractPath) \(args.joined(separator: " "))")
            
            let pipe = Pipe()
            let outputPipe = Pipe()
            task.standardError = pipe
            task.standardOutput = outputPipe
            
            try task.run()
            print("[TesseractCLI] Process launched successfully")
            task.waitUntilExit()
            
            print("[TesseractCLI] Process exit code: \(task.terminationStatus)")
            
            // Read stdout
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8), !outputString.isEmpty {
                print("[TesseractCLI] Process stdout: \(outputString)")
            }
            
            if task.terminationStatus == 0 {
                // Read the output text file
                let outputTextPath = outputPath + ".txt"
                print("[TesseractCLI] Reading output from: \(outputTextPath)")
                
                if FileManager.default.fileExists(atPath: outputTextPath) {
                    let result = try String(contentsOfFile: outputTextPath, encoding: .utf8)
                    print("[TesseractCLI] Raw output: '\(result)'")
                    let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("[TesseractCLI] Trimmed output: '\(trimmed)'")
                    return trimmed.isEmpty ? nil : trimmed
                } else {
                    print("[TesseractCLI] Output file not found at: \(outputTextPath)")
                }
            } else {
                // Read error output
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                if let errorString = String(data: errorData, encoding: .utf8) {
                    print("[TesseractCLI] Tesseract stderr: \(errorString)")
                }
            }
        } catch {
            print("[TesseractCLI] Error performing OCR: \(error)")
            if let nsError = error as NSError? {
                print("[TesseractCLI] Error domain: \(nsError.domain)")
                print("[TesseractCLI] Error code: \(nsError.code)")
                print("[TesseractCLI] Error description: \(nsError.localizedDescription)")
                if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileNoSuchFileError {
                    print("[TesseractCLI] The file doesn't exist at path: \(actualTesseractPath)")
                }
            }
        }
        
        return nil
    }
}