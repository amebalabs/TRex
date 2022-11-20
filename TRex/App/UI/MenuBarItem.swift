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
    let ignoreLineBreaksItem = NSMenuItem(title: "Ignore Line Breaks", action: #selector(ignoreLineBreaks), keyEquivalent: "")
    let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: "")
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
        [captureTextItem, captureTextAndTriggerAutomationItem, ignoreLineBreaksItem, preferencesItem, aboutItem, quitItem].forEach { $0.target = self }
        statusBarmenu.addItem(captureTextItem)
        statusBarmenu.addItem(captureTextAndTriggerAutomationItem)
        statusBarmenu.addItem(ignoreLineBreaksItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        if #available(macOS 13.0, *) {
            if let menu = NSApp.mainMenu?.items.first, let item = menu.submenu?.items[2] {
                menu.submenu?.removeItem(item)
                statusBarmenu.addItem(item)
            }
        } else {
            if let menu = NSApp.mainMenu?.items.first, let item = menu.submenu?.items.first {
                menu.submenu?.removeItem(item)
                statusBarmenu.addItem(item)
            }
        }
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
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: self, from: self)
    }
}

extension MenubarItem: NSMenuDelegate {
    func menuWillOpen(_: NSMenu) {
        captureTextItem.setShortcut(for: .captureScreen)
        captureTextAndTriggerAutomationItem.setShortcut(for: .captureScreenAndTriggerAutomation)
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
