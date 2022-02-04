import SwiftUI

struct PagerView<Content: View>: View {
    let pageCount: Int
    @Binding var currentIndex: Int
    let content: Content

    @GestureState private var translation: CGFloat = 0

    init(pageCount: Int, currentIndex: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.pageCount = pageCount
        _currentIndex = currentIndex
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack(alignment: .bottomLeading) {
                    HStack(spacing: 0) {
                        self.content.frame(width: geometry.size.width)
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    .offset(x: -CGFloat(self.currentIndex) * geometry.size.width)
                    .offset(x: self.translation)
                    .animation(.easeIn(duration: currentIndex == 0 ? 0 : 0.1))
                }
                HStack {
                    HStack {
                        ForEach(0 ..< self.pageCount, id: \.self) { index in
                            Circle()
                                .fill(index == self.currentIndex ? Color.orange : Color.gray)
                                .frame(width: 8, height: 8)
                                .onTapGesture {
                                    self.currentIndex = index
                                }
                        }
                    }.padding()
                    Spacer()
                    Button(currentIndex == pageCount - 1 ? "Let's Go!" : "Continue", action: {
                        guard currentIndex != pageCount - 1 else {
                            NotificationCenter.default.post(name: .closeOnboarding, object: nil)
                            return
                        }
                        self.currentIndex = min(max(Int(self.currentIndex + 1), 0), self.pageCount - 1)
                    }).padding()
                }
            }
        }
    }
}
