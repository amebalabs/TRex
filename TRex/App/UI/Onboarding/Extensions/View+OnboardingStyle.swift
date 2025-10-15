import SwiftUI

struct OnboardingDimensions {
    static let windowWidth: CGFloat = 1000
    static let windowHeight: CGFloat = 800
    static let titleBarHeight: CGFloat = 28
    static let footerHeight: CGFloat = 100
    static let contentPadding: CGFloat = 50
    static let sectionSpacing: CGFloat = 40
    static let featureIconSize: CGFloat = 60
    static let logoSize: CGFloat = 180
}

extension View {
    func onboardingCard(isHovered: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(isHovered ? 0.08 : 0.05))
                    .shadow(color: .black.opacity(isHovered ? 0.1 : 0), radius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(isHovered ? 0.3 : 0.1), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.01 : 1.0)
    }
    
    func fadeInAnimation(delay: TimeInterval = 0) -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(Animation.brandEaseOut(delay: delay)) {
                    self.opacity(1)
                }
            }
    }
}