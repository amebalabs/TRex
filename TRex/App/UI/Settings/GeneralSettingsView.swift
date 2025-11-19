import SwiftUI
import TRexCore
import CryptoKit

struct GeneralSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @EnvironmentObject var appDelegate: AppDelegate
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @State private var visionLanguages: [LanguageManager.Language] = []

    let width: CGFloat = 90
    
    var body: some View {
        Form {
            ToggleView(label: "Startup", secondLabel: "Start at Login",
                       state: $launchAtLogin.isEnabled,
                       width: width)

            ToggleView(label: "Sounds",
                       secondLabel: "Play Sounds",
                       state: $preferences.captureSound,
                       width: width)
            ToggleView(label: "Notifications",
                       secondLabel: "Show Recognized Text",
                       state: $preferences.resultNotification,
                       width: width)
            ToggleView(label: "Menu Bar", secondLabel: "Show Icon",
                       state: $preferences.showMenuBarIcon,
                       width: width)

            if preferences.showMenuBarIcon {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(NSColor.controlBackgroundColor))
                    HStack {
                        ForEach(Preferences.MenuBarIcon.allCases, id: \.self) { item in
                            MenuBarIconView(item: item, selected: $preferences.menuBarIcon).onTapGesture {
                                preferences.menuBarIcon = item
                            }
                        }
                    }
                }.frame(height: 70)
                    .padding([.leading, .trailing], 10)
            }

            // Only show Recognition Language section when using Apple Vision (not Tesseract)
            if !preferences.tesseractEnabled {
                Section(header: Text("Recognition Language")) {
                    if #available(OSX 13.0, *) {
                        HStack {
                            ToggleView(label: "", secondLabel: "Automatic",
                                       state: $preferences.automaticLanguageDetection,
                                       width: 0)
                            Picker(selection: $preferences.recognitionLanguageCode, label: Text("")) {
                                ForEach(visionLanguages, id: \.code) { language in
                                    Text(language.displayNameWithFlag)
                                        .tag(language.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .disabled(preferences.automaticLanguageDetection)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor.withAlphaComponent(0.3)), lineWidth: 0.5)
                            )
                            Spacer()
                        }
                    } else {
                        Picker(selection: $preferences.recognitionLanguageCode, label: Text("")) {
                            ForEach(visionLanguages, id: \.code) { language in
                                Text(language.displayNameWithFlag)
                                    .tag(language.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .labelsHidden()
                        .disabled(preferences.automaticLanguageDetection)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor.withAlphaComponent(0.3)), lineWidth: 0.5)
                        )
                    }
                    Text("More languages are available in the Tesseract menu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } else {
                // When Tesseract is enabled, show a note about language configuration
                Section(header: Text("Language Settings")) {
                    Text("Language configuration is available in the Tesseract settings tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()

            #if !MAC_APP_STORE
            Divider()

            // CLI Installation
            Section(header: Text("Command Line Tool")) {
                CLIInstallRow()
            }

            Divider()
            Section(header: Text("Updates")) {
                HStack {
                    Button("Check for Updates", action: {
                        checkForUpdates()
                    })
                    Spacer()
                    Toggle("Include beta updates", isOn: $preferences.includeBetaUpdates)
                        .toggleStyle(.checkbox)
                }
            }
            #endif
        }
        .padding(20)
        #if MAC_APP_STORE
        .frame(width: 500, height: preferences.showMenuBarIcon ? (preferences.tesseractEnabled ? 220 : 280) : (preferences.tesseractEnabled ? 140 : 200))
        #else
        .frame(width: 500, height: preferences.showMenuBarIcon ? (preferences.tesseractEnabled ? 300 : 360) : (preferences.tesseractEnabled ? 220 : 280))
        #endif
        .onAppear {
            loadVisionLanguages()
        }
    }
    
    private func loadVisionLanguages() {
        let manager = LanguageManager.shared
        let allLanguages = manager.availableLanguages()
        // Filter to only Vision-supported languages
        visionLanguages = allLanguages
            .filter { $0.source == .vision || $0.source == .both }
            .sorted { $0.displayName < $1.displayName }
    }
    
    #if !MAC_APP_STORE
    func checkForUpdates() {
        guard let updater = appDelegate.softwareUpdater else {
            return
        }
        updater.checkForUpdates()
    }
    #endif
}

struct MenuBarIconView: View {
    let item: Preferences.MenuBarIcon
    @Binding var selected: Preferences.MenuBarIcon
    var isSelected: Bool {
        selected == item
    }

    var body: some View {
        VStack(spacing: 2) {
            item.image()
                .resizable()
                .accentColor(isSelected ? .blue : .white)
                .frame(width: 30, height: 30, alignment: .center)
                .padding(3)
                .border(isSelected ? Color.blue : Color.clear, width: 2)
            Circle()
                .fill(isSelected ? Color.blue : Color.gray)
                .frame(width: 8, height: 8)
                .padding([.top], 5)
        }
    }
}

struct ToggleView: View {
    let label: String
    let secondLabel: String
    @Binding var state: Bool
    let width: CGFloat

    var mainLabel: String {
        guard !label.isEmpty else { return "" }
        return "\(label):"
    }

    var body: some View {
        HStack {
            HStack {
                Spacer()
                Text(mainLabel)
            }.frame(width: width)
            Toggle("", isOn: $state)
            Text(secondLabel)
            Spacer()
        }
    }
}

struct CLIInstallRow: View {
    @State private var isCLIInstalled = false
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var errorMessage: String?

    // Install to user's local bin directory (no admin required)
    private let installPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".local/bin/trex")
        .path

    var body: some View {
        HStack {
            if isDownloading {
                ProgressView(value: downloadProgress, total: 1.0)
                    .frame(width: 80)
                Text("\(Int(downloadProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if isCLIInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TRex CLI installed")
                        .font(.body)
                    Text(installPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button("Install TRex CLI") {
                    installCLI()
                }
            }

            Spacer()

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
        }
        .onAppear {
            checkCLIInstallation()
        }
    }

    private func checkCLIInstallation() {
        isCLIInstalled = FileManager.default.fileExists(atPath: installPath)
    }

    private func installCLI() {
        isDownloading = true
        errorMessage = nil
        downloadProgress = 0

        Task {
            do {
                try await downloadAndInstallCLI()
                await MainActor.run {
                    isCLIInstalled = true
                    isDownloading = false
                }
            } catch {
                // Log full error to console for debugging
                print("CLI Installation Error: \(error)")
                if let localizedError = error as? LocalizedError {
                    print("Error Description: \(localizedError.errorDescription ?? "None")")
                    print("Failure Reason: \(localizedError.failureReason ?? "None")")
                    print("Recovery Suggestion: \(localizedError.recoverySuggestion ?? "None")")
                }

                await MainActor.run {
                    errorMessage = "Failed: \(error.localizedDescription)"
                    isDownloading = false
                }
            }
        }
    }

    private func findReleaseWithCLI() async throws -> GitHubRelease {
        // Get current app version
        guard let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            throw CLIInstallError.cannotDetermineAppVersion
        }

        // Fetch all releases to find matching version
        let allReleasesURL = URL(string: "https://api.github.com/repos/amebalabs/TRex/releases")!
        let (allData, _) = try await URLSession.shared.data(from: allReleasesURL)
        let allReleases = try JSONDecoder().decode([GitHubRelease].self, from: allData)

        // Find release matching current app version
        guard let matchingRelease = allReleases.first(where: { release in
            // Tag format is v1.8.0 or v1.9.1-BETA-2
            let tag = release.tagName
            // Strip 'v' prefix and compare
            let versionString = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            return versionString == appVersion
        }) else {
            throw CLIInstallError.noMatchingRelease(version: appVersion)
        }

        // Verify the release has CLI assets
        guard matchingRelease.assets.contains(where: { $0.name == "trex" }) else {
            throw CLIInstallError.noCliInRelease(version: appVersion)
        }

        return matchingRelease
    }

    private func downloadAndInstallCLI() async throws {
        // Find appropriate release with CLI assets
        let release = try await findReleaseWithCLI()

        // Find CLI asset and checksum
        guard let cliAsset = release.assets.first(where: { $0.name == "trex" }) else {
            throw CLIInstallError.assetNotFound
        }

        guard let checksumAsset = release.assets.first(where: { $0.name == "trex.sha256" }) else {
            throw CLIInstallError.checksumNotFound
        }

        await MainActor.run { downloadProgress = 0.2 }

        // Download checksum file
        let (checksumData, _) = try await URLSession.shared.data(from: URL(string: checksumAsset.browserDownloadURL)!)
        let checksumString = String(data: checksumData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let expectedChecksum = checksumString.components(separatedBy: " ").first ?? ""

        guard !expectedChecksum.isEmpty else {
            throw CLIInstallError.invalidChecksum
        }

        await MainActor.run { downloadProgress = 0.4 }

        // Download CLI binary
        let (binaryData, _) = try await URLSession.shared.data(from: URL(string: cliAsset.browserDownloadURL)!)

        await MainActor.run { downloadProgress = 0.6 }

        // Verify checksum
        let computedChecksum = SHA256.hash(data: binaryData)
        let computedChecksumString = computedChecksum.compactMap { String(format: "%02x", $0) }.joined()

        guard computedChecksumString == expectedChecksum else {
            throw CLIInstallError.checksumMismatch
        }

        await MainActor.run { downloadProgress = 0.8 }

        // Create a uniquely named temp file to avoid conflicts
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueFilename = "trex-\(UUID().uuidString)"
        let tempURL = tempDir.appendingPathComponent(uniqueFilename)

        // Ensure cleanup
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // Write binary to temp location
        try binaryData.write(to: tempURL, options: .atomic)

        // Verify file exists before trying to install
        guard FileManager.default.fileExists(atPath: tempURL.path) else {
            throw CLIInstallError.installationFailed("Failed to write temporary file")
        }

        // Create ~/.local/bin directory if it doesn't exist
        let installURL = URL(fileURLWithPath: installPath)
        let binDir = installURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true, attributes: nil)

        // Copy binary to install location
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: installPath) {
            try FileManager.default.removeItem(atPath: installPath)
        }

        try FileManager.default.copyItem(at: tempURL, to: installURL)

        // Make executable (chmod +x)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installPath)

        // Verify installation succeeded
        guard FileManager.default.fileExists(atPath: installPath) else {
            throw CLIInstallError.installationFailed("Installation did not complete")
        }

        await MainActor.run { downloadProgress = 1.0 }
    }
}

enum CLIInstallError: LocalizedError {
    case assetNotFound
    case checksumNotFound
    case invalidChecksum
    case checksumMismatch
    case installationFailed(String)
    case cannotDetermineAppVersion
    case noMatchingRelease(version: String)
    case noCliInRelease(version: String)
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .assetNotFound:
            return "CLI binary not found in release"
        case .checksumNotFound:
            return "Checksum file not found in release"
        case .invalidChecksum:
            return "Invalid checksum format"
        case .checksumMismatch:
            return "Security verification failed: Binary checksum mismatch"
        case .installationFailed(let details):
            return "Installation failed: \(details)"
        case .cannotDetermineAppVersion:
            return "Cannot determine app version"
        case .noMatchingRelease(let version):
            return "No release found for version \(version)"
        case .noCliInRelease(let version):
            return "Version \(version) doesn't include CLI. Please check for app updates."
        case .userCancelled:
            return "Installation cancelled by user"
        }
    }
}

struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}
