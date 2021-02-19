import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var body: some View {
        PagerView(pageCount: 3, currentIndex: $currentPage) {
            WelcomeView()
            ShortcutView().environmentObject(Preferences.shared)
            Color.green
        }.frame(width: 400, height: 400)
    }
}

struct WelcomeView: View {
    var body: some View {
        ZStack {
            Color.green
            VStack {
                Image("trex")
                    .resizable()
                    .renderingMode(.template)
                    .accentColor(.white)
            }
        }
    }
}

struct ShortcutView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    let width: CGFloat = 70

    var body: some View {
        VStack {
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

            HStack {
                Text("Capture text:")
                KeyboardShortcuts.Recorder(for: .captureText)
            }
        }.padding()
    }
}
