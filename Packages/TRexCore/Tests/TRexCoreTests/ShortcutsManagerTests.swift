import XCTest
@testable import TRexCore

final class ShortcutsManagerTests: XCTestCase {
    func testShortcutNameMustBeMeaningfulAndIsTrimmed() {
        XCTAssertNil(ShortcutsManager.normalizedShortcutName(" \n\t "))
        XCTAssertEqual(ShortcutsManager.normalizedShortcutName("  Process OCR \n"), "Process OCR")
    }
}
