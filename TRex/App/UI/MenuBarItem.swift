import Cocoa
import Combine
import KeyboardShortcuts
import SwiftUI
import TRexCore

class MenubarItem: NSObject {
    let trex: TRex
    let preferences = Preferences.shared
    var statusBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let statusBarmenu = NSMenu()
    let captureTextItem = NSMenuItem(title: "Capture", action: #selector(captureScreen), keyEquivalent: "")
    let captureTextAndTriggerAutomationItem = NSMenuItem(title: "Capture & Run Automation", action: #selector(captureScreenAndTriggerAutomation), keyEquivalent: "")
    let captureFromClipboard = NSMenuItem(title: "Capture from Clipboard", action: #selector(captureClipboard), keyEquivalent: "")
    let ignoreLineBreaksItem = NSMenuItem(title: "Ignore Line Breaks", action: #selector(ignoreLineBreaks), keyEquivalent: "")
    let preferencesItem = NSMenuItem(title: "Settings...", action: #selector(showPreferences), keyEquivalent: ",")
    let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
    let aboutItem = NSMenuItem(title: "About TRex", action: #selector(showAbout), keyEquivalent: "")

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
        [captureTextItem, captureTextAndTriggerAutomationItem, captureFromClipboard, ignoreLineBreaksItem, preferencesItem, aboutItem, quitItem].forEach { $0.target = self }
        statusBarmenu.addItem(captureTextItem)
        statusBarmenu.addItem(captureTextAndTriggerAutomationItem)
        statusBarmenu.addItem(captureFromClipboard)
        statusBarmenu.addItem(ignoreLineBreaksItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(preferencesItem)
        statusBarmenu.addItem(aboutItem)
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

    @objc func captureClipboard() {
        trex.capture(.captureClipboard)
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
        NSApp.openSettings()
        return
    }
}

extension MenubarItem: NSMenuDelegate {
    func menuWillOpen(_ menu : NSMenu) {
        
        if NSApp.currentEvent?.modifierFlags.contains(.option) == true {
            menu.cancelTracking()
            if preferences.optionQuickAction == .captureFromFile || preferences.optionQuickAction == .captureFromFileAndTriggerAutomation {
                let dialog = NSOpenPanel()
                dialog.title = "Choose an image"
                dialog.showsResizeIndicator = true
                dialog.showsHiddenFiles = false
                dialog.allowsMultipleSelection = false
                dialog.canChooseDirectories = false
                dialog.allowedContentTypes = [.jpeg, .png, .tiff, .gif]
                
                if dialog.runModal() == .OK {
                    trex.capture(preferences.optionQuickAction, imagePath: dialog.url?.path(percentEncoded: false))
                }
                return
            }
            trex.capture(preferences.optionQuickAction)
            return
        }
        
        captureTextItem.setShortcut(for: .captureScreen)
        captureTextAndTriggerAutomationItem.setShortcut(for: .captureScreenAndTriggerAutomation)
        captureFromClipboard.setShortcut(for: .captureClipboard)

        captureFromClipboard.isEnabled = clipboardHasSupportedContente() ? true : false
        ignoreLineBreaksItem.state = preferences.ignoreLineBreaks ? .on : .off
    }

    func menuDidClose(_: NSMenu) {
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension MenubarItem: NSWindowDelegate, NSDraggingDestination {
    func draggingEntered(_: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var filesURL: [URL] = []

        let pasteBoard = sender.draggingPasteboard
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            filesURL = urls
        }

        if !filesURL.isEmpty, let imagePath = filesURL.first?.path {
            trex.capture(.captureFromFile, imagePath: imagePath)
        }

        return true
    }
}
