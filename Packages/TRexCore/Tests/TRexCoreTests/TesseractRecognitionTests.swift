import AppKit
import CoreGraphics
import CoreText
import Foundation
import TesseractSwift
import Vision
import XCTest

@testable import TRexCore

/// Regression tests for issue #89: Tesseract reported "success" with empty text
/// because TesseractSwift's recognize(cgImage:) passes the source image's
/// bytesPerRow while rendering pixels into a packed buffer. Screen captures
/// usually have padded rows, so every capture produced an empty result that
/// was silently written to the clipboard.
final class TesseractRecognitionTests: XCTestCase {
    private static let sampleText = "Hello World 123"

    /// Render text into an RGBA image. `rowPadding` adds extra bytes per row,
    /// mimicking the padded strides produced by decoded screenshots.
    private func makeTextImage(text: String, rowPadding: Int) throws -> CGImage {
        let width = 600
        let height = 120
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4 + rowPadding,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        drawText(text, in: context, width: width, height: height, white: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        return try XCTUnwrap(context.makeImage())
    }

    private func makeGrayscaleTextImage(text: String) throws -> CGImage {
        let width = 600
        let height = 120
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ))
        drawText(text, in: context, width: width, height: height, white: CGColor(gray: 1, alpha: 1))
        return try XCTUnwrap(context.makeImage())
    }

    private func drawText(_ text: String, in context: CGContext, width: Int, height: Int, white: CGColor) {
        context.setFillColor(white)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard !text.isEmpty else { return }
        let attributed = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 48),
            .foregroundColor: NSColor.black
        ])
        let line = CTLineCreateWithAttributedString(attributed)
        context.textPosition = CGPoint(x: 20, y: 40)
        CTLineDraw(line, context)
    }

    func testRecognizesTextWhenSourceImageHasPackedRows() async throws {
        let image = try makeTextImage(text: Self.sampleText, rowPadding: 0)
        let result = try await TesseractOCREngine().recognizeText(
            in: image,
            languages: ["en-US"],
            recognitionLevel: .accurate
        )
        XCTAssertTrue(result.text.contains(Self.sampleText), "Got: '\(result.text)'")
    }

    func testRecognizesTextWhenSourceImageHasPaddedRows() async throws {
        let image = try makeTextImage(text: Self.sampleText, rowPadding: 64)
        XCTAssertNotEqual(image.bytesPerRow, image.width * 4, "Image must have padded rows for this regression test")

        let result = try await TesseractOCREngine().recognizeText(
            in: image,
            languages: ["en-US"],
            recognitionLevel: .accurate
        )
        XCTAssertTrue(result.text.contains(Self.sampleText), "Got: '\(result.text)'")
    }

    func testRecognizesTextInGrayscaleImage() async throws {
        let image = try makeGrayscaleTextImage(text: Self.sampleText)
        let result = try await TesseractOCREngine().recognizeText(
            in: image,
            languages: ["en-US"],
            recognitionLevel: .accurate
        )
        XCTAssertTrue(result.text.contains(Self.sampleText), "Got: '\(result.text)'")
    }

    func testThrowsInsteadOfReturningEmptySuccessWhenNoTextFound() async throws {
        let image = try makeTextImage(text: "", rowPadding: 0)

        do {
            let result = try await TesseractOCREngine().recognizeText(
                in: image,
                languages: ["en-US"],
                recognitionLevel: .accurate
            )
            XCTFail("Expected an error, got success with text: '\(result.text)'")
        } catch let error as OCRError {
            guard case .recognitionFailed(let message) = error else {
                return XCTFail("Expected recognitionFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("eng"), "Error should include the language: \(message)")
        }
    }
}

/// Regression tests for issue #88: Bengali (and other Vision-unsupported
/// scripts) must be offered and correctly mapped so OCRManager can route them
/// to Tesseract.
final class TesseractLanguageExposureTests: XCTestCase {
    func testBengaliIsInDownloadCatalog() {
        XCTAssertTrue(
            LanguageDownloader.allAvailableLanguages().contains { $0.code == "ben" },
            "Bengali must be available for download"
        )
    }

    func testBengaliCodeMappingRoundTrips() {
        XCTAssertEqual(LanguageCodeMapper.toTesseract("bn"), "ben")
        XCTAssertEqual(LanguageCodeMapper.fromTesseract("ben"), "bn")
    }

    func testTesseractEngineSupportsBengaliAndGreek() {
        let engine = TesseractOCREngine()
        XCTAssertTrue(engine.supportsLanguage("bn"), "Bengali must be supported (downloadable) by Tesseract")
        XCTAssertTrue(engine.supportsLanguage("el-GR"), "Greek must be supported (downloadable) by Tesseract")
    }

    func testLanguageManagerOffersBengali() {
        let bengali = LanguageManager.shared.availableLanguages().first { $0.displayName == "Bengali" }
        XCTAssertNotNil(bengali, "Bengali must appear in the language list")
        XCTAssertEqual(bengali.map { LanguageCodeMapper.toTesseract($0.code) }, "ben")
    }
}
