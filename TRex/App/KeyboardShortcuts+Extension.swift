import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureScreen = Self("captureScreen")
    static let captureScreenAndTriggerAutomation = Self("captureScreenAndTriggerAutomation")
    static let captureClipboard = Self("captureClipboard")
    static let captureClipboardAndTriggerAutomation = Self("captureClipboardAndTriggerAutomation")
}

enum InvocationMode: String {
    case captureScreen
    case captureScreenAndTriggerAutomation
    case captureClipboard
    case captureClipboardAndTriggerAutomation
}
