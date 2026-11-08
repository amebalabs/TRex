import Foundation
import XCTest
@testable import TRexCore

final class LanguageManagerTests: XCTestCase {
    func testModernVisionIdentifiersPreserveRegionsScriptsAndAliases() {
        let identifiers = [
            "en-US": "en-US",
            "pt-BR": "pt-BR",
            "ru-RU": "ru-RU",
            "zh-Hans": "zh-Hans",
            "zh-Hant": "zh-Hant",
            "yue-Hans": "yue-Hans",
            "yue-Hant": "yue-Hant",
            "ar-SA": "ar-SA",
            "ars-SA": "ar-SA",
            "vi-VT": "vi-VN",
            "sr-Latn-RS": "sr-Latn-RS"
        ]
        for (input, expected) in identifiers {
            XCTAssertEqual(
                VisionOCREngine.visionLanguageIdentifier(Locale.Language(identifier: input)),
                expected, "Unexpected identifier for \(input)"
            )
        }
    }

    func testChineseVisionVariantsRemainDistinctInLanguageList() throws {
        let languages = LanguageManager.shared.availableLanguages()
        let simplified = try XCTUnwrap(languages.first { $0.code == "zh-Hans" })
        let traditional = try XCTUnwrap(languages.first { $0.code == "zh-Hant" })
        XCTAssertEqual(simplified.displayNameWithFlag, "🇨🇳 Chinese, Simplified")
        XCTAssertEqual(traditional.displayNameWithFlag, "🇹🇼 Chinese, Traditional")
        XCTAssertNotEqual(simplified.source, .tesseract)
        XCTAssertNotEqual(traditional.source, .tesseract)
    }

    func testEnglishRemainsAvailableForTesseractDownload() {
        let languages = LanguageManager.shared.availableLanguages()
        let english = languages.first { $0.displayName == "English (American)" }

        XCTAssertNotNil(english)
        guard let english else { return }
        XCTAssertEqual(english.displayNameWithFlag, "🇺🇸 English (American)")
        XCTAssertNotEqual(english.source, .vision)
    }
}
