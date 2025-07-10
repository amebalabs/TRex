import SwiftUI
import TRexCore

#if DEBUG
struct OnboardingPreview: View {
    var body: some View {
        OnboardingView()
            .environmentObject(Preferences.shared)
    }
}

#Preview("Onboarding") {
    OnboardingPreview()
}
#endif