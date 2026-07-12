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
