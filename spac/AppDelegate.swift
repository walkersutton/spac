import SwiftUI
import Cocoa
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
	var statusItem: NSStatusItem?
	private let hudController = HUDController()
	private let capsMonitor = CapsLockMonitor()
    private var prefs = PreferencesStore.shared
    private var subscriptions = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?

	func applicationDidFinishLaunching(_ notification: Notification) {
		
        setupMenuBar()
        
		capsMonitor.onChange = { [weak self] isOn in
			self?.hudController.presentCapsState(isOn)
		}
		capsMonitor.start()
        
        // React to preferences
        prefs.$showMenuBarIcon.sink { [weak self] show in
            self?.statusItem?.isVisible = show
        }.store(in: &subscriptions)
        
        prefs.$showDockIcon.sink { show in
            let policy: NSApplication.ActivationPolicy = show ? .regular : .accessory
            NSApp.setActivationPolicy(policy)
            // If switching to regular, we usually need to force an activation signal
            // for the icon to reliably snap into the Dock.
            if show {
                NSApp.activate(ignoringOtherApps: true)
            }
        }.store(in: &subscriptions)
        
        // Open settings on launch
        showSettings()
	}

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "capslock.fill", accessibilityDescription: nil)
        }
        
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit spac", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Settings")
        window.title = "spac Settings"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(prefs: prefs))
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }

}

extension CALayer {
	func animate(from: Any?, to: Any?, keyPath: String, duration: TimeInterval) {
		let animation = CABasicAnimation(keyPath: keyPath)
		animation.fromValue = from
		animation.toValue = to
		animation.duration = duration
		animation.fillMode = .both
		animation.isRemovedOnCompletion = true
		animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
		add(animation, forKey: keyPath)
	}
}
