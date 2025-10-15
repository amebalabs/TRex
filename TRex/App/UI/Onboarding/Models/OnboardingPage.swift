import Foundation

enum OnboardingPage: Int, CaseIterable {
    case welcome
    case setup
    case tutorial
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .setup:
            return "Quick Setup"
        case .tutorial:
            return "Let's Practice!"
        }
    }
}