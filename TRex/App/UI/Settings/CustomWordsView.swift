import SwiftUI
import TRexCore

struct CustomWordsView: View {
    @EnvironmentObject var preferences: Preferences
    var body: some View {
        Form {
            ZStack(alignment: .top) {
                if preferences.customWords.isEmpty {
                    HStack {
                        Text(" Add custom words separated by comma")
                        Spacer()
                    }
                }
                TextEditor(text: $preferences.customWords)
                    .cornerRadius(5)
                    .opacity(preferences.customWords.isEmpty ? 0.30 : 1)
            }
            Text("You can improve text recognition by providing a list of words that are special to your text.")
                .font(.footnote)
        }
        .frame(width: 410, height: 160)
    }
}
