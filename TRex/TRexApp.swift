import SwiftUI
import TRexCore

@main
struct TRexApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(Preferences.shared)
                .environmentObject(appDelegate)
        }
    }
}
