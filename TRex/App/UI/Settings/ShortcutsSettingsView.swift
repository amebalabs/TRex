import KeyboardShortcuts
import SwiftUI

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Capture ➜ Clipboard").bold()) {
                HStack {
                    Text("From Screen:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureScreen)
                }
                HStack {
                    Text("From Clipboard:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureClipboard)
                }
            }
            Divider()
            Section(header: Text("Capture ➜ Automation").bold()) {
                HStack {
                    Text("From Screen:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureScreenAndTriggerAutomation)
                }
                HStack {
                    Text("From Clipboard:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureClipboardAndTriggerAutomation)
                }
            }
            Spacer()
        }
        .padding(20)
        .frame(width: 410, height: 160)
    }
}
