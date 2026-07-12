import AppKit

/// Attempts to replace pasteboard text. Before clearing, it eagerly snapshots
/// readable representations and, if writing fails, attempts a best-effort restore.
/// The return value reports only whether replacement succeeded; it does not
/// guarantee that every prior representation was restored.
@MainActor
public enum PasteboardWriter {
    @discardableResult
    public static func replaceString(_ text: String, in pasteboard: NSPasteboard = .general) -> Bool {
        replaceString(text, in: pasteboard) { value, board in
            board.setString(value, forType: .string)
        }
    }

    @discardableResult
    static func replaceString(
        _ text: String,
        in pasteboard: NSPasteboard,
        writer: (String, NSPasteboard) -> Bool
    ) -> Bool {
        let previousItems = copiedItems(from: pasteboard)
        pasteboard.clearContents()

        guard writer(text, pasteboard) else {
            if !previousItems.isEmpty {
                _ = pasteboard.writeObjects(previousItems)
            }
            return false
        }

        return true
    }

    private static func copiedItems(from pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).compactMap { item in
            let copy = NSPasteboardItem()
            var copiedRepresentation = false
            for type in item.types {
                if let data = item.data(forType: type) {
                    copiedRepresentation = copy.setData(data, forType: type) || copiedRepresentation
                }
            }
            return copiedRepresentation ? copy : nil
        }
    }
}
