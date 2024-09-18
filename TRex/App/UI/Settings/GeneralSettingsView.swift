import SwiftUI
import TRexCore

struct GeneralSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

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

            Section(header: Text("Recognition Language")) {
                if #available(OSX 13.0, *) {
                    ToggleView(label: "Detection", secondLabel: "Automatic",
                               state: $preferences.automaticLanguageDetection,
                               width: width)
                }
                HStack {
                    EnumPicker(selected: $preferences.recongitionLanguage, title: "")
                        .disabled(preferences.automaticLanguageDetection)
                }
            }
        }
        .padding(20)
        .frame(width: 410, height: preferences.showMenuBarIcon ? 260 : 180)
    }
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
