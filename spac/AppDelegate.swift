import SwiftUI
import Cocoa
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
	var statusItem: NSStatusItem?
	private let hudController = HUDController()
	private let capsMonitor = CapsLockMonitor()
	private let updateController = UpdateController.shared
    private var prefs = PreferencesStore.shared
    private var subscriptions = Set<AnyCancellable>()
    private var infoWindowController: InfoWindowController?

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
        if infoWindowController == nil {
            infoWindowController = InfoWindowController()
        }
        infoWindowController?.window?.makeKeyAndOrderFront(nil)
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
