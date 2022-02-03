import Foundation
import AppKit

class ShortcutsManager: ObservableObject {
    static let shared = ShortcutsManager()
    var task: Process?
    var shortcutsURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
    var shellURL = URL(fileURLWithPath: "/bin/zsh")
    
    @Published var shortcuts: [String] = []
    
    var currentShortcut: String {
        Preferences.shared.autoRunShortcut
    }
    
    lazy var shortcutInputPath: URL = {
        let directory = NSTemporaryDirectory()
        return NSURL.fileURL(withPathComponents: [directory, "shortcutInput"])!
    }()
    
    init() {
        getShortcuts()
    }
    
    
    func getShortcuts() {
        task = Process()
        task?.executableURL = shortcutsURL
        task?.arguments = ["list"]
        
        let pipe = Pipe()
        task?.standardOutput = pipe
        task?.launch()
        task?.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        shortcuts = output.components(separatedBy: .newlines).sorted()
    }
    
    func runShortcut(inputText: String) {
        guard !currentShortcut.isEmpty else {return}
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "run-shortcut"
        components.queryItems = [
            URLQueryItem(name: "name", value: currentShortcut),
            URLQueryItem(name: "input", value: "text"),
            URLQueryItem(name: "text", value: inputText),
        ]
        
        NSWorkspace.shared.open(components.url!)
    }
    
    func viewCurrentShortcut() {
        guard !currentShortcut.isEmpty else {return}
        
        task = Process()
        task?.executableURL = shellURL
        task?.arguments = ["-c", "-l", "shortcuts view '\(currentShortcut)'"]
    
        task?.launch()
        task?.waitUntilExit()
    }
    
    func createShortcut() {
        NSWorkspace.shared.open(URL(string: "shortcuts://create-shortcut")!)
    }
}
