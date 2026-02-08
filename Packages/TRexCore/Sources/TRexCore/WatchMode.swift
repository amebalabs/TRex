import Foundation

/// Output mode for Watch Mode continuous capture.
public enum WatchOutputMode: String, Sendable, Codable, CaseIterable {
    case appendToClipboard = "Append to Clipboard"
    case appendToFile = "Append to File"
    case notificationStream = "Notifications"
}
