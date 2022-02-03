import Combine
import KeyboardShortcuts
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarItem: MenubarItem?
    var trex = TRex()
    let preferences = Preferences.shared
    var cancellable: Set<AnyCancellable> = []
    var onboardingWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_: Notification) {
        let bundleID = Bundle.main.bundleIdentifier!
        
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
    
    func application(_: NSApplication, open urls: [URL]) {
        for url in urls {
            switch url.host?.lowercased() {
            case "capture":
                trex.capture(.captureScreen)
            case "captureclipboard":
                trex.capture(.captureClipboard)
            case "captureautomation":
                trex.capture(.captureScreenAndTriggerAutomation)
            case "captureclipboardautomation":  
                trex.capture(.captureClipboardAndTriggerAutomation)
            case "showpreferences":
                menuBarItem?.showPreferences()
            default:
                return
            }
        }
    }
    
    func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .captureScreen) { [self] in
            trex.capture(.captureScreen)
        }
        KeyboardShortcuts.onKeyUp(for: .captureScreenAndTriggerAutomation) { [self] in
            trex.capture(.captureScreenAndTriggerAutomation)
        }
        KeyboardShortcuts.onKeyUp(for: .captureClipboard) { [self] in
            trex.capture(.captureClipboard)
        }
        KeyboardShortcuts.onKeyUp(for: .captureClipboardAndTriggerAutomation) { [self] in
            trex.capture(.captureClipboardAndTriggerAutomation)
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
