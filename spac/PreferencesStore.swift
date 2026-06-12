import Foundation
import ServiceManagement

final class PreferencesStore: ObservableObject {
	static let shared = PreferencesStore()

	@Published var showMenuBarIcon: Bool {
		didSet { UserDefaults.standard.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon) }
	}

	@Published var launchAtLogin: Bool {
		didSet {
            // SMAppService requires macOS 13.0+
            if #available(macOS 13.0, *) {
                do {
                    if launchAtLogin {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to update launch at login: \(error)")
                }
            }
        }
	}

	private struct Keys {
		static let showMenuBarIcon = "prefs.showMenuBarIcon"
        // No key needed for launchAtLogin as we read from SMAppService directly
	}

	private init() {
		let defaultValue = true
		if UserDefaults.standard.object(forKey: Keys.showMenuBarIcon) == nil {
			UserDefaults.standard.set(defaultValue, forKey: Keys.showMenuBarIcon)
		}
		showMenuBarIcon = UserDefaults.standard.bool(forKey: Keys.showMenuBarIcon)
		
		if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            launchAtLogin = false
        }
	}
}


