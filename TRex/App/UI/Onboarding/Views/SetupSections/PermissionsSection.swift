import SwiftUI

struct PermissionsSection: View {
    @ObservedObject var vm: SetupViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: vm.screenRecordingPermission ? "checkmark.shield.fill" : "shield.slash")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: vm.screenRecordingPermission ? [.green, .blue] : [.blue, .gray],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .accessibilityLabel(vm.screenRecordingPermission ? "Screen recording enabled" : "Screen recording required")
            
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: vm.screenRecordingPermission ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(vm.screenRecordingPermission ? .green : .orange)
                    Text(vm.screenRecordingPermission ? "Screen Recording Enabled" : "Screen Recording Required")
                        .font(.title2.bold())
                }
                
                Text(vm.screenRecordingPermission ? "TRex has permission to capture text from your screen" : "TRex needs permission to capture text from your screen")
                    .foregroundColor(.secondary)
                
                if !vm.screenRecordingPermission {
                    Button(action: vm.openSystemPreferences) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Open System Preferences")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.brandBlue)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Grant permission to TRex in Privacy & Security settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 15) {
                PrivacyPoint(icon: "lock.fill", text: "Your privacy is protected", color: .green)
                PrivacyPoint(icon: "hand.raised.fill", text: "Only captures when you trigger", color: .blue)
                PrivacyPoint(icon: "externaldrive.fill", text: "No data stored or transmitted", color: .purple)
            }
        }
    }
}

struct PrivacyPoint: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 16))
        }
    }
}