import SwiftUI
import KeyboardShortcuts
import TRexCore

struct SetupView: View {
    @StateObject private var vm = SetupViewModel()
    @EnvironmentObject var preferences: Preferences
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: OnboardingDimensions.sectionSpacing) {
            Text("Quick Setup")
                .font(.system(size: 42, weight: .bold))
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(Animation.brandEaseOut, value: animateContent)
            
            // Section tabs
            HStack(spacing: 30) {
                ForEach(SetupSection.allCases, id: \.self) { section in
                    SetupTab(section: section, isActive: vm.activeSection == section)
                        .onTapGesture { vm.switchToSection(section) }
                }
            }
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(Animation.brandEaseOut(delay: 0.1), value: animateContent)
            
            // Content area
            ScrollView {
                ZStack {
                    switch vm.activeSection {
                    case .permissions:
                        PermissionsSection(vm: vm)
                            .transition(AnyTransition.slideFade)
                    case .settings:
                        SettingsSection(preferences: preferences, launchAtLogin: launchAtLogin.isEnabled)
                            .transition(AnyTransition.slideFade)
                    case .language:
                        LanguageSection(selectedLanguageCode: $vm.selectedLanguageCode, preferences: preferences, availableLanguages: vm.availableLanguages)
                            .transition(AnyTransition.slideFade)
                    }
                }
            }
            .frame(height: 350)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(Animation.brandEaseOut(delay: 0.2), value: animateContent)
            
            Spacer()
        }
        .padding(OnboardingDimensions.contentPadding)
        .onAppear {
            animateContent = true
            preferences.recognitionLanguageCode = vm.selectedLanguageCode
        }
        .onChange(of: vm.selectedLanguageCode) { newValue in
            preferences.recognitionLanguageCode = newValue
        }
    }
}