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
    let captureMultiRegionItem = NSMenuItem(title: "Capture Multi-Region", action: #selector(captureMultiRegion), keyEquivalent: "")
    let captureTextAndTriggerAutomationItem = NSMenuItem(title: "Capture & Run Automation", action: #selector(captureScreenAndTriggerAutomation), keyEquivalent: "")
    let captureFromClipboard = NSMenuItem(title: "Capture from Clipboard", action: #selector(captureClipboard), keyEquivalent: "")
    let ignoreLineBreaksItem = NSMenuItem(title: "Ignore Line Breaks", action: #selector(ignoreLineBreaks), keyEquivalent: "")
    let tableDetectionMenuItem = NSMenuItem(title: "Table Detection", action: nil, keyEquivalent: "")
    let tableDetectionToggleItem = NSMenuItem(title: "Enable Table Detection", action: #selector(toggleTableDetection), keyEquivalent: "")
    let historyItem = NSMenuItem(title: "History", action: nil, keyEquivalent: "")
    let preferencesItem = NSMenuItem(title: "Settings...", action: #selector(showPreferences), keyEquivalent: ",")
    let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
    let aboutItem = NSMenuItem(title: "About TRex", action: #selector(showAbout), keyEquivalent: "")

    var cancellable: AnyCancellable?
    var llmProcessingCancellable: AnyCancellable?
    private var pulseAnimation: CFRunLoopTimer?
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

        // LLMProcessingState is @MainActor; subscribe from main actor context
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.llmProcessingCancellable = trex.llmProcessingState.$isProcessing
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isProcessing in
                    if isProcessing {
                        self?.startPulse()
                    } else {
                        self?.stopPulse()
                    }
                }
        }
    }

    private func startPulse() {
        guard pulseAnimation == nil, let button = statusBarItem.button else { return }
        let minAlpha: CGFloat = 0.3
        let maxAlpha: CGFloat = 1.0
        let step: CGFloat = 0.05
        var fadingOut = true
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent(), 0.05, 0, 0) { _ in
            if fadingOut {
                button.alphaValue = max(minAlpha, button.alphaValue - step)
                if button.alphaValue <= minAlpha {
                    fadingOut = false
                }
            } else {
                button.alphaValue = min(maxAlpha, button.alphaValue + step)
                if button.alphaValue >= maxAlpha {
                    fadingOut = true
                }
            }
        }
        CFRunLoopAddTimer(CFRunLoopGetMain(), timer, .commonModes)
        pulseAnimation = timer
    }

    private func stopPulse() {
        if let timer = pulseAnimation {
            CFRunLoopTimerInvalidate(timer)
            pulseAnimation = nil
        }
        statusBarItem.button?.alphaValue = 1.0
    }

    private func buildMenu() {
        let menuItems = [captureTextItem, captureMultiRegionItem, captureTextAndTriggerAutomationItem, captureFromClipboard, ignoreLineBreaksItem, tableDetectionToggleItem, historyItem, preferencesItem, aboutItem, quitItem]
        menuItems.forEach { $0.target = self }

        statusBarmenu.addItem(captureTextItem)
        statusBarmenu.addItem(captureMultiRegionItem)
        statusBarmenu.addItem(captureTextAndTriggerAutomationItem)
        statusBarmenu.addItem(captureFromClipboard)
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(historyItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(ignoreLineBreaksItem)
        statusBarmenu.addItem(tableDetectionMenuItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(preferencesItem)
        statusBarmenu.addItem(aboutItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(quitItem)

        // Build table detection submenu (toggle + format options)
        let tableSubmenu = NSMenu()
        tableSubmenu.addItem(tableDetectionToggleItem)
        tableSubmenu.addItem(NSMenuItem.separator())
        for format in TableOutputFormat.allCases {
            let item = NSMenuItem(title: format.rawValue, action: #selector(selectOutputFormat(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = format
            tableSubmenu.addItem(item)
        }
        tableDetectionMenuItem.submenu = tableSubmenu

        statusBarmenu.delegate = self
    }

    @objc func captureScreen() {
        Task {
            await trex.capture(.captureScreen)
        }
    }

    @objc func captureMultiRegion() {
        Task {
            await trex.capture(.captureMultiRegion)
        }
    }

    @objc func captureScreenAndTriggerAutomation() {
        Task {
            await trex.capture(.captureScreenAndTriggerAutomation)
        }
    }

    @objc func captureClipboard() {
        Task {
            await trex.capture(.captureClipboard)
        }
    }

    @objc func ignoreLineBreaks() {
        preferences.ignoreLineBreaks.toggle()
    }

    @objc func toggleTableDetection() {
        preferences.tableDetectionEnabled.toggle()
    }

    @objc func selectOutputFormat(_ sender: NSMenuItem) {
        if let format = sender.representedObject as? TableOutputFormat {
            preferences.tableOutputFormat = format
        }
    }

    @objc func showHistory() {
        guard let url = URL(string: "trex://showHistory") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func copyHistoryEntry(_ sender: NSMenuItem) {
        if let text = sender.representedObject as? String {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }
    }

    @objc func quit() {
        NSApp.terminate(self)
    }

    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel()
    }

    @objc func showPreferences() {
        NSApp.showAndActivateSettings()
    }
}

extension MenubarItem: NSMenuDelegate {
    func menuWillOpen(_ menu : NSMenu) {
        
        if NSApp.currentEvent?.modifierFlags.contains(.option) == true {
            menu.cancelTracking()
            let quickAction = preferences.optionQuickAction
            if quickAction == .captureFromFile || quickAction == .captureFromFileAndTriggerAutomation {
                let dialog = NSOpenPanel()
                dialog.title = "Choose an image"
                dialog.showsResizeIndicator = true
                dialog.showsHiddenFiles = false
                dialog.allowsMultipleSelection = false
                dialog.canChooseDirectories = false
                dialog.allowedContentTypes = [.jpeg, .png, .tiff, .gif]
                
                if dialog.runModal() == .OK {
                    Task {
                        await trex.capture(quickAction, imagePath: dialog.url?.path(percentEncoded: false))
                    }
                }
                return
            }
            Task {
                await trex.capture(quickAction)
            }
            return
        }
        
        captureTextItem.setShortcut(for: .captureScreen)
        captureMultiRegionItem.setShortcut(for: .captureMultiRegion)
        captureTextAndTriggerAutomationItem.setShortcut(for: .captureScreenAndTriggerAutomation)
        captureFromClipboard.setShortcut(for: .captureClipboard)

        captureFromClipboard.isEnabled = clipboardHasSupportedContente() ? true : false
        ignoreLineBreaksItem.state = preferences.ignoreLineBreaks ? .on : .off
        tableDetectionToggleItem.state = preferences.tableDetectionEnabled ? .on : .off

        // Update radio-style selection in format submenu + disable when off
        if let tableSubmenu = tableDetectionMenuItem.submenu {
            var foundSeparator = false
            for item in tableSubmenu.items {
                if item.isSeparatorItem {
                    foundSeparator = true
                    continue
                }
                if let format = item.representedObject as? TableOutputFormat {
                    item.state = format == preferences.tableOutputFormat ? .on : .off
                }
                if foundSeparator {
                    item.isEnabled = preferences.tableDetectionEnabled
                }
            }
        }

        // Build history submenu
        buildHistorySubmenu()
    }

    private static let historyMenuMaxEntries = 5
    private static let historyMenuTruncationLength = 40

    @MainActor private func buildHistorySubmenu() {
        let submenu = NSMenu()

        guard preferences.captureHistoryEnabled else {
            let disabledItem = NSMenuItem(title: "History is disabled", action: nil, keyEquivalent: "")
            disabledItem.isEnabled = false
            submenu.addItem(disabledItem)
            historyItem.submenu = submenu
            return
        }

        let entries = trex.captureHistoryStore.entries
        let recentEntries = entries.prefix(Self.historyMenuMaxEntries)

        if recentEntries.isEmpty {
            let emptyItem = NSMenuItem(title: "No captures yet", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            for entry in recentEntries {
                let firstLine = entry.text.components(separatedBy: .newlines).first ?? ""
                let maxLen = Self.historyMenuTruncationLength
                let truncated = firstLine.count > maxLen ? String(firstLine.prefix(maxLen)) + "..." : firstLine
                let item = NSMenuItem(title: truncated, action: #selector(copyHistoryEntry(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = entry.text
                submenu.addItem(item)
            }
        }

        submenu.addItem(NSMenuItem.separator())
        let showAllItem = NSMenuItem(title: "Show All...", action: #selector(showHistory), keyEquivalent: "")
        showAllItem.target = self
        submenu.addItem(showAllItem)

        historyItem.submenu = submenu
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
            Task {
                await trex.capture(.captureFromFile, imagePath: imagePath)
            }
        }

        return true
    }
}
