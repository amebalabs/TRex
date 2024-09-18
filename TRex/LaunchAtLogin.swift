//Copied from https://github.com/sindresorhus/LaunchAtLogin-Modern

import SwiftUI
import ServiceManagement
import os.log

public enum LaunchAtLogin {
	private static let logger = Logger(subsystem: "com.sindresorhus.LaunchAtLogin", category: "main")
	public static let observable = Observable()

	/**
	Toggle “launch at login” for your app or check whether it's enabled.
	*/
	public static var isEnabled: Bool {
		get { SMAppService.mainApp.status == .enabled }
		set {
			observable.objectWillChange.send()

			do {
				if newValue {
					if SMAppService.mainApp.status == .enabled {
						try? SMAppService.mainApp.unregister()
					}

					try SMAppService.mainApp.register()
				} else {
					try SMAppService.mainApp.unregister()
				}
			} catch {
				logger.error("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
			}
		}
	}

	/**
	Whether the app was launched at login.

	- Important: This property must only be checked in `NSApplicationDelegate#applicationDidFinishLaunching`.
	*/
	public static var wasLaunchedAtLogin: Bool {
		let event = NSAppleEventManager.shared().currentAppleEvent
		return event?.eventID == kAEOpenApplication
			&& event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
	}
}

extension LaunchAtLogin {
	public final class Observable: ObservableObject {
		public var isEnabled: Bool {
			get { LaunchAtLogin.isEnabled }
			set {
				LaunchAtLogin.isEnabled = newValue
			}
		}
	}
}

extension LaunchAtLogin {
	/**
	This package comes with a `LaunchAtLogin.Toggle` view which is like the built-in `Toggle` but with a predefined binding and label. Clicking the view toggles “launch at login” for your app.

	```
	struct ContentView: View {
		var body: some View {
			LaunchAtLogin.Toggle()
		}
	}
	```

	The default label is `"Launch at login"`, but it can be overridden for localization and other needs:

	```
	struct ContentView: View {
		var body: some View {
			LaunchAtLogin.Toggle {
				Text("Launch at login")
			}
		}
	}
	```
	*/
	public struct Toggle<Label: View>: View {
		@ObservedObject private var launchAtLogin = LaunchAtLogin.observable
		private let label: Label

		/**
		Creates a toggle that displays a custom label.

		- Parameters:
			- label: A view that describes the purpose of the toggle.
		*/
		public init(@ViewBuilder label: () -> Label) {
			self.label = label()
		}

		public var body: some View {
			SwiftUI.Toggle(isOn: $launchAtLogin.isEnabled) { label }
		}
	}
}

extension LaunchAtLogin.Toggle<Text> {
	/**
	Creates a toggle that generates its label from a localized string key.

	This initializer creates a ``Text`` view on your behalf with the provided `titleKey`.

	- Parameters:
		- titleKey: The key for the toggle's localized title, that describes the purpose of the toggle.
	*/
	public init(_ titleKey: LocalizedStringKey) {
		label = Text(titleKey)
	}

	/**
	Creates a toggle that generates its label from a string.

	This initializer creates a `Text` view on your behalf with the provided `title`.

	- Parameters:
		- title: A string that describes the purpose of the toggle.
	*/
	public init(_ title: some StringProtocol) {
		label = Text(title)
	}

	/**
	Creates a toggle with the default title of `Launch at login`.
	*/
	public init() {
		self.init("Launch at login")
	}
}
