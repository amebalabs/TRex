import KeyboardShortcuts
import SwiftUI
import TRexCore

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, shortcuts, about, automation, customWords, tesseract
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
                .tag(Tabs.shortcuts)
            if #available(macOS 12.0, *) {
                AutomationSettingsView()
                    .tabItem {
                        Label("Automation", systemImage: "bolt.badge.a")
                    }
                    .tag(Tabs.automation)
                    .environmentObject(ShortcutsManager())
            } else {
                AutomationSettingsView()
                    .tabItem {
                        Label("Automation", systemImage: "bolt.badge.a")
                    }
                    .tag(Tabs.automation)
            }
            CustomWordsView()
                .tabItem {
                    Label("Custom Words", systemImage: "text.redaction")
                }
                .tag(Tabs.customWords)
            TesseractSettingsView()
                .tabItem {
                    Label("Advanced OCR", systemImage: "text.viewfinder")
                }
                .tag(Tabs.tesseract)
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info")
                }
                .tag(Tabs.about)
        }.padding(20)
    }
}
