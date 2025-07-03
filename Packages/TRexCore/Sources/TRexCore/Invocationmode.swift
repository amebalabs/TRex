import Foundation

public enum InvocationMode: String, CaseIterable {
    case captureScreen = "Capture Screen"
    case captureScreenAndTriggerAutomation = "Capture Screen and Run Automation"
    case captureClipboard = "Capture Clipboard"
    case captureClipboardAndTriggerAutomation = "Capture Clipboard and Run Automation"
    case captureFromFile = "Capture Image"
    case captureFromFileAndTriggerAutomation = "Capture Image and Trigger Automation"
    case captureTesseract = "Capture with Tesseract"
}
