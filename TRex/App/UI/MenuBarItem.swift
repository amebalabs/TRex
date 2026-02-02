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
    let outputFormatItem = NSMenuItem(title: "Table Output Format", action: nil, keyEquivalent: "")
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
        let menuItems = [captureTextItem, captureMultiRegionItem, captureTextAndTriggerAutomationItem, captureFromClipboard, ignoreLineBreaksItem, outputFormatItem, preferencesItem, aboutItem, quitItem]
        menuItems.forEach { $0.target = self }

        statusBarmenu.addItem(captureTextItem)
        statusBarmenu.addItem(captureMultiRegionItem)
        statusBarmenu.addItem(captureTextAndTriggerAutomationItem)
        statusBarmenu.addItem(captureFromClipboard)
        statusBarmenu.addItem(ignoreLineBreaksItem)
        statusBarmenu.addItem(outputFormatItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(preferencesItem)
        statusBarmenu.addItem(aboutItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        statusBarmenu.addItem(quitItem)

        // Build output format submenu
        let formatSubmenu = NSMenu()
        for format in TableOutputFormat.allCases {
            let item = NSMenuItem(title: format.rawValue, action: #selector(selectOutputFormat(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = format
            formatSubmenu.addItem(item)
        }
        outputFormatItem.submenu = formatSubmenu

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

    @objc func selectOutputFormat(_ sender: NSMenuItem) {
        if let format = sender.representedObject as? TableOutputFormat {
            preferences.tableOutputFormat = format
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

        // Update radio-style selection in output format submenu
        if let formatSubmenu = outputFormatItem.submenu {
            for item in formatSubmenu.items {
                item.state = (item.representedObject as? TableOutputFormat) == preferences.tableOutputFormat ? .on : .off
            }
        }
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
