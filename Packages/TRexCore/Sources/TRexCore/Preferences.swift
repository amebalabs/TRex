import Cocoa
import Combine
import SwiftUI

public class Preferences: ObservableObject {
    public nonisolated(unsafe) static let shared = Preferences()
    static let suiteName = "X93LWC49WV.TRex.preferences"
    nonisolated(unsafe) static let userDefaults = UserDefaults(suiteName: suiteName)!

    enum PreferencesKeys: String {
        case CaptureSound
        case ResultNotification
        case ShowMenuBarIcon
        case IgnoreLineBreaks
        case RecongitionLanguage
        case NeedsOnboarding
        case MenuBarIcon
        case AutoOpenCapturedURL
        case AutoOpenQRCodeURL
        case AutoOpenProvidedURL
        case AutoOpenProvidedURLAddNewLine
        case AutoRunShortcut
        case CustomWords
        case AutomaticLanguageDetection
        case OptionQuickAction
        case TesseractEnabled
        case TesseractLanguages
        case TesseractPath
        case IncludeBetaUpdates
        case LLMEnabled
        case LLMOCRProvider
        case LLMOCRAPIKey
        case LLMOCRCustomEndpoint
        case LLMPostProcessProvider
        case LLMPostProcessAPIKey
        case LLMPostProcessCustomEndpoint
        case LLMOCRModel
        case LLMPostProcessModel
        case LLMEnableOCR
        case LLMEnablePostProcessing
        case LLMOCRPrompt
        case LLMPostProcessPrompt
        case LLMFallbackToBuiltIn
        case TableDetectionEnabled
        case TableOutputFormat
        case CaptureHistoryEnabled
        case CaptureHistoryMaxEntries
    }

    public enum MenuBarIcon: String, CaseIterable {
        case Option1
        case Option2
        case Option3
        case Option4
        case Option5
        case Option6

        public func image() -> Image {
            Image(nsImage: nsImage())
        }

        public func nsImage() -> NSImage {
            var image: NSImage?
            let imageConfig = NSImage.SymbolConfiguration(pointSize: 50, weight: .heavy, scale: .large)
            switch self {
            case .Option1:
                image = NSImage(named: "trex")
            case .Option2:
                image = NSImage(systemSymbolName: "perspective", accessibilityDescription: nil)?.withSymbolConfiguration(imageConfig)
            case .Option3:
                image = NSImage(systemSymbolName: "crop", accessibilityDescription: nil)?.withSymbolConfiguration(imageConfig)
            case .Option4:
                image = NSImage(systemSymbolName: "textbox", accessibilityDescription: nil)?.withSymbolConfiguration(imageConfig)
            case .Option5:
                image = NSImage(systemSymbolName: "doc.text.fill.viewfinder", accessibilityDescription: nil)?.withSymbolConfiguration(imageConfig)
            case .Option6:
                image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: nil)?.withSymbolConfiguration(imageConfig)
            }
            image?.isTemplate = true
            return image!
        }
    }


    @Published public var needsOnboarding: Bool {
        didSet {
            Preferences.setValue(value: needsOnboarding, key: .NeedsOnboarding)
        }
    }

    @Published public var captureSound: Bool {
        didSet {
            Preferences.setValue(value: captureSound, key: .CaptureSound)
        }
    }

    @Published public var resultNotification: Bool {
        didSet {
            Preferences.setValue(value: resultNotification, key: .ResultNotification)
        }
    }

    @Published public var showMenuBarIcon: Bool {
        didSet {
            Preferences.setValue(value: showMenuBarIcon, key: .ShowMenuBarIcon)
        }
    }

    @Published public var ignoreLineBreaks: Bool {
        didSet {
            Preferences.setValue(value: ignoreLineBreaks, key: .IgnoreLineBreaks)
        }
    }

    @Published public var autoOpenCapturedURL: Bool {
        didSet {
            Preferences.setValue(value: autoOpenCapturedURL, key: .AutoOpenCapturedURL)
        }
    }

    @Published public var autoOpenQRCodeURL: Bool {
        didSet {
            Preferences.setValue(value: autoOpenQRCodeURL, key: .AutoOpenQRCodeURL)
        }
    }

    @Published public var autoOpenProvidedURL: String {
        didSet {
            Preferences.setValue(value: autoOpenProvidedURL, key: .AutoOpenProvidedURL)
        }
    }

    @Published public var autoOpenProvidedURLAddNewLine: Bool {
        didSet {
            Preferences.setValue(value: autoOpenProvidedURLAddNewLine, key: .AutoOpenProvidedURLAddNewLine)
        }
    }

    @Published public var autoRunShortcut: String {
        didSet {
            Preferences.setValue(value: autoRunShortcut, key: .AutoRunShortcut)
        }
    }

    @Published public var recognitionLanguageCode: String {
        didSet {
            Preferences.setValue(value: recognitionLanguageCode, key: .RecongitionLanguage)
        }
    }

    @Published public var menuBarIcon: MenuBarIcon {
        didSet {
            Preferences.setValue(value: menuBarIcon.rawValue, key: .MenuBarIcon)
        }
    }

    @Published public var customWords: String {
        didSet {
            Preferences.setValue(value: customWords, key: .CustomWords)
        }
    }

    public var customWordsList: [String] {
        customWords
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @Published public var automaticLanguageDetection: Bool {
        didSet {
            Preferences.setValue(value: automaticLanguageDetection, key: .AutomaticLanguageDetection)
        }
    }
    
    @Published public var optionQuickAction: InvocationMode {
        didSet {
            Preferences.setValue(value: optionQuickAction.rawValue, key: .OptionQuickAction)
        }
    }
    
    @Published public var tesseractEnabled: Bool {
        didSet {
            Preferences.setValue(value: tesseractEnabled, key: .TesseractEnabled)
        }
    }
    
    @Published public var tesseractLanguages: [String] {
        didSet {
            Preferences.setValue(value: tesseractLanguages, key: .TesseractLanguages)
        }
    }
    
    @Published public var tesseractPath: String {
        didSet {
            Preferences.setValue(value: tesseractPath, key: .TesseractPath)
        }
    }
    
    @Published public var includeBetaUpdates: Bool {
        didSet {
            Preferences.setValue(value: includeBetaUpdates, key: .IncludeBetaUpdates)
        }
    }

    @Published public var llmEnabled: Bool {
        didSet {
            Preferences.setValue(value: llmEnabled, key: .LLMEnabled)
        }
    }

    @Published public var llmOCRProvider: String {
        didSet {
            Preferences.setValue(value: llmOCRProvider, key: .LLMOCRProvider)
        }
    }

    @Published public var llmOCRAPIKey: String {
        didSet {
            Preferences.setValue(value: llmOCRAPIKey, key: .LLMOCRAPIKey)
        }
    }

    @Published public var llmOCRCustomEndpoint: String {
        didSet {
            Preferences.setValue(value: llmOCRCustomEndpoint, key: .LLMOCRCustomEndpoint)
        }
    }

    @Published public var llmPostProcessProvider: String {
        didSet {
            Preferences.setValue(value: llmPostProcessProvider, key: .LLMPostProcessProvider)
        }
    }

    @Published public var llmPostProcessAPIKey: String {
        didSet {
            Preferences.setValue(value: llmPostProcessAPIKey, key: .LLMPostProcessAPIKey)
        }
    }

    @Published public var llmPostProcessCustomEndpoint: String {
        didSet {
            Preferences.setValue(value: llmPostProcessCustomEndpoint, key: .LLMPostProcessCustomEndpoint)
        }
    }

    @Published public var llmOCRModel: String {
        didSet {
            Preferences.setValue(value: llmOCRModel, key: .LLMOCRModel)
        }
    }

    @Published public var llmPostProcessModel: String {
        didSet {
            Preferences.setValue(value: llmPostProcessModel, key: .LLMPostProcessModel)
        }
    }

    @Published public var llmEnableOCR: Bool {
        didSet {
            Preferences.setValue(value: llmEnableOCR, key: .LLMEnableOCR)
        }
    }

    @Published public var llmEnablePostProcessing: Bool {
        didSet {
            Preferences.setValue(value: llmEnablePostProcessing, key: .LLMEnablePostProcessing)
        }
    }

    @Published public var llmOCRPrompt: String {
        didSet {
            Preferences.setValue(value: llmOCRPrompt, key: .LLMOCRPrompt)
        }
    }

    @Published public var llmPostProcessPrompt: String {
        didSet {
            Preferences.setValue(value: llmPostProcessPrompt, key: .LLMPostProcessPrompt)
        }
    }

    @Published public var llmFallbackToBuiltIn: Bool {
        didSet {
            Preferences.setValue(value: llmFallbackToBuiltIn, key: .LLMFallbackToBuiltIn)
        }
    }

    @Published public var captureHistoryEnabled: Bool {
        didSet {
            Preferences.setValue(value: captureHistoryEnabled, key: .CaptureHistoryEnabled)
        }
    }

    public static let captureHistoryMinEntries = 1
    public static let captureHistoryMaxEntriesLimit = 10_000

    @Published public var captureHistoryMaxEntries: Int {
        didSet {
            let clamped = max(Self.captureHistoryMinEntries, min(captureHistoryMaxEntries, Self.captureHistoryMaxEntriesLimit))
            if clamped != captureHistoryMaxEntries {
                captureHistoryMaxEntries = clamped
                return
            }
            Preferences.setValue(value: captureHistoryMaxEntries, key: .CaptureHistoryMaxEntries)
        }
    }

    @Published public var tableDetectionEnabled: Bool {
        didSet {
            Preferences.setValue(value: tableDetectionEnabled, key: .TableDetectionEnabled)
        }
    }

    @Published public var tableOutputFormat: TableOutputFormat {
        didSet {
            Preferences.setValue(value: tableOutputFormat.rawValue, key: .TableOutputFormat)
        }
    }

    init() {
        needsOnboarding = Preferences.getValue(key: .NeedsOnboarding) as? Bool ?? true
        captureSound = Preferences.getValue(key: .CaptureSound) as? Bool ?? true
        resultNotification = Preferences.getValue(key: .ResultNotification) as? Bool ?? false
        showMenuBarIcon = Preferences.getValue(key: .ShowMenuBarIcon) as? Bool ?? true
        ignoreLineBreaks = Preferences.getValue(key: .IgnoreLineBreaks) as? Bool ?? false
        autoOpenCapturedURL = Preferences.getValue(key: .AutoOpenCapturedURL) as? Bool ?? false
        autoOpenQRCodeURL = Preferences.getValue(key: .AutoOpenQRCodeURL) as? Bool ?? false
        autoOpenProvidedURL = Preferences.getValue(key: .AutoOpenProvidedURL) as? String ?? ""
        autoOpenProvidedURLAddNewLine = Preferences.getValue(key: .AutoOpenProvidedURLAddNewLine) as? Bool ?? true
        autoRunShortcut = Preferences.getValue(key: .AutoRunShortcut) as? String ?? ""
        if let storedArray = Preferences.getValue(key: .CustomWords) as? [String] {
            customWords = storedArray.joined(separator: ",")
        } else {
            customWords = Preferences.getValue(key: .CustomWords) as? String ?? ""
        }
        
        // Handle language preference - support both old enum rawValue and new language codes
        if let savedLanguage = Preferences.getValue(key: .RecongitionLanguage) as? String {
            // Check if it's an old enum rawValue (contains emoji)
            if savedLanguage.contains("🇺🇸") {
                recognitionLanguageCode = "en-US"
            } else if savedLanguage.contains("🇫🇷") {
                recognitionLanguageCode = "fr-FR"
            } else if savedLanguage.contains("🇮🇹") {
                recognitionLanguageCode = "it-IT"
            } else if savedLanguage.contains("🇩🇪") {
                recognitionLanguageCode = "de-DE"
            } else if savedLanguage.contains("🇪🇸") {
                recognitionLanguageCode = "es-ES"
            } else if savedLanguage.contains("🇵🇹") || savedLanguage.contains("Portuguese") {
                recognitionLanguageCode = "pt-BR"
            } else if savedLanguage.contains("🇨🇳") && savedLanguage.contains("Traditional") {
                recognitionLanguageCode = "zh-Hant"
            } else if savedLanguage.contains("🇨🇳") {
                recognitionLanguageCode = "zh-Hans"
            } else if savedLanguage.contains("🇰🇷") {
                recognitionLanguageCode = "ko-KR"
            } else if savedLanguage.contains("🇯🇵") {
                recognitionLanguageCode = "ja-JP"
            } else if savedLanguage.contains("🇺🇦") {
                recognitionLanguageCode = "uk-UA"
            } else if savedLanguage.contains("🇷🇺") {
                recognitionLanguageCode = "ru-RU"
            } else {
                // Already a proper language code
                recognitionLanguageCode = savedLanguage
            }
        } else {
            recognitionLanguageCode = "en-US"
        }
        
        automaticLanguageDetection = Preferences.getValue(key: .AutomaticLanguageDetection) as? Bool ?? false
        menuBarIcon = .Option1
        if let mbitem = Preferences.getValue(key: .MenuBarIcon) as? String {
            menuBarIcon = MenuBarIcon(rawValue: mbitem) ?? .Option1
        }
        optionQuickAction = .captureScreen
        if let optionQA = Preferences.getValue(key: .OptionQuickAction) as? String {
            optionQuickAction = InvocationMode(rawValue: optionQA) ?? .captureScreen
        }
        tesseractEnabled = Preferences.getValue(key: .TesseractEnabled) as? Bool ?? false
        tesseractLanguages = Preferences.getValue(key: .TesseractLanguages) as? [String] ?? ["eng"]
        tesseractPath = Preferences.getValue(key: .TesseractPath) as? String ?? ""
        includeBetaUpdates = Preferences.getValue(key: .IncludeBetaUpdates) as? Bool ?? false
        llmEnabled = Preferences.getValue(key: .LLMEnabled) as? Bool ?? false
        llmOCRProvider = Preferences.getValue(key: .LLMOCRProvider) as? String ?? "OpenAI"
        llmOCRAPIKey = Preferences.getValue(key: .LLMOCRAPIKey) as? String ?? ""
        llmOCRCustomEndpoint = Preferences.getValue(key: .LLMOCRCustomEndpoint) as? String ?? ""
        llmPostProcessProvider = Preferences.getValue(key: .LLMPostProcessProvider) as? String ?? "OpenAI"
        llmPostProcessAPIKey = Preferences.getValue(key: .LLMPostProcessAPIKey) as? String ?? ""
        llmPostProcessCustomEndpoint = Preferences.getValue(key: .LLMPostProcessCustomEndpoint) as? String ?? ""
        llmOCRModel = Preferences.getValue(key: .LLMOCRModel) as? String ?? "gpt-4o"
        llmPostProcessModel = Preferences.getValue(key: .LLMPostProcessModel) as? String ?? "gpt-4o"
        llmEnableOCR = Preferences.getValue(key: .LLMEnableOCR) as? Bool ?? false
        llmEnablePostProcessing = Preferences.getValue(key: .LLMEnablePostProcessing) as? Bool ?? false
        llmOCRPrompt = Preferences.getValue(key: .LLMOCRPrompt) as? String ?? "Extract all visible text from this image. Preserve the layout and formatting as much as possible. Return only the extracted text without any additional commentary."
        llmPostProcessPrompt = Preferences.getValue(key: .LLMPostProcessPrompt) as? String ?? "You are given OCR output that may contain errors. Please:\n1. Correct any obvious spelling or recognition errors\n2. Fix formatting issues (spacing, line breaks)\n3. Preserve the original structure and meaning\n4. Return only the corrected text without explanations\n\nOCR Text:\n{text}"
        llmFallbackToBuiltIn = Preferences.getValue(key: .LLMFallbackToBuiltIn) as? Bool ?? true
        captureHistoryEnabled = Preferences.getValue(key: .CaptureHistoryEnabled) as? Bool ?? true
        let storedMaxEntries = Preferences.getValue(key: .CaptureHistoryMaxEntries) as? Int ?? 100
        captureHistoryMaxEntries = max(Self.captureHistoryMinEntries, min(storedMaxEntries, Self.captureHistoryMaxEntriesLimit))
        tableDetectionEnabled = Preferences.getValue(key: .TableDetectionEnabled) as? Bool ?? true
        if let rawFormat = Preferences.getValue(key: .TableOutputFormat) as? String,
           let format = TableOutputFormat(rawValue: rawFormat) {
            tableOutputFormat = format
        } else {
            tableOutputFormat = .markdown
        }
    }

    static func removeAll() {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    private static func setValue(value: Any?, key: PreferencesKeys) {
        userDefaults.setValue(value, forKey: key.rawValue)
    }

    private static func getValue(key: PreferencesKeys) -> Any? {
        userDefaults.value(forKey: key.rawValue)
    }
    
    private static func removeValue(key: PreferencesKeys) {
        userDefaults.removeObject(forKey: key.rawValue)
    }
}
