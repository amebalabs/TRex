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
    @State private var searchText = ""
    
    var filteredLanguages: [TesseractLanguageDownloader.LanguageInfo] {
        if searchText.isEmpty {
            return installedLanguages
        }
        return installedLanguages.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) || 
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var installedLanguagesFirst: [TesseractLanguageDownloader.LanguageInfo] {
        filteredLanguages.sorted { lhs, rhs in
            if lhs.isInstalled != rhs.isInstalled {
                return lhs.isInstalled
            }
            return lhs.name < rhs.name
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "text.viewfinder")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text("Tesseract OCR")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Toggle("", isOn: $preferences.tesseractEnabled)
                        .toggleStyle(SwitchToggleStyle())
                }
                
                Text("Enable for advanced language support beyond Apple Vision's 14 languages")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            if preferences.tesseractEnabled {
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                
                // Language Management Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Languages")
                            .font(.headline)
                        Spacer()
                        
                        // Search field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search languages...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .frame(width: 200)
                    }
                    
                    // Language List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(installedLanguagesFirst, id: \.code) { lang in
                                LanguageRow(
                                    language: lang,
                                    isSelected: selectedLanguages.contains(lang.code),
                                    isDownloading: isDownloading && downloadingLanguage == lang.code,
                                    downloadProgress: downloadProgress,
                                    onToggle: { isSelected in
                                        if isSelected {
                                            selectedLanguages.insert(lang.code)
                                        } else {
                                            selectedLanguages.remove(lang.code)
                                        }
                                        preferences.tesseractLanguages = Array(selectedLanguages)
                                    },
                                    onDownload: {
                                        downloadLanguage(lang.code)
                                    },
                                    onDelete: {
                                        deleteLanguage(lang.code)
                                    }
                                )
                                .disabled(isDownloading && downloadingLanguage != lang.code)
                                
                                if lang.code != installedLanguagesFirst.last?.code {
                                    Divider()
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(height: 220)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    )
                    
                    // Footer info
                    HStack {
                        if !selectedLanguages.isEmpty {
                            Label(
                                "\(selectedLanguages.count) active",
                                systemImage: "checkmark.circle.fill"
                            )
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                        
                        Spacer()
                        
                        let totalSize = ByteCountFormatter.string(fromByteCount: languageDownloader.totalInstalledSize, countStyle: .file)
                        Label(totalSize, systemImage: "square.stack.3d.up.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 550, height: preferences.tesseractEnabled ? 430 : 140)
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

// MARK: - Language Row Component
struct LanguageRow: View {
    let language: TesseractLanguageDownloader.LanguageInfo
    let isSelected: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onToggle: (Bool) -> Void
    let onDownload: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Language Info
            VStack(alignment: .leading, spacing: 4) {
                Text(language.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(language.code)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if let size = language.fileSize {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            if language.isInstalled {
                // Active toggle
                Toggle("", isOn: Binding(
                    get: { isSelected },
                    set: { onToggle($0) }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .scaleEffect(0.8)
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete language")
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            } else {
                // Download button or progress
                if isDownloading {
                    HStack(spacing: 6) {
                        ProgressView(value: downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 60)
                        
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                } else {
                    Button(action: onDownload) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 11))
                            Text("Download")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.clear)
        )
    }
}
