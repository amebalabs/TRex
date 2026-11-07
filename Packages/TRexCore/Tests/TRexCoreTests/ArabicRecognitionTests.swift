import AppKit
import CoreText
import Vision
import XCTest

@testable import TRexCore

final class ArabicRecognitionTests: XCTestCase {
    private let sample = "اهلا كيف حالك اليوم"

    private func image() throws -> CGImage {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 900, height: 160, bitsPerComponent: 8, bytesPerRow: 3600,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 900, height: 160))
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: sample, attributes: [
            .font: NSFont.systemFont(ofSize: 48), .foregroundColor: NSColor.black
        ]))
        context.textPosition = CGPoint(x: 30, y: 65)
        CTLineDraw(line, context)
        return try XCTUnwrap(context.makeImage())
    }

    func testAccurateRecognitionPreservesArabic() async throws {
        let engine = VisionOCREngine()
        try XCTSkipUnless(engine.supportsLanguage("ar-SA"), "Arabic requires a supported Vision model")
        for languages in [["ar-SA"], []] {
            let result = try await engine.recognizeText(in: image(), languages: languages, recognitionLevel: .accurate)
            XCTAssertEqual(result.text, sample)
            XCTAssertEqual(result.recognitionLevel, "accurate")
        }
    }

    func testFastRecognitionRejectsUnsupportedArabic() async throws {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        try XCTSkipIf(request.supportedRecognitionLanguages().contains("ar-SA"), "Fast model now supports Arabic")
        try await assertFastRecognitionFails(languages: ["ar-SA"])
        try await assertFastRecognitionFails(languages: ["en-US", "ar-SA"])
    }

    func testFastRecognitionDoesNotGuessAnUnknownScript() async throws {
        try await assertFastRecognitionFails(languages: [])
    }

    private func assertFastRecognitionFails(languages: [String], file: StaticString = #filePath, line: UInt = #line) async throws {
        let source = try image()
        do {
            let result = try await VisionOCREngine().recognizeText(in: source, languages: languages, recognitionLevel: .fast)
            XCTFail("Unsupported fast recognition must fail instead of copying garbage: \(result.text)", file: file, line: line)
        } catch {
            XCTAssertTrue(error is OCRError, "Unexpected failure: \(error)", file: file, line: line)
        }
    }
}
