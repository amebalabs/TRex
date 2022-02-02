import SwiftUI

struct AboutSettingsView: View {
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
                    Text("Copyright ©2022 Ameba Labs. All rights reserved.")
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
        .frame(width: 410, height: 120)
    }
}
