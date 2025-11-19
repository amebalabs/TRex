import AppKit
import Foundation

@MainActor
public class ShortcutsManager: ObservableObject {
    public static let shared = ShortcutsManager()
    nonisolated let shortcutsURL = URL(fileURLWithPath: "/usr/bin/shortcuts")

    @Published public var shortcuts: [String] = []
    nonisolated var currentShortcut: String {
        Preferences.shared.autoRunShortcut
    }

    nonisolated let shortcutInputPath: URL

    public init() {
        let directory = NSTemporaryDirectory()
        self.shortcutInputPath = NSURL.fileURL(withPathComponents: [directory, "shortcutInput"])!
        if #available(macOS 12, *) {
            getShortcuts()
        }
    }

    private func isShortcutsAvailable() -> Bool {
        FileManager.default.isExecutableFile(atPath: shortcutsURL.path)
    }

    public func getShortcuts() {
        guard isShortcutsAvailable() else {
            Task { @MainActor [weak self] in
                self?.shortcuts = []
            }
            return
        }

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            let process = Process()
            process.executableURL = self.shortcutsURL
            process.arguments = ["list"]

            let pipe = Pipe()
            process.standardOutput = pipe

            do {
                try process.run()
            } catch {
                await MainActor.run {
                    self.shortcuts = []
                }
                return
            }

            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            let entries = output
                .split(whereSeparator: { $0.isNewline })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .sorted()

            await MainActor.run {
                self.shortcuts = entries
            }
        }
    }

    public func runShortcut(inputText: String) {
        guard !currentShortcut.isEmpty else { return }
        guard isShortcutsAvailable() else { return }

        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }

            do {
                try inputText.write(toFile: self.shortcutInputPath.path, atomically: true, encoding: .utf8)
            } catch {
                return
            }

            let process = Process()
            process.executableURL = self.shortcutsURL
            process.arguments = ["run", "\(self.currentShortcut)", "-i", "\(self.shortcutInputPath.path)"]

            do {
                try process.run()
            } catch {
                try? FileManager.default.removeItem(at: self.shortcutInputPath)
                return
            }

            process.waitUntilExit()
            try? FileManager.default.removeItem(at: self.shortcutInputPath)
        }
    }

    public func viewCurrentShortcut() {
        guard !currentShortcut.isEmpty else { return }
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "open-shortcut"
        components.queryItems = [
            URLQueryItem(name: "name", value: currentShortcut),
        ]
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    public func createShortcut() {
        NSWorkspace.shared.open(URL(string: "shortcuts://create-shortcut")!)
    }
}
