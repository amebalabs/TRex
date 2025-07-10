import Foundation

enum SetupSection: Int, CaseIterable {
    case permissions
    case settings
    case language
    
    var icon: String {
        switch self {
        case .permissions:
            return "shield.checkered"
        case .settings:
            return "keyboard"
        case .language:
            return "globe"
        }
    }
    
    var title: String {
        switch self {
        case .permissions:
            return "Permissions"
        case .settings:
            return "Settings"
        case .language:
            return "Language"
        }
    }
}