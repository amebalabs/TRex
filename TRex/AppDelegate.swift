import Combine
import KeyboardShortcuts
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarItem: MenubarItem?
    var trex = TRex()
    let preferences = Preferences.shared
    var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_: Notification) {
        let bundleID = Bundle.main.bundleIdentifier!

        if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1 {
            NSWorkspace.shared.open(URL(string: "trex://swhowPreferences")!)
            NSApp.terminate(nil)
        }

        cancellable = preferences.$showMenuBarIcon.sink(receiveValue: { [weak self] show in
            guard let self = self else { return }
            if show {
                self.menuBarItem = MenubarItem(self.trex)
                return
            }
            self.menuBarItem = nil
        })

        setupShortcuts()

        showOnboardingIfNeeded()
    }

    func application(_: NSApplication, open urls: [URL]) {
        for url in urls {
            switch url.host?.lowercased() {
            case "capture":
                trex.capture()
            case "swhowpreferences":
                if let menu = NSApp.mainMenu?.items.first?.submenu {
                    menu.performActionForItem(at: 0)
                }
            default:
                return
            }
        }
    }

    func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .captureText) { [self] in
            trex.capture()
        }
    }

    func showOnboardingIfNeeded() {
        guard preferences.needsOnboarding else { return }

        var onboardingWindowController = NSWindowController()

        let myWindow = NSWindow(
            contentRect: .init(origin: .zero, size: CGSize(width: 400, height: 500)),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )
        myWindow.title = "Welcome to TRex"
        myWindow.center()

        onboardingWindowController = NSWindowController(window: myWindow)
        onboardingWindowController.contentViewController = NSHostingController(rootView: OnboardingView())

        onboardingWindowController.showWindow(self)
        onboardingWindowController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
