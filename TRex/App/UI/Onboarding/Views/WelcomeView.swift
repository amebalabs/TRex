import SwiftUI

struct WelcomeView: View {
    @State private var animateContent = false
    @State private var hoveredFeature: Feature?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side - Welcome
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image("mac_256")
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: OnboardingDimensions.logoSize, height: OnboardingDimensions.logoSize)
                        .accessibilityLabel("TRex application icon")
                        .scaleEffect(animateContent ? 1.0 : 0.85)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .rotationEffect(.degrees(animateContent ? 0 : -5))
                        .animation(Animation.brandSpring, value: animateContent)
                        .clipped()
                    
                    VStack(spacing: 20) {
                        Text("Welcome to")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(Animation.brandEaseOut(delay: 0.2), value: animateContent)
                        
                        Text("TRex")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: Color.brandGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(Animation.brandEaseOut(delay: 0.3), value: animateContent)
                        
                        Text("Your intelligent OCR companion")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(Animation.brandEaseOut(delay: 0.4), value: animateContent)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 5) {
                        ForEach(0..<3) { i in
                            Text("🦖")
                                .font(.system(size: 32))
                                .opacity(animateContent ? 1.0 : 0.0)
                                .scaleEffect(animateContent ? 1.0 : 0.0)
                                .animation(
                                    Animation.brandSpring(delay: Double(i) * 0.1 + 0.8),
                                    value: animateContent
                                )
                        }
                    }
                    .accessibilityHidden(true)
                    .padding(.bottom, 40)
                }
                .frame(width: geometry.size.width * 0.3)
                .padding(40)
                
                Divider()
                    .opacity(0.2)
                
                // Right side - Features
                VStack(alignment: .leading, spacing: 25) {
                    Text("Powerful Features")
                        .font(.system(size: 32, weight: .bold))
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(Animation.brandEaseOut(delay: 0.5), value: animateContent)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            ForEach(Array(Feature.all.enumerated()), id: \.element.id) { index, feature in
                                FeatureCard(
                                    feature: feature,
                                    isHovered: hoveredFeature?.id == feature.id,
                                    animateContent: animateContent,
                                    delay: Double(index) * 0.1 + 0.6
                                )
                                .onHover { hovering in
                                    withAnimation(Animation.brandSpring) {
                                        hoveredFeature = hovering ? feature : nil
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 10)
                    }
                }
                .frame(width: geometry.size.width * 0.7)
                .padding(40)
            }
        }
        .onAppear {
            animateContent = true
        }
    }
}