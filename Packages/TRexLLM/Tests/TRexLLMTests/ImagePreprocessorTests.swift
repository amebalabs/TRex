import XCTest
import AppKit
@testable import TRexLLM

final class ImagePreprocessorTests: XCTestCase {
    let preprocessor = ImagePreprocessor()

    func testPreprocessValidImage() throws {
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        let data = try preprocessor.preprocess(image)

        // Verify we got data back
        XCTAssertGreaterThan(data.count, 0)

        // Verify it's JPEG data (starts with FF D8 FF)
        let bytes = [UInt8](data.prefix(3))
        XCTAssertEqual(bytes[0], 0xFF)
        XCTAssertEqual(bytes[1], 0xD8)
        XCTAssertEqual(bytes[2], 0xFF)
    }

    func testBase64Encoding() {
        let testData = "Hello, World!".data(using: .utf8)!
        let base64 = preprocessor.toBase64(testData)

        XCTAssertFalse(base64.isEmpty)
        XCTAssertEqual(Data(base64Encoded: base64), testData)
    }

    func testLargeImageResize() throws {
        // Create a large test image
        let size = CGSize(width: 4000, height: 4000)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        let data = try preprocessor.preprocess(image)

        // The preprocessed image should be smaller than 2MB target
        XCTAssertLessThan(data.count, 2_500_000)
    }
}
