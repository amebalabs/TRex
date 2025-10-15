import SwiftUI

struct FeatureCard: View {
    let feature: Feature
    let isHovered: Bool
    let animateContent: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(feature.tint.opacity(0.1))
                    .frame(width: OnboardingDimensions.featureIconSize, height: OnboardingDimensions.featureIconSize)
                
                Image(systemName: feature.sfSymbol)
                    .font(.system(size: 28))
                    .foregroundColor(feature.tint)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(20)
        .onboardingCard(isHovered: isHovered)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(x: animateContent ? 0 : 50)
        .animation(Animation.brandEaseOut(delay: delay), value: animateContent)
    }
}