import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

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
            Text("🦖\nWelcome to \nTRex")
                .multilineTextAlignment(.center)
                .font(.system(size: 50))
            Text("Easy to use text recognition.")
                .font(.title3)
            Spacer()
                .frame(height: 100)
        }
    }
}

struct ShortcutView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    let width: CGFloat = 70
    
    var body: some View {
        Form {
            
            Text("Preferences")
                .font(.title)
            
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
            
            Spacer()
            Text("Shortcut")
                .font(.title)
            HStack {
                Text("Capture text:")
                KeyboardShortcuts.Recorder(for: .captureText)
            }
            Spacer()
        }.padding()
    }
}


struct FinishView: View {
    var body: some View {
        VStack {
            Text("All Set!")
                .font(.system(size: 50))
            Text("Enjoy using the easiest text extraction tool.")
                .font(.title3)
                .padding()
            Text("🦖🦖🦖")
                .font(.title)
            Spacer()
                .frame(height: 100)
        }
    }
}
