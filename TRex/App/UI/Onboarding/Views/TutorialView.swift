import SwiftUI
import Quartz

struct TutorialView: View {
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 25) {
                Spacer()
                VStack(spacing: 15) {
                    Text("See TRex in Action")
                        .font(.system(size: 36, weight: .bold))
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(Animation.brandEaseOut(delay: 0.1), value: animateContent)
                    
                    Text("Watch how easy it is to capture text from anywhere on your screen")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 600)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(Animation.brandEaseOut(delay: 0.2), value: animateContent)
                }
                Spacer()
                
                HStack(spacing: 30) {
                    VStack(spacing: 20) {
                        Text("Step 1: Select area")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        QLImage("step2")
                            .frame(width: 350, height: 250)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        
                        Text("Use your keyboard shortcut to\nselect the text area")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(Animation.brandEaseOut(delay: 0.3), value: animateContent)
                    
                    VStack(spacing: 20) {
                        Text("Step 2: Text captured!")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        QLImage("step3")
                            .frame(width: 350, height: 250)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        
                        Text("Text is instantly copied\nto your clipboard")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(Animation.brandEaseOut(delay: 0.4), value: animateContent)
                }
                Spacer()
            }
            
            Spacer()
        }
        .padding(.horizontal, OnboardingDimensions.contentPadding)
        .onAppear {
            animateContent = true
        }
    }
}

