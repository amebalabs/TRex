import SwiftUI

func clipboardHasSupportedContente() -> Bool {
    if let url = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil)?.first as? NSURL, url.isFileURL {
        return true
    }

    if let _ = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
        return true
    }

    return false
}
