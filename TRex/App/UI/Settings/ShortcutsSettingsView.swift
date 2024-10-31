import KeyboardShortcuts
import SwiftUI
import TRexCore

struct ShortcutsSettingsView: View {
    @EnvironmentObject var preferences: Preferences
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
            Divider()
            Section(header: Text("Quick Action").bold(), footer: Text("Trigger with 􀆕+click on menu bar icon")) {
                EnumPicker(selected: $preferences.optionQuickAction, title: "")
            }
            Spacer()
            
        }
        .padding(20)
        .frame(width: 410, height: 260)
    }
}
