import SwiftUI
import TRexCore

struct GeneralSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @State private var visionLanguages: [LanguageManager.Language] = []

    let width: CGFloat = 90
    
    var body: some View {
        Form {
            ToggleView(label: "Startup", secondLabel: "Start at Login",
                       state: $launchAtLogin.isEnabled,
                       width: width)

            ToggleView(label: "Sounds",
                       secondLabel: "Play Sounds",
                       state: $preferences.captureSound,
                       width: width)
            ToggleView(label: "Notifications",
                       secondLabel: "Show Recognized Text",
                       state: $preferences.resultNotification,
                       width: width)
            ToggleView(label: "Menu Bar", secondLabel: "Show Icon",
                       state: $preferences.showMenuBarIcon,
                       width: width)

            if preferences.showMenuBarIcon {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(NSColor.controlBackgroundColor))
                    HStack {
                        ForEach(Preferences.MenuBarIcon.allCases, id: \.self) { item in
                            MenuBarIconView(item: item, selected: $preferences.menuBarIcon).onTapGesture {
                                preferences.menuBarIcon = item
                            }
                        }
                    }
                }.frame(height: 70)
                    .padding([.leading, .trailing], 10)
            }

            // Only show Recognition Language section when using Apple Vision (not Tesseract)
            if !preferences.tesseractEnabled {
                Section(header: Text("Recognition Language")) {
                    if #available(OSX 13.0, *) {
                        HStack {
                            ToggleView(label: "", secondLabel: "Automatic",
                                       state: $preferences.automaticLanguageDetection,
                                       width: 0)
                            Picker(selection: $preferences.recognitionLanguageCode, label: Text("")) {
                                ForEach(visionLanguages, id: \.code) { language in
                                    Text(language.displayNameWithFlag)
                                        .tag(language.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .disabled(preferences.automaticLanguageDetection)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor.withAlphaComponent(0.3)), lineWidth: 0.5)
                            )
                            Spacer()
                        }
                    } else {
                        Picker(selection: $preferences.recognitionLanguageCode, label: Text("")) {
                            ForEach(visionLanguages, id: \.code) { language in
                                Text(language.displayNameWithFlag)
                                    .tag(language.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .labelsHidden()
                        .disabled(preferences.automaticLanguageDetection)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor.withAlphaComponent(0.3)), lineWidth: 0.5)
                        )
                    }
                    Text("More languages are available in the Tesseract menu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } else {
                // When Tesseract is enabled, show a note about language configuration
                Section(header: Text("Language Settings")) {
                    Text("Language configuration is available in the Tesseract settings tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            #if !MAC_APP_STORE
            Spacer()
            Divider()
            Section(header: Text("Updates")) {
                HStack {
                    Button("Check for Updates", action: {
                        checkForUpdates()
                    })
                    Spacer()
                    Toggle("Include beta updates", isOn: $preferences.includeBetaUpdates)
                        .toggleStyle(.checkbox)
                }
            }
            #endif
        }
        .padding(20)
        #if MAC_APP_STORE
        .frame(width: 410, height: preferences.showMenuBarIcon ? (preferences.tesseractEnabled ? 220 : 280) : (preferences.tesseractEnabled ? 140 : 200))
        #else
        .frame(width: 410, height: preferences.showMenuBarIcon ? (preferences.tesseractEnabled ? 280 : 340) : (preferences.tesseractEnabled ? 200 : 260))
        #endif
        .onAppear {
            loadVisionLanguages()
        }
    }
    
    private func loadVisionLanguages() {
        let manager = LanguageManager.shared
        let allLanguages = manager.availableLanguages()
        // Filter to only Vision-supported languages
        visionLanguages = allLanguages
            .filter { $0.source == .vision || $0.source == .both }
            .sorted { $0.displayName < $1.displayName }
    }
    
    #if !MAC_APP_STORE
    func checkForUpdates() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.softwareUpdater.checkForUpdates()
        }
    }
    #endif
}

struct MenuBarIconView: View {
    let item: Preferences.MenuBarIcon
    @Binding var selected: Preferences.MenuBarIcon
    var isSelected: Bool {
        selected == item
    }

    var body: some View {
        VStack(spacing: 2) {
            item.image()
                .resizable()
                .accentColor(isSelected ? .blue : .white)
                .frame(width: 30, height: 30, alignment: .center)
                .padding(3)
                .border(isSelected ? Color.blue : Color.clear, width: 2)
            Circle()
                .fill(isSelected ? Color.blue : Color.gray)
                .frame(width: 8, height: 8)
                .padding([.top], 5)
        }
    }
}

struct ToggleView: View {
    let label: String
    let secondLabel: String
    @Binding var state: Bool
    let width: CGFloat

    var mainLabel: String {
        guard !label.isEmpty else { return "" }
        return "\(label):"
    }

    var body: some View {
        HStack {
            HStack {
                Spacer()
                Text(mainLabel)
            }.frame(width: width)
            Toggle("", isOn: $state)
            Text(secondLabel)
            Spacer()
        }
    }
}
