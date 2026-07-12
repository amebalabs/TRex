import XCTest
@testable import TRexCore

@MainActor
final class CaptureHistoryStoreTests: XCTestCase {
    func testIgnoresEmptyEntriesAndPersistsPrunedSnapshot() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("TRexHistoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = CaptureHistoryStore(storageRoot: root)
        store.addEntry(text: " \n\t ")
        XCTAssertTrue(store.entries.isEmpty)

        store.addEntry(text: "first", maxEntries: 1)
        store.addEntry(text: "second", maxEntries: 1)
        XCTAssertEqual(store.entries.map(\.text), ["second"])

        await store.waitForPendingSave()
        let historyURL = root.appendingPathComponent("TRex/History/history.json")
        let data = try Data(contentsOf: historyURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let persisted = try decoder.decode([CaptureHistoryEntry].self, from: data)
        XCTAssertEqual(persisted.map(\.text), ["second"])
    }
}
