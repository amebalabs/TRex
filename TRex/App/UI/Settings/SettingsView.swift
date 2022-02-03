import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, shortcuts, about, automation, customWords
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
                .tag(Tabs.general)
            AutomationSettingsView()
                .tabItem {
                    Label("Automation", systemImage: "bolt.badge.a")
                }
                .tag(Tabs.automation)
                .environmentObject(ShortcutsManager())
            CustomWordsView()
                .tabItem {
                    Label("Custom Words", systemImage: "text.redaction")
                }
                .tag(Tabs.customWords)
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info")
                }
                .tag(Tabs.about)
        }.padding(20)
    }
}
