import SwiftUI

extension Animation {
    static let brandSpring = spring(response: 0.6, dampingFraction: 0.8)
    static let brandEaseOut = easeOut(duration: 0.6)
    static let confettiSpring = spring(response: 0.8, dampingFraction: 0.6)
    
    static func brandEaseOut(delay: TimeInterval) -> Animation {
        easeOut(duration: 0.6).delay(delay)
    }
    
    static func brandSpring(delay: TimeInterval) -> Animation {
        spring(response: 0.6, dampingFraction: 0.8).delay(delay)
    }
}