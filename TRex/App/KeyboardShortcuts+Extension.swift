import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureScreen = Self("captureScreen")
    static let captureScreenAndTriggerAutomation = Self("captureScreenAndTriggerAutomation")
    static let captureClipboard = Self("captureClipboard")
}

enum InvocationMode {
    case captureScreen
    case captureScreenAndTriggerAutomation
    case captureClipboard
}
