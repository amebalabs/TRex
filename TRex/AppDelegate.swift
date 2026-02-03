import Combine
import KeyboardShortcuts
import SwiftUI
import TRexCore
#if !MAC_APP_STORE
import Sparkle
#endif

// TesseractWrapper bridge removed - now using TesseractSwift directly in TRexCore

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var menuBarItem: MenubarItem?
    var trex = TRex.shared
    let preferences = Preferences.shared
    var cancellable: Set<AnyCancellable> = []
    var onboardingWindowController: NSWindowController?
    var historyWindowController: NSWindowController?
    let bundleID = Bundle.main.bundleIdentifier!
    #if !MAC_APP_STORE
    var softwareUpdater: SPUUpdater!
    #endif
    
    func applicationDidFinishLaunching(_: Notification) {
        NSApp.servicesProvider = self

        if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1 {
            NSWorkspace.shared.open(URL(string: "trex://showPreferences")!)
            NSApp.terminate(nil)
        }
        
        #if !MAC_APP_STORE
        setupSparkle()
        #endif

        preferences.$showMenuBarIcon.sink(receiveValue: { [weak self] show in
            guard let self = self else { return }
            if show {
                self.menuBarItem = MenubarItem(self.trex)
                return
            }
            self.menuBarItem = nil
        }).store(in: &cancellable)

        NotificationCenter.default.publisher(for: .closeOnboarding, object: nil).sink(receiveValue: { _ in
            self.onboardingWindowController?.close()
            self.preferences.needsOnboarding = false
        }).store(in: &cancellable)

        setupShortcuts()

        // Initialize LLM if enabled
        trex.initializeLLM()

        showOnboardingIfNeeded()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.showAndActivateSettings()
        }
        return true
    }
    
    func application(_: NSApplication, open urls: [URL]) {
        for url in urls {
            switch url.host?.lowercased() {
            case "capture":
                Task {
                    await trex.capture(.captureScreen)
                }
            case "captureclipboard":
                Task {
                    await trex.capture(.captureClipboard)
                }
            case "captureautomation":
                Task {
                    await trex.capture(.captureScreenAndTriggerAutomation)
                }
            case "captureclipboardautomation":
                Task {
                    await trex.capture(.captureClipboardAndTriggerAutomation)
                }
            case "capturemultiregion":
                Task {
                    await trex.capture(.captureMultiRegion)
                }
            case "capturemultiregionautomation":
                Task {
                    await trex.capture(.captureMultiRegionAndTriggerAutomation)
                }
            case "showpreferences":
                NSApp.showAndActivateSettings()
            case "showhistory":
                showHistory()
            case "shortcut":
                if let name = url.queryParameters?["name"] {
                    preferences.autoRunShortcut = name
                }
            default:
                return
            }
        }
    }

    func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .captureScreen) { [self] in
            Task {
                await trex.capture(.captureScreen)
            }
        }
        KeyboardShortcuts.onKeyUp(for: .captureScreenAndTriggerAutomation) { [self] in
            Task {
                await trex.capture(.captureScreenAndTriggerAutomation)
            }
        }
        KeyboardShortcuts.onKeyUp(for: .captureClipboard) { [self] in
            Task {
                await trex.capture(.captureClipboard)
            }
        }
        KeyboardShortcuts.onKeyUp(for: .captureClipboardAndTriggerAutomation) { [self] in
            Task {
                await trex.capture(.captureClipboardAndTriggerAutomation)
            }
        }
        KeyboardShortcuts.onKeyUp(for: .captureMultiRegion) { [self] in
            Task {
                await trex.capture(.captureMultiRegion)
            }
        }
        KeyboardShortcuts.onKeyUp(for: .captureMultiRegionAndTriggerAutomation) { [self] in
            Task {
                await trex.capture(.captureMultiRegionAndTriggerAutomation)
            }
        }
    }

    @MainActor func showHistory() {
        if let controller = historyWindowController {
            controller.showWindow(self)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: .init(origin: .zero, size: CGSize(width: 700, height: 500)),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Capture History"
        window.minSize = CGSize(width: 600, height: 400)
        window.center()

        let controller = NSWindowController(window: window)
        controller.contentViewController = NSHostingController(
            rootView: CaptureHistoryView(store: trex.captureHistoryStore)
        )
        historyWindowController = controller

        controller.showWindow(self)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showOnboardingIfNeeded() {
        guard preferences.needsOnboarding else { return }
        
        onboardingWindowController = NSWindowController()

        let myWindow = NSWindow(
            contentRect: .init(origin: .zero, size: CGSize(width: 900, height: 700)),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        myWindow.title = "Welcome to TRex"
        myWindow.titlebarAppearsTransparent = true
        myWindow.isMovableByWindowBackground = true
        myWindow.backgroundColor = NSColor.windowBackgroundColor
        myWindow.minSize = CGSize(width: 1000, height: 800)
        myWindow.maxSize = CGSize(width: 1000, height: 800)
        myWindow.center()

        onboardingWindowController = NSWindowController(window: myWindow)
        onboardingWindowController?.contentViewController = NSHostingController(
            rootView: OnboardingView()
                .environmentObject(preferences)
        )

        onboardingWindowController?.showWindow(self)
        onboardingWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate {
    @objc func fileServiceHandler(_ pboard: NSPasteboard, userData _: String, error _: NSErrorPointer) {
        if let path = pboard.string(forType: .fileURL) {
            let url = URL(string: path) ?? URL(fileURLWithPath: path)
            let coord = NSFileCoordinator()
            coord.coordinate(readingItemAt: url, options: .forUploading, error: nil, byAccessor: { url in
                Task {
                    await trex.capture(.captureFromFile, imagePath: url.path)
                }
            })
        }
    }
}

// MARK: - NSApplication Settings Extension

extension NSApplication {
    /// Opens settings and brings the app to front
    func showAndActivateSettings() {
        openSettings()
        activate(ignoringOtherApps: true)
    }
}

#if !MAC_APP_STORE
extension AppDelegate: SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    func setupSparkle() {
        let hostBundle = Bundle.main
        let updateDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: self)
        softwareUpdater = SPUUpdater(hostBundle: hostBundle, applicationBundle: hostBundle, userDriver: updateDriver, delegate: self)

        do {
            try softwareUpdater.start()
        } catch {
            print("Failed to start software updater with error: \(error)")
        }
    }

    func feedURLString(for updater: SPUUpdater) -> String? {
        if preferences.includeBetaUpdates {
            return "https://amebalabs.github.io/TRex/appcast_beta.xml"
        }
        return "https://amebalabs.github.io/TRex/appcast.xml"
    }
}
#endif
