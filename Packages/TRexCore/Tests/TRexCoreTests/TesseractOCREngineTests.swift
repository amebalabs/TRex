import AppKit
import Vision
import XCTest
@testable import TRexCore

final class TesseractOCREngineTests: XCTestCase {
    private func makeGrayscaleImage(with text: String) -> CGImage {
        let width = 1_400
        let height = 320
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        (text as NSString).draw(
            at: NSPoint(x: 80, y: 120),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 56),
                .foregroundColor: NSColor.black,
            ]
        )
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage()!
    }

    func testNormalizesGrayscaleInputToRGBAWithoutLanguageData() throws {
        let grayscale = makeGrayscaleImage(with: "TRex grayscale normalization")
        let normalized = try TesseractOCREngine.makeTesseractCompatibleImage(from: grayscale)

        XCTAssertEqual(normalized.width, grayscale.width)
        XCTAssertEqual(normalized.height, grayscale.height)
        XCTAssertEqual(normalized.bitsPerPixel, 32)
        XCTAssertEqual(normalized.colorSpace?.model, .rgb)
    }

    func testFallbackRespectsTesseractPreferenceAndDoesNotReenter() {
        XCTAssertFalse(
            TRex.shouldAttemptTesseractFallback(
                attemptedEngineID: "vision",
                tesseractEnabled: false
            )
        )
        XCTAssertFalse(
            TRex.shouldAttemptTesseractFallback(
                attemptedEngineID: "tesseract",
                tesseractEnabled: true
            )
        )
        XCTAssertTrue(
            TRex.shouldAttemptTesseractFallback(
                attemptedEngineID: "vision",
                tesseractEnabled: true
            )
        )
    }

    func testRecognizesGrayscaleImageWhenLanguageDataIsInstalled() async throws {
        let tessdata = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/TRex/tessdata/eng.traineddata")
        try XCTSkipUnless(
            FileManager.default.fileExists(atPath: tessdata.path),
            "English Tesseract data is not installed"
        )

        let result = try await TesseractOCREngine().recognizeText(
            in: makeGrayscaleImage(with: "TRex grayscale clipboard test"),
            languages: ["en-US"],
            recognitionLevel: .accurate
        )

        XCTAssertTrue(result.text.localizedCaseInsensitiveContains("grayscale"))
    }
}
