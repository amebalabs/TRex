import SwiftUI
import TRexCore
import KeyboardShortcuts

struct TesseractSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @State private var tesseractInfo: TesseractCLIEngine.TesseractInfo?
    @State private var selectedLanguages: Set<String> = []
    @State private var isTestingOCR = false
    @State private var testResult = ""
    
    var body: some View {
        Form {
            Section(header: Text("Tesseract OCR Engine").bold()) {
                HStack {
                    if let info = tesseractInfo {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Tesseract \(info.version) found at \(info.path)")
                            .font(.system(.body, design: .monospaced))
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Tesseract not found")
                        Spacer()
                        Button("Install Guide") {
                            NSWorkspace.shared.open(URL(string: "https://tesseract-ocr.github.io/tessdoc/Installation.html")!)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Add button to manually select tesseract binary for sandboxed app
                HStack {
                    Text("For sandboxed app:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Select Tesseract Binary") {
                        TesseractSecurityBookmark.requestTesseractAccess { url in
                            if let url = url {
                                // Re-detect tesseract after getting permission
                                detectTesseract()
                                preferences.tesseractPath = url.path
                            }
                        }
                    }
                    .font(.caption)
                }
                .padding(.vertical, 2)
                
                if tesseractInfo != nil {
                    Toggle("Enable Tesseract OCR", isOn: $preferences.tesseractEnabled)
                        .padding(.vertical, 2)
                }
            }
            
            if let info = tesseractInfo, preferences.tesseractEnabled {
                Divider()
                
                Section(header: Text("Language Configuration").bold()) {
                    Text("Available Languages (\(info.availableLanguages.count)):")
                        .font(.caption)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(info.availableLanguages.sorted(), id: \.self) { lang in
                                HStack {
                                    Toggle(isOn: Binding(
                                        get: { selectedLanguages.contains(lang) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedLanguages.insert(lang)
                                            } else {
                                                selectedLanguages.remove(lang)
                                            }
                                            preferences.tesseractLanguages = Array(selectedLanguages)
                                        }
                                    )) {
                                        HStack {
                                            Text(TesseractCLIEngine.Language.displayName(for: lang))
                                            Text("(\(lang))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 150)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    HStack {
                        Text("Selected: \(selectedLanguages.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Get More Languages") {
                            NSWorkspace.shared.open(URL(string: "https://github.com/tesseract-ocr/tessdata")!)
                        }
                        .font(.caption)
                    }
                }
                
                Divider()
                
                Section(header: Text("Keyboard Shortcut").bold()) {
                    Toggle("Use separate shortcut for Tesseract OCR", isOn: $preferences.preferTesseractShortcut)
                    
                    if preferences.preferTesseractShortcut {
                        HStack {
                            Text("Tesseract OCR:")
                            Spacer()
                            KeyboardShortcuts.Recorder(for: .captureTesseract)
                        }
                        .padding(.top, 4)
                    }
                }
                
                Divider()
                
                Section(header: Text("Test OCR").bold()) {
                    Button(action: testTesseractOCR) {
                        HStack {
                            if isTestingOCR {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.trailing, 4)
                            }
                            Text(isTestingOCR ? "Testing..." : "Test Tesseract OCR")
                        }
                    }
                    .disabled(isTestingOCR || selectedLanguages.isEmpty)
                    
                    if !testResult.isEmpty {
                        Text(testResult)
                            .font(.caption)
                            .foregroundColor(testResult.contains("Error") ? .red : .green)
                            .padding(.top, 2)
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 500, height: 450)
        .onAppear {
            detectTesseract()
            selectedLanguages = Set(preferences.tesseractLanguages)
        }
    }
    
    private func detectTesseract() {
        tesseractInfo = TesseractCLIEngine.shared.detectTesseract()
        if let info = tesseractInfo, preferences.tesseractPath.isEmpty {
            preferences.tesseractPath = info.path
        }
    }
    
    private func testTesseractOCR() {
        isTestingOCR = true
        testResult = ""
        
        // Create a test image with text
        let testImage = createTestImage()
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let result = TesseractCLIEngine.shared.performOCR(
                on: testImage,
                languages: Array(selectedLanguages),
                tesseractPath: preferences.tesseractPath
            ) {
                DispatchQueue.main.async {
                    testResult = "Success! Recognized: \"\(result)\""
                    isTestingOCR = false
                }
            } else {
                DispatchQueue.main.async {
                    testResult = "Error: Failed to perform OCR"
                    isTestingOCR = false
                }
            }
        }
    }
    
    private func createTestImage() -> NSImage {
        let size = NSSize(width: 300, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // White background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw test text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.black
        ]
        
        let text = "TRex OCR Test"
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        image.unlockFocus()
        
        return image
    }
}