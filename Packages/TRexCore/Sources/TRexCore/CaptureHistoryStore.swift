import Cocoa
import Foundation
import OSLog

/// A single capture history entry, persisted as JSON.
public struct CaptureHistoryEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let text: String
    public let timestamp: Date
    public let engineName: String?
    public let confidence: Float
    public let recognizedLanguages: [String]
    public let thumbnailFilename: String?

    public init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        engineName: String? = nil,
        confidence: Float = 0,
        recognizedLanguages: [String] = [],
        thumbnailFilename: String? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.engineName = engineName
        self.confidence = confidence
        self.recognizedLanguages = recognizedLanguages
        self.thumbnailFilename = thumbnailFilename
    }
}

/// Manages capture history persistence and thumbnail storage.
///
/// History is stored as JSON in `~/Library/Application Support/TRex/History/history.json`.
/// Thumbnails are stored as JPEG files in `~/Library/Application Support/TRex/History/thumbnails/`.
@MainActor
public final class CaptureHistoryStore: ObservableObject {
    @Published public var entries: [CaptureHistoryEntry] = []

    private let logger = Logger(subsystem: "com.ameba.TRex", category: "CaptureHistoryStore")
    private let historyDirectoryURL: URL
    private let thumbnailsDirectoryURL: URL
    private let historyFileURL: URL
    private var saveTask: Task<Void, Never>?

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let historyDir = appSupport.appendingPathComponent("TRex/History", isDirectory: true)
        self.historyDirectoryURL = historyDir
        self.thumbnailsDirectoryURL = historyDir.appendingPathComponent("thumbnails", isDirectory: true)
        self.historyFileURL = historyDir.appendingPathComponent("history.json")

        ensureDirectories()
        loadEntries()
    }

    // MARK: - Public API

    /// Add a new history entry from captured text and an optional OCR result.
    public func addEntry(text: String, ocrResult: OCRResult? = nil, maxEntries: Int = 100) {
        let entryID = UUID()
        var thumbnailFilename: String?

        // Save thumbnail from source image if available
        if let sourceImage = ocrResult?.sourceImage {
            let filename = "\(entryID.uuidString).jpg"
            saveThumbnail(sourceImage, filename: filename)
            thumbnailFilename = filename
        }

        let entry = CaptureHistoryEntry(
            id: entryID,
            text: text,
            timestamp: Date(),
            engineName: ocrResult?.engineName,
            confidence: ocrResult?.confidence ?? 0,
            recognizedLanguages: ocrResult?.recognizedLanguages ?? [],
            thumbnailFilename: thumbnailFilename
        )

        entries.insert(entry, at: 0)

        // Prune oldest entries beyond the cap
        while entries.count > maxEntries {
            let removed = entries.removeLast()
            deleteThumbnail(for: removed)
        }

        saveAsync()
    }

    /// Remove a specific entry by ID.
    public func removeEntry(_ entry: CaptureHistoryEntry) {
        deleteThumbnail(for: entry)
        entries.removeAll { $0.id == entry.id }
        saveAsync()
    }

    /// Remove all history entries and thumbnails.
    public func clearAll() {
        entries.removeAll()
        let fm = FileManager.default
        // Remove thumbnails directory contents
        if let files = try? fm.contentsOfDirectory(at: thumbnailsDirectoryURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? fm.removeItem(at: file)
            }
        }
        saveAsync()
    }

    /// Resolve the file URL for an entry's thumbnail.
    public func thumbnailURL(for entry: CaptureHistoryEntry) -> URL? {
        guard let filename = entry.thumbnailFilename else { return nil }
        let url = thumbnailsDirectoryURL.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Persistence

    private func ensureDirectories() {
        let fm = FileManager.default
        try? fm.createDirectory(at: thumbnailsDirectoryURL, withIntermediateDirectories: true)
    }

    private func loadEntries() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: historyFileURL.path) else { return }

        do {
            let data = try Data(contentsOf: historyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([CaptureHistoryEntry].self, from: data)
        } catch {
            logger.error("Failed to load capture history: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func saveAsync() {
        let entriesToSave = entries
        let fileURL = historyFileURL
        let logger = self.logger
        let previousTask = saveTask

        saveTask = Task.detached(priority: .utility) {
            if let previousTask {
                await previousTask.value
            }
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(entriesToSave)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                logger.error("Failed to save capture history: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Thumbnails

    private func saveThumbnail(_ cgImage: CGImage, filename: String) {
        let maxDimension: CGFloat = 200
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let scale = min(maxDimension / width, maxDimension / height, 1.0)
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)

        guard let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: newWidth,
                  height: newHeight,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            logger.warning("Failed to create thumbnail context")
            return
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let scaledImage = context.makeImage() else {
            logger.warning("Failed to create scaled thumbnail image")
            return
        }

        let url = thumbnailsDirectoryURL.appendingPathComponent(filename)
        let nsImage = NSImage(cgImage: scaledImage, size: NSSize(width: newWidth, height: newHeight))

        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.6]) else {
            logger.warning("Failed to encode thumbnail as JPEG")
            return
        }

        do {
            try jpegData.write(to: url, options: .atomic)
        } catch {
            logger.warning("Failed to write thumbnail: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deleteThumbnail(for entry: CaptureHistoryEntry) {
        guard let filename = entry.thumbnailFilename else { return }
        let url = thumbnailsDirectoryURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
