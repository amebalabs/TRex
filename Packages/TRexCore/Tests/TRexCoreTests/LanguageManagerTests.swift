import XCTest
@testable import TRexCore

final class LanguageManagerTests: XCTestCase {
    func testEnglishRemainsAvailableForTesseractDownload() {
        let languages = LanguageManager.shared.availableLanguages()
        let english = languages.first { $0.displayName == "English (American)" }

        XCTAssertNotNil(english)
        guard let english else { return }
        XCTAssertEqual(english.displayNameWithFlag, "🇺🇸 English (American)")
        XCTAssertNotEqual(english.source, .vision)
    }
}
