import SwiftUI
import KeyboardShortcuts
import TRexCore

struct SettingsSection: View {
    let preferences: Preferences
    let launchAtLogin: Bool
    @ObservedObject private var launchAtLoginObservable = LaunchAtLogin.observable
    
    var body: some View {
        VStack(spacing: 30) {
            // Keyboard Shortcuts
            VStack(spacing: 20) {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 18) {
                    ShortcutRow(
                        icon: "camera.viewfinder",
                        title: "Capture from Screen",
                        shortcut: .captureScreen
                    )
                    
                    ShortcutRow(
                        icon: "doc.on.clipboard",
                        title: "Capture from Clipboard",
                        shortcut: .captureClipboard
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }
            
            // Preferences
            VStack(spacing: 20) {
                Text("Preferences")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 0) {
                    PreferenceToggle(
                        icon: "power",
                        title: "Start at Login",
                        isOn: $launchAtLoginObservable.isEnabled
                    )
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    PreferenceToggle(
                        icon: "speaker.wave.2",
                        title: "Capture Sound",
                        isOn: .init(
                            get: { preferences.captureSound },
                            set: { preferences.captureSound = $0 }
                        )
                    )
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    PreferenceToggle(
                        icon: "bell",
                        title: "Show Notifications",
                        isOn: .init(
                            get: { preferences.resultNotification },
                            set: { preferences.resultNotification = $0 }
                        )
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }
}

struct ShortcutRow: View {
    let icon: String
    let title: String
    let shortcut: KeyboardShortcuts.Name
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color.brandBlue)
                .frame(width: 40)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 200, alignment: .leading)
            
            KeyboardShortcuts.Recorder(for: shortcut)
                .scaleEffect(1.1)
        }
    }
}

struct PreferenceToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isOn ? Color.brandBlue : .secondary)
                .frame(width: 32)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(ModernToggleStyle())
                .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(isHovered ? Color.gray.opacity(0.05) : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}