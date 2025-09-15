import SwiftUI
import TRexCore

struct LanguageSection: View {
    @Binding var selectedLanguageCode: String
    let preferences: Preferences
    let availableLanguages: [LanguageManager.Language]
    
    var body: some View {
        VStack(spacing: 25) {
            LanguageGrid(selectedLanguageCode: $selectedLanguageCode, availableLanguages: availableLanguages)
            
            VStack(spacing: 20) {
                Toggle("Enable automatic language detection", isOn: .init(
                    get: { preferences.automaticLanguageDetection },
                    set: { preferences.automaticLanguageDetection = $0 }
                ))
                .toggleStyle(ModernToggleStyle())
                .padding(.horizontal, 100)
                
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Additional languages are available in the app settings after setup")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 50)
            }
        }
    }
}

struct LanguageGrid: View {
    @Binding var selectedLanguageCode: String
    let availableLanguages: [LanguageManager.Language]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(availableLanguages, id: \.code) { language in
                LanguageGridItem(
                    language: language,
                    isSelected: selectedLanguageCode == language.code,
                    action: {
                        withAnimation(Animation.brandSpring) {
                            selectedLanguageCode = language.code
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 50)
    }
}

struct LanguageGridItem: View {
    let language: LanguageManager.Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.displayNameWithFlag)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .transition(AnyTransition.scaleOpacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                        LinearGradient(colors: Color.brandGradientColors, startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandBlue : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}