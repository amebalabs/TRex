import SwiftUI

struct PagerView<Content: View>: View {
    let pageCount: Int
    @Binding var currentIndex: Int
    let content: Content
    
    @GestureState private var translation: CGFloat = 0
    @State private var animatePageIndicators = false
    
    init(pageCount: Int, currentIndex: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.pageCount = pageCount
        _currentIndex = currentIndex
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Content area - takes up most of the space
                ZStack(alignment: .bottom) {
                    HStack(spacing: 0) {
                        self.content
                            .frame(width: geometry.size.width)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    .offset(x: -CGFloat(self.currentIndex) * geometry.size.width)
                    .offset(x: self.translation)
                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.95, blendDuration: 0), value: currentIndex)
                    .gesture(
                        DragGesture()
                            .updating(self.$translation) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                let offset = value.translation.width / geometry.size.width
                                let newIndex = Int((CGFloat(self.currentIndex) - offset).rounded())
                                self.currentIndex = max(0, min(newIndex, self.pageCount - 1))
                            }
                    )
                }
                .frame(height: geometry.size.height - 100) // Leave space for navigation
                
                // Navigation controls
                VStack(spacing: 15) {
                    HStack(spacing: 8) {
                        ForEach(0 ..< self.pageCount, id: \.self) { index in
                            Capsule()
                                .fill(index == self.currentIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: index == self.currentIndex ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentIndex)
                                .scaleEffect(animatePageIndicators ? 1.0 : 0.5)
                                .opacity(animatePageIndicators ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: animatePageIndicators)
                                .onTapGesture {
                                    withAnimation {
                                        self.currentIndex = index
                                    }
                                }
                        }
                    }
                    
                    HStack(spacing: 20) {
                        if currentIndex > 0 {
                            Button(action: {
                                withAnimation {
                                    self.currentIndex = max(0, self.currentIndex - 1)
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentIndex == pageCount - 1 {
                                NotificationCenter.default.post(name: .closeOnboarding, object: nil)
                            } else {
                                withAnimation {
                                    self.currentIndex = min(self.currentIndex + 1, self.pageCount - 1)
                                }
                            }
                        }) {
                            HStack(spacing: 5) {
                                Text(currentIndex == pageCount - 1 ? "Get Started" : "Continue")
                                    .fontWeight(.medium)
                                Image(systemName: currentIndex == pageCount - 1 ? "checkmark.circle.fill" : "chevron.right")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.vertical, 15)
                .frame(height: 100)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .onAppear {
            animatePageIndicators = true
        }
    }
}
