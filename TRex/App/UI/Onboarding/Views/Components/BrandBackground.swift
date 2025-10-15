import SwiftUI

struct BrandBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: Color.brandBackgroundGradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}