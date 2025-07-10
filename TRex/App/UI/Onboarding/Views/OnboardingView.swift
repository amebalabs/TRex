import SwiftUI
import TRexCore

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            BrandBackground()
            
            VStack(spacing: 0) {
                // Title bar spacer
                Color.clear
                    .frame(height: OnboardingDimensions.titleBarHeight)
                
                // Main content area with fixed height
                ZStack {
                    switch vm.currentPage {
                    case .welcome:
                        WelcomeView()
                    case .setup:
                        SetupView()
                    case .tutorial:
                        TutorialView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(AnyTransition.slideFade)
                .animation(Animation.brandSpring, value: vm.currentPage)
                
                // Fixed footer
                NavigationFooter(vm: vm)
                    .frame(height: OnboardingDimensions.footerHeight)
            }
        }
        .frame(width: OnboardingDimensions.windowWidth, height: OnboardingDimensions.windowHeight)
        .onAppear {
            withAnimation(Animation.brandEaseOut) {
                vm.showContent = true
            }
        }
    }
}