import Foundation
import SwiftUI
import CoreGraphics
import TRexCore

@MainActor
class SetupViewModel: ObservableObject {
    @Published var activeSection: SetupSection = .permissions
    @Published var screenRecordingPermission = false
    @Published var selectedLanguageCode: String
    @Published var availableLanguages: [LanguageManager.Language] = []
    
    private var permissionTimer: Timer?
    
    init() {
        self.selectedLanguageCode = Preferences.shared.recognitionLanguageCode
        loadAvailableLanguages()
        checkScreenRecordingPermission()
    }
    
    private func loadAvailableLanguages() {
        let manager = LanguageManager.shared
        let allLanguages = manager.availableLanguages()
        // Filter to only Vision-supported languages for onboarding
        availableLanguages = allLanguages
            .filter { $0.source == .vision || $0.source == .both }
            .sorted { $0.displayName < $1.displayName }
    }
    
    deinit {
        permissionTimer?.invalidate()
    }
    
    func switchToSection(_ section: SetupSection) {
        withAnimation(Animation.brandSpring) {
            activeSection = section
        }
        
        if section == .permissions {
            startPermissionMonitoring()
        } else {
            stopPermissionMonitoring()
        }
    }
    
    func checkScreenRecordingPermission() {
        screenRecordingPermission = CGPreflightScreenCaptureAccess()
        
        if activeSection == .permissions, !screenRecordingPermission {
            startPermissionMonitoring()
        } else {
            stopPermissionMonitoring()
        }
    }
    
    func openSystemPreferences() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func startPermissionMonitoring() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let newStatus = CGPreflightScreenCaptureAccess()
            Task { @MainActor in
                guard let self else { return }
                if newStatus != self.screenRecordingPermission {
                    withAnimation(Animation.brandSpring) {
                        self.screenRecordingPermission = newStatus
                    }
                }
                if newStatus {
                    self.stopPermissionMonitoring()
                }
            }
        }
    }
    
    func stopPermissionMonitoring() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }
}
