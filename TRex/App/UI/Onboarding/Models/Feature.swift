import SwiftUI

struct Feature: Identifiable, Equatable {
    let id = UUID()
    let sfSymbol: String
    let title: String
    let subtitle: String
    let tint: Color
}

extension Feature {
    static let all: [Self] = [
        .init(
            sfSymbol: "text.viewfinder",
            title: "Smart Text Recognition",
            subtitle: "Extract text from any part of your screen with AI-powered accuracy",
            tint: .blue
        ),
        .init(
            sfSymbol: "qrcode.viewfinder",
            title: "QR & Barcode Scanner",
            subtitle: "Instantly decode QR codes and barcodes directly from your display",
            tint: .purple
        ),
        .init(
            sfSymbol: "globe.badge.chevron.backward",
            title: "Multi-Language Support",
            subtitle: "Recognize text in 100+ languages with automatic detection",
            tint: .green
        ),
        .init(
            sfSymbol: "bolt.horizontal.circle",
            title: "Lightning Fast",
            subtitle: "Native performance with instant results and zero lag",
            tint: .orange
        )
    ]
}
