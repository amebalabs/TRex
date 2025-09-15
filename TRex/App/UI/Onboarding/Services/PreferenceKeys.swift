import SwiftUI
import TRexCore

struct PreferenceKeys {
    @AppStorage(
        "recognitionLanguage"
    ) static var languageCode: String = "en-US"
    @AppStorage("automaticLanguageDetection") static var autoDetect = true
    @AppStorage("captureSound") static var captureSound = true
    @AppStorage("resultNotification") static var resultNotification = true
}
