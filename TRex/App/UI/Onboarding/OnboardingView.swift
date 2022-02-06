import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI
import TRexCore

struct OnboardingView: View {
    @State private var currentPage = 0
    var body: some View {
        PagerView(pageCount: 3, currentIndex: $currentPage) {
            WelcomeView()
            ShortcutView().environmentObject(Preferences.shared)
            FinishView()
        }.frame(width: 400, height: 400)
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack {
            Image("mac_256")
                .resizable()
                .renderingMode(.original)
                .frame(width: 160, height: 160, alignment: .leading)
            Text("Welcome to \nTRex")
                .multilineTextAlignment(.center)
                .font(.system(size: 50))
            Spacer()
            Text("Easy to use text recognition")
                .font(.title3)
            Spacer()
                .frame(height: 20)
        }
    }
}

struct ShortcutView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    let width: CGFloat = 100

    var body: some View {
        Form {
            Text("Preferences")
                .font(.title)

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
            Divider()
            Spacer()
            Text("Shortcuts")
                .font(.title)
            HStack {
                Text("Capture from Screen:     ")
                KeyboardShortcuts.Recorder(for: .captureScreen)
            }
            HStack {
                Text("Capture from Clipboard:")
                KeyboardShortcuts.Recorder(for: .captureClipboard)
            }
        }.padding(40)
    }
}

struct FinishView: View {
    var body: some View {
        VStack {
            Text("All Set!")
                .font(.system(size: 50))
            Text("Enjoy using the easiest text extraction tool")
                .font(.title3)
                .padding()
            Text("🦖🦖🦖")
                .font(.system(size: 50))
            Spacer()
                .frame(height: 100)
        }
    }
}
