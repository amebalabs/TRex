import SwiftUI
import TRexCore

struct AboutSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    
    var body: some View {
        VStack {
            HStack {
                Image("mac_256")
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 90, height: 90, alignment: .leading)

                VStack(alignment: .leading) {
                    Text("TRex")
                        .font(.title3)
                        .bold()
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                        .font(.subheadline)
                    Text("Copyright ©2025 Ameba Labs. All rights reserved.")
                        .font(.footnote)
                        .padding(.top, 10)
                }
            }
            Spacer()
            Divider()
            HStack {
                Spacer()
                Button("Visit our Website", action: {
                    NSWorkspace.shared.open(URL(string: "https://ameba.co")!)
                })
                Button("Contact Us", action: {
                    NSWorkspace.shared.open(URL(string: "mailto:info@ameba.co")!)
                })
            }.padding(.top, 10)
                .padding(.bottom, 20)
        }
        .frame(width: 500, height: 120)
    }
}
