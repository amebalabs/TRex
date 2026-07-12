import XCTest

@testable import TRexCore

final class TableDetectionTests: XCTestCase {
    func testMarkdownEscapesPipesAndNormalizesUnevenRows() {
        let table = DetectedTable(
            headers: ["Name", "Status"],
            rows: [
                ["A | B", "Ready", "Extra"],
                ["Second"]
            ]
        )

        let lines = table.toMarkdown().split(separator: "\n", omittingEmptySubsequences: false)

        XCTAssertEqual(lines.count, 4)
        XCTAssertTrue(lines[0].contains("| Name"))
        XCTAssertTrue(lines[0].contains("Status"))
        XCTAssertTrue(lines[1].contains("---"))
        XCTAssertTrue(lines[2].contains("A \\| B"))
        XCTAssertTrue(lines[2].contains("Extra"))
        XCTAssertTrue(lines[3].contains("Second"))
        XCTAssertTrue(lines.allSatisfy { $0.hasPrefix("| ") && $0.hasSuffix(" |") })
    }

    func testCSVQuotesCarriageReturns() {
        let table = DetectedTable(headers: nil, rows: [["first\rsecond", "ok"]])

        XCTAssertEqual(table.toCSV(), "\"first\rsecond\",ok")
    }

    func testTSVRemovesAllEmbeddedLineBreaks() {
        let table = DetectedTable(headers: nil, rows: [["first\r\nsecond", "ok"]])

        XCTAssertEqual(table.toTSV(), "first  second\tok")
    }
}
