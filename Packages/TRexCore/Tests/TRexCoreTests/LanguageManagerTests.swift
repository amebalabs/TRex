import XCTest
@testable import TRexCore

final class LanguageManagerTests: XCTestCase {
    func testEnglishRemainsAvailableForTesseractDownload() {
        let languages = LanguageManager.shared.availableLanguages()
        let english = languages.first { $0.displayName == "English" }

        XCTAssertNotNil(english)
        guard let english else { return }
        XCTAssertNotEqual(english.source, .vision)
    }
}
