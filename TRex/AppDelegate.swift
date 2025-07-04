import Combine
import KeyboardShortcuts
import SwiftUI
import TRexCore

// TesseractWrapper bridge removed - now using TesseractSwift directly in TRexCore

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarItem: MenubarItem?
    var trex = TRex.shared
    let preferences = Preferences.shared
    var cancellable: Set<AnyCancellable> = []
    var onboardingWindowController: NSWindowController?

    func applicationDidFinishLaunching(_: Notification) {
        // TesseractSwift is now integrated directly in TRexCore
        
        let bundleID = Bundle.main.bundleIdentifier!
        NSApp.servicesProvider = self

        // this is a dumb workaround for but that causes Settings to open on app launch
        // this happens since macOS 15, for SwiftUI apps without windows macOS will open settings
        // a better workaround would be migrating to MenuBar extra, but this touches to many things and I don't want to invest time at the moment
        // another alternative could look like this
        // WindowGroup {
        //   EmptyView()
        //      .hidden()
        // }.defaultSize(width: 0, height: 0)

        if let window = NSApplication.shared.windows.first {
            window.close()
        }
        
        if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1 {
            NSWorkspace.shared.open(URL(string: "trex://showPreferences")!)
            NSApp.terminate(nil)
        }

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

        showOnboardingIfNeeded()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.openSettings()
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
            case "showpreferences":
                NSApp.openSettings()
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
    }

    func showOnboardingIfNeeded() {
        guard preferences.needsOnboarding else { return }

        onboardingWindowController = NSWindowController()

        let myWindow = NSWindow(
            contentRect: .init(origin: .zero, size: CGSize(width: 400, height: 500)),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        myWindow.title = "Welcome to TRex"
        myWindow.center()

        onboardingWindowController = NSWindowController(window: myWindow)
        onboardingWindowController?.contentViewController = NSHostingController(rootView: OnboardingView())

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
