import SwiftUI
import TRexCore

struct AutomationSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @EnvironmentObject var shortcutsManager: ShortcutsManager
    let width: CGFloat = 80
    var body: some View {
        VStack {
            ToggleView(label: "Open URLs", secondLabel: "Detected in Text",
                       state: $preferences.autoOpenCapturedURL,
                       width: width)
            ToggleView(label: "", secondLabel: "From QR Code",
                       state: $preferences.autoOpenQRCodeURL,
                       width: width)

            Divider()

            HStack {
                Text("Trigger URL Scheme:")
                TextField("{text} variable contains captured text", text: $preferences.autoOpenProvidedURL)
            }

            ToggleView(label: "", secondLabel: "Append New Line",
                       state: $preferences.autoOpenProvidedURLAddNewLine,
                       width: 129)
            Spacer()
            Divider()
            HStack {
                Picker("Run Shortcut:", selection: $preferences.autoRunShortcut, content: {
                    ForEach(shortcutsManager.shortcuts, id: \.self) { shortcut in
                        Text(shortcut)
                    }
                })

                HStack(spacing: 0) {
                    if !preferences.autoRunShortcut.isEmpty {
                        Button(action: {
                            shortcutsManager.runShortcut(inputText: "Hello from TRex!")
                        }, label: {
                            Image(systemName: "play.fill")
                        })
                        Button(action: {
                            shortcutsManager.viewCurrentShortcut()
                        }, label: {
                            Image(systemName: "slider.horizontal.3")
                        })
                    }

                    Button(action: {
                        shortcutsManager.createShortcut()
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
            }.onAppear { shortcutsManager.getShortcuts() }
        }.padding(20)
            .frame(width: 410, height: 160)
    }
}
