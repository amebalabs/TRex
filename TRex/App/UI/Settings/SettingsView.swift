import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, shortcuts, about, automation
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
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info")
                }
                .tag(Tabs.about)
        }
        .padding(20)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

    let width: CGFloat = 70
    var body: some View {
        Form {
            ToggleView(label: "Startup", secondLabel: "Start at login",
                       state: $launchAtLogin.isEnabled,
                       width: width)

            ToggleView(label: "Sounds",
                       secondLabel: "Play sounds",
                       state: $preferences.captureSound,
                       width: width)

            ToggleView(label: "Menu bar", secondLabel: "Show icon",
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
                HStack {
                    EnumPicker(selected: $preferences.recongitionLanguage, title: "")
                }
            }
        }
        .padding(20)
        .frame(width: 350, height: preferences.showMenuBarIcon ? 200 : 110)
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

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Shortcuts")) {
                HStack {
                    Text("Capture text:")
                    KeyboardShortcuts.Recorder(for: .captureText)
                }
            }
            Spacer()
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}

struct AutomationSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    let width: CGFloat = 80
    var body: some View {
        Form {
            ToggleView(label: "Open URLs", secondLabel: "Detected in Text", state: $preferences.autoOpenCapturedURL, width: width)
            ToggleView(label: "", secondLabel: "From QR Code", state: $preferences.autoOpenCapturedURL, width: width)

            Divider()

            HStack {
                HStack {
                    Spacer()
                    Text("Trigger URL Scheme:")
                }.frame(width: width)
                TextField("URL to Open", text: $preferences.autoOpenProvidedURL)
            }

            HStack {
                HStack {
                    Spacer()
                    Text("")
                }.frame(width: width)
                Text("{text} variable contains captured text")
                    .font(.footnote)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 350, height: 200)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack {
            HStack {
                Image("mac_256")
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 90, height: 90, alignment: .leading)

                VStack(alignment: .leading) {
                    Text("TRex")
                        .font(.title3)
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                        .font(.subheadline)
                    Text("Copyright ©2021 Ameba Labs. All rights reserved.")
                        .font(.footnote)
                        .padding(.top, 10)
                }
            }
            Spacer()
            Divider()
            HStack {
                Spacer()
                Button("Visit our Website", action: {
                    NSWorkspace.shared.open(URL(string: "https://ameba.co")!)
                })
                Button("Contact Us", action: {
                    NSWorkspace.shared.open(URL(string: "mailto:info@ameba.co")!)
                })
            }.padding(.top, 10)
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 120)
    }
}

struct ToggleView: View {
    let label: String
    let secondLabel: String
    @Binding var state: Bool
    let width: CGFloat

    var mainLabel: String {
        guard !label.isEmpty else {return ""}
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
        }
    }
}
