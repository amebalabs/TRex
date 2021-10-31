import SwiftUI
import KeyboardShortcuts

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Shortcuts").bold()) {
                HStack {
                    Text("Capture Text:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureScreen)
                }
                HStack {
                    Text("Trigger Automation:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureScreenAndTriggerAutomation)
                }
                HStack {
                    Text("Recognize from Clipboard:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureClipboard)
                }
            }
            Spacer()
        }
        .padding(20)
        .frame(width: 410, height: 100)
    }
}
