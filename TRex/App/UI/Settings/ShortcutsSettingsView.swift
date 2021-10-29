import SwiftUI
import KeyboardShortcuts

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Shortcuts")) {
                HStack {
                    Text("Capture Text:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureText)
                }
                HStack {
                    Text("Trigger Automation:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .captureTextAndTriggerAutomation)
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
        .frame(width: 350, height: 100)
    }
}
