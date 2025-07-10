import SwiftUI

extension AnyTransition {
    static let slideFade = asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    static let scaleOpacity = scale.combined(with: .opacity)
}