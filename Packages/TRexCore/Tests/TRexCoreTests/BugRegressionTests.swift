import AppKit
import Vision
import XCTest

@testable import TRexCore

final class BugRegressionTests: XCTestCase {
    func testRegisteringSameEngineIdentifierReplacesExistingEngine() {
        let manager = OCRManager.shared
        let originalVision = manager.engines.first { $0.identifier == "vision" }
        let originalCount = manager.engines.count

        manager.registerEngine(StubOCREngine(identifier: "vision", priority: 999))

        XCTAssertEqual(manager.engines.count, originalCount)
        XCTAssertEqual(manager.engines.filter { $0.identifier == "vision" }.count, 1)
        XCTAssertEqual(manager.engines.first { $0.identifier == "vision" }?.priority, 999)

        if let originalVision {
            manager.registerEngine(originalVision)
        }
    }

    @MainActor
    func testURLDetectionHandlesUnicodeBeforeURL() {
        let urls = TRex.detectedURLs(in: "Receipt 🧭 — visit example.com/account")

        XCTAssertEqual(urls.map(\.absoluteString), ["https://example.com/account"])
    }

    // capture() must report completion status so the CLI can exit
    // with a proper exit code instead of hanging (issue #93).
    @MainActor
    func testCaptureReturnsFalseWhenImageFileIsMissing() async {
        let trex = TRex()
        let missingPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("trex-missing-\(UUID().uuidString).png").path

        let success = await trex.capture(.captureFromFile, imagePath: missingPath)

        XCTAssertFalse(success)
    }

    @MainActor
    func testCaptureReturnsFalseWhenCaptureAlreadyInProgress() async throws {
        let trex = TRex()
        // A readable image with real text ensures this test fails only if the
        // in-progress guard is broken, not because the image can't be loaded.
        let imagePath = try Self.writeTemporaryImage(text: "Hello TRex")
        defer { try? FileManager.default.removeItem(atPath: imagePath) }
        XCTAssertTrue(trex.beginCaptureTransaction())
        defer { trex.endCaptureTransaction() }

        let success = await trex.capture(.captureFromFile, imagePath: imagePath)

        XCTAssertFalse(success)
    }

    @MainActor
    func testCaptureReturnsFalseWhenNoTextRecognized() async throws {
        let trex = TRex()
        let imagePath = try Self.writeTemporaryImage(text: nil)
        defer { try? FileManager.default.removeItem(atPath: imagePath) }

        let success = await trex.capture(.captureFromFile, imagePath: imagePath)

        XCTAssertFalse(success)
    }

    @MainActor
    private static func writeTemporaryImage(text: String?) throws -> String {
        let size = NSSize(width: 240, height: 80)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        if let text {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 32),
                .foregroundColor: NSColor.black,
            ]
            (text as NSString).draw(at: NSPoint(x: 10, y: 20), withAttributes: attributes)
        }
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            throw NSError(domain: "BugRegressionTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render test image"])
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("trex-test-\(UUID().uuidString).png")
        try png.write(to: url)
        return url.path
    }

    @MainActor
    func testWatchOutputRejectsSiblingPathWithHomePrefix() {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let siblingPath = home.path + "-outside/capture.txt"

        XCTAssertNil(WatchModeManager.sanitizedOutputURL(from: siblingPath))
        XCTAssertNotNil(WatchModeManager.sanitizedOutputURL(from: home.appendingPathComponent("capture.txt").path))
    }
}

private struct StubOCREngine: OCREngine {
    let identifier: String
    let priority: Int
    let name = "Stub"

    func supportsLanguage(_ language: String) -> Bool { true }

    func recognizeText(
        in image: CGImage,
        languages: [String],
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> OCRResult {
        OCRResult(text: "", confidence: 0, recognizedLanguages: languages)
    }

    func recognizeText(
        in image: CGImage,
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> OCRResult {
        OCRResult(text: "", confidence: 0, recognizedLanguages: [])
    }
}
