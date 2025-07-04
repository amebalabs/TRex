import SwiftUI
import TRexCore
import KeyboardShortcuts

struct TesseractSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @State private var tesseractEngine = TesseractOCREngine()
    @State private var languageDownloader = TesseractLanguageDownloader.shared
    @State private var installedLanguages: [TesseractLanguageDownloader.LanguageInfo] = []
    @State private var selectedLanguages: Set<String> = []
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var downloadingLanguage: String? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Tesseract OCR Library").bold()) {
                Toggle("Enable Tesseract OCR", isOn: $preferences.tesseractEnabled)
                    .padding(.vertical, 2)
                Text("Enable, if you want to use Tesseract OCR instead of Apple Vision")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                Spacer()
            }
            
            if preferences.tesseractEnabled {
                Divider()
                
                Section(header: Text("Language Management").bold()) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(installedLanguages, id: \.code) { lang in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(lang.displayName)
                                            .font(.body)
                                        if let size = lang.fileSize {
                                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if lang.isInstalled {
                                        Toggle("", isOn: Binding(
                                            get: { selectedLanguages.contains(lang.code) },
                                            set: { isSelected in
                                                if isSelected {
                                                    selectedLanguages.insert(lang.code)
                                                } else {
                                                    selectedLanguages.remove(lang.code)
                                                }
                                                preferences.tesseractLanguages = Array(selectedLanguages)
                                            }
                                        ))
                                        .toggleStyle(SwitchToggleStyle())
                                        
                                        Button(action: {
                                            deleteLanguage(lang.code)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    } else {
                                        if isDownloading && downloadingLanguage == lang.code {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        } else {
                                            Button("Download") {
                                                downloadLanguage(lang.code)
                                            }
                                            .disabled(isDownloading)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 200)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    HStack {
                        if !selectedLanguages.isEmpty {
                            Text("Active: \(selectedLanguages.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        Spacer()
                        let totalSize = ByteCountFormatter.string(fromByteCount: languageDownloader.totalInstalledSize, countStyle: .file)
                        Text("Total Space Used:\(totalSize)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 550, height: 350)
        .onAppear {
            refreshLanguageList()
            selectedLanguages = Set(preferences.tesseractLanguages)
        }
    }
    
    private func refreshLanguageList() {
        installedLanguages = languageDownloader.getInstalledLanguages()
    }
    
    private func downloadLanguage(_ code: String) {
        isDownloading = true
        downloadingLanguage = code
        downloadProgress = 0
        
        languageDownloader.downloadLanguage(code, progress: { progress in
            DispatchQueue.main.async {
                self.downloadProgress = progress
            }
        }) { result in
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadingLanguage = nil
                
                switch result {
                case .success:
                    self.refreshLanguageList()
                case .failure(let error):
                    // Show error alert
                    let alert = NSAlert()
                    alert.messageText = "Download Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }
    
    private func deleteLanguage(_ code: String) {
        do {
            try languageDownloader.deleteLanguage(code)
            selectedLanguages.remove(code)
            preferences.tesseractLanguages = Array(selectedLanguages)
            refreshLanguageList()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Delete Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}
