import SwiftUI

struct AutomationSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    let width: CGFloat = 80
    var body: some View {
        VStack {
            ToggleView(label: "Open URLs", secondLabel: "Detected in Text",
                       state: $preferences.autoOpenCapturedURL,
                       width: width)
            ToggleView(label: "", secondLabel: "From QR Code",
                       state: $preferences.autoOpenQRCodeURL,
                       width: width)
            
            Divider()
            
            HStack {
                Text("Trigger URL Scheme:")
                TextField("{text} variable contains captured text", text: $preferences.autoOpenProvidedURL)
            }
           
            ToggleView(label: "", secondLabel: "Append New Line",
                       state: $preferences.autoOpenProvidedURLAddNewLine,
                       width: 129)
            Spacer()
        }.padding(20)
            .frame(width: 450, height: 120)
    }
}
