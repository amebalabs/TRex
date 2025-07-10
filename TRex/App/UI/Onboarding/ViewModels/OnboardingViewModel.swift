import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage: OnboardingPage = .welcome
    @Published var showContent = false
    
    var isLastPage: Bool {
        currentPage == OnboardingPage.allCases.last
    }
    
    func nextPage() {
        guard let currentIndex = OnboardingPage.allCases.firstIndex(of: currentPage),
              currentIndex < OnboardingPage.allCases.count - 1 else { return }
        
        withAnimation(Animation.brandSpring) {
            currentPage = OnboardingPage.allCases[currentIndex + 1]
        }
    }
    
    func previousPage() {
        guard let currentIndex = OnboardingPage.allCases.firstIndex(of: currentPage),
              currentIndex > 0 else { return }
        
        withAnimation(Animation.brandSpring) {
            currentPage = OnboardingPage.allCases[currentIndex - 1]
        }
    }
    
    func goToPage(_ page: OnboardingPage) {
        withAnimation(Animation.brandSpring) {
            currentPage = page
        }
    }
    
    func completeOnboarding() {
        NotificationCenter.default.post(name: .closeOnboarding, object: nil)
    }
}