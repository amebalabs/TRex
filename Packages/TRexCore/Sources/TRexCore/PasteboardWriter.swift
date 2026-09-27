import AppKit

/// Attempts to replace pasteboard text and, when safe, restore the previous
/// contents if the write fails.
///
/// Reading the general pasteboard can trigger the system's pasteboard privacy
/// alert ("app would like to paste from ..."), so the restore snapshot is only
/// taken when the read is known to be prompt-free:
/// - On macOS 15.4+ the snapshot is taken only when `NSPasteboard.accessBehavior`
///   is `.alwaysAllow`; checking the property itself never prompts.
/// - On earlier systems there is no way to check, so the snapshot is taken only
///   for user-initiated writes (e.g. copying a history entry), never for
///   automatic OCR or watch-mode writes.
///
/// The return value reports only whether replacement succeeded; it does not
/// guarantee that every prior representation was restored.
@MainActor
public enum PasteboardWriter {
    @discardableResult
    public static func replaceString(
        _ text: String,
        in pasteboard: NSPasteboard = .general,
        userInitiated: Bool = false
    ) -> Bool {
        replaceString(
            text,
            in: pasteboard,
            snapshotAllowed: shouldSnapshotBeforeWriting(userInitiated: userInitiated, in: pasteboard)
        ) { value, board in
            board.setString(value, forType: .string)
        }
    }

    @discardableResult
    static func replaceString(
        _ text: String,
        in pasteboard: NSPasteboard,
        snapshotAllowed: Bool,
        writer: (String, NSPasteboard) -> Bool
    ) -> Bool {
        let previousItems = snapshotAllowed ? copiedItems(from: pasteboard) : []
        pasteboard.clearContents()

        guard writer(text, pasteboard) else {
            if !previousItems.isEmpty {
                _ = pasteboard.writeObjects(previousItems)
            }
            return false
        }

        return true
    }

    /// Whether snapshotting the pasteboard before a write is guaranteed not to
    /// show a pasteboard privacy prompt. See the type-level documentation.
    static func shouldSnapshotBeforeWriting(userInitiated: Bool, in pasteboard: NSPasteboard) -> Bool {
        if #available(macOS 15.4, *) {
            // Only an explicit "always allow" guarantees a prompt-free read;
            // .default and .ask may still surface the paste alert.
            return pasteboard.accessBehavior == .alwaysAllow
        }
        return userInitiated
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
