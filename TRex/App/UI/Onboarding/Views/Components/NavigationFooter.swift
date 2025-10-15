import SwiftUI

struct NavigationFooter: View {
    @ObservedObject var vm: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.2)
            
            ZStack {
                Color.gray.opacity(0.05)
                
                HStack {
                    // Page indicators
                    HStack(spacing: 10) {
                        ForEach(OnboardingPage.allCases, id: \.self) { page in
                            Circle()
                                .fill(vm.currentPage == page ? Color.brandBlue : Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .scaleEffect(vm.currentPage == page ? 1.2 : 1.0)
                                .animation(Animation.brandSpring, value: vm.currentPage)
                                .onTapGesture {
                                    vm.goToPage(page)
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if vm.currentPage != .welcome {
                            Button(action: vm.previousPage) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                        
                        Button(action: {
                            if vm.isLastPage {
                                vm.completeOnboarding()
                            } else {
                                vm.nextPage()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(vm.isLastPage ? "Get Started" : "Continue")
                                    .fontWeight(.semibold)
                                Image(systemName: vm.isLastPage ? "arrow.right.circle.fill" : "chevron.right")
                            }
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: vm.isLastPage ? [.green, .blue] : Color.brandGradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(vm.isLastPage ? 1.05 : 1.0)
                        .animation(Animation.brandSpring, value: vm.isLastPage)
                    }
                }
                .padding(.horizontal, OnboardingDimensions.contentPadding)
            }
            .frame(height: OnboardingDimensions.footerHeight)
        }
    }
}