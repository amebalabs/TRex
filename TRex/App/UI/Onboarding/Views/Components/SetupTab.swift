import SwiftUI

struct SetupTab: View {
    let section: SetupSection
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: section.icon)
                .font(.system(size: 32))
                .foregroundColor(isActive ? Color.brandBlue : .secondary)
            
            Text(section.title)
                .font(.headline)
                .foregroundColor(isActive ? .primary : .secondary)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.brandBlue)
                .frame(height: 3)
                .opacity(isActive ? 1 : 0)
                .scaleEffect(x: isActive ? 1 : 0.5, y: 1, anchor: .center)
                .animation(Animation.brandSpring, value: isActive)
        }
        .frame(width: 120)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(Animation.brandSpring, value: isActive)
    }
}