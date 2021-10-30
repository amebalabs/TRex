import Cocoa
import Combine
import KeyboardShortcuts
import SwiftUI

class MenubarItem: NSObject {
    let trex: TRex
    let preferences = Preferences.shared
    var statusBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let statusBarmenu = NSMenu()
    let captureTextItem = NSMenuItem(title: "Capture Text", action: #selector(captureScreen), keyEquivalent: "")
    let captureTextAndTriggerAutomationItem = NSMenuItem(title: "Trigger Automation", action: #selector(captureScreenAndTriggerAutomation), keyEquivalent: "")
    let ignoreLineBreaksItem = NSMenuItem(title: "Ignore Line Breaks", action: #selector(ignoreLineBreaks), keyEquivalent: "")
    let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: "")
    let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
    let aboutItem = NSMenuItem(title: "About TRex...", action: #selector(showAbout), keyEquivalent: "")

    var cancellable: AnyCancellable?
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()

    init(_ trex: TRex) {
        self.trex = trex
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.menu = statusBarmenu
        super.init()
        buildMenu()

        statusBarItem.button?.window?.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        statusBarItem.button?.window?.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        statusBarItem.button?.window?.delegate = self

        cancellable = preferences.$menuBarIcon.sink { [weak self] item in
            let size: CGFloat = (item == .Option1) ? 18 : 20
            let image = item.nsImage().resizedCopy(w: size, h: size)
            image.isTemplate = true
            self?.statusBarItem.button?.image = image
        }
    }

    private func buildMenu() {
        [captureTextItem, captureTextAndTriggerAutomationItem, ignoreLineBreaksItem, preferencesItem, aboutItem, quitItem].forEach { $0.target = self }
        statusBarmenu.addItem(captureTextItem)
        statusBarmenu.addItem(captureTextAndTriggerAutomationItem)
        statusBarmenu.addItem(ignoreLineBreaksItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(aboutItem)
        if let menu = NSApp.mainMenu?.items.first, let item = menu.submenu?.items.first {
            menu.submenu?.removeItem(item)
            statusBarmenu.addItem(item)
        }
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(quitItem)

        statusBarmenu.delegate = self
    }

    @objc func captureScreen() {
        trex.capture(.captureScreen)
    }

    @objc func captureScreenAndTriggerAutomation() {
        trex.capture(.captureScreenAndTriggerAutomation)
    }

    @objc func ignoreLineBreaks() {
        preferences.ignoreLineBreaks.toggle()
    }

    @objc func quit() {
        NSApp.terminate(self)
    }

    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel()
    }

    @objc func showPreferences() {
        var windowRef: NSWindow
        windowRef = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        windowRef.contentView = NSHostingView(rootView: SettingsView().environmentObject(Preferences.shared))
        windowRef.makeKeyAndOrderFront(nil)
    }
}

extension MenubarItem: NSMenuDelegate {
    func menuWillOpen(_: NSMenu) {
        captureTextItem.setShortcut(for: .captureScreen)
        captureTextAndTriggerAutomationItem.setShortcut(for: .captureScreenAndTriggerAutomation)
        ignoreLineBreaksItem.state = preferences.ignoreLineBreaks ? .on:.off
    }
}

extension MenubarItem: NSWindowDelegate, NSDraggingDestination {
    func draggingEntered(_: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var files: [String] = []
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self,
        ]

        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: ["public.image"],
        ]

        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)

        sender.enumerateDraggingItems(options: [], for: nil, classes: supportedClasses, searchOptions: searchOptions) { draggingItem, _, _ in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                filePromiseReceiver.receivePromisedFiles(atDestination: destinationURL, options: [:], operationQueue: self.workQueue) { fileURL, error in
                    if error == nil {
                        files.append(fileURL.path)
                    }
                }
            case let fileURL as URL:
                files.append(fileURL.path)
            default: break
            }
        }

//        env["DROPPED_FILES"] = files.joined(separator: ",")
//        guard let scriptPath = plugin?.file else { return false }
//        AppShared.runInTerminal(script: scriptPath, env: env, runInBash: plugin?.metadata?.shouldRunInBash ?? true)
        return true
    }
}
