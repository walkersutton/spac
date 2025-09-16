import SwiftUI
import Cocoa

// MARK: - HUDController
class HUDController {
	private var hudWindow: NSWindow?
	private var hudTimer: Timer?

	func showHUD(isCapsOn: Bool) {
		if let panel = hudWindow {
			panel.orderOut(nil)
			hudWindow = nil
		}
		hudTimer?.invalidate()
		hudTimer = nil

		guard let screen = NSScreen.main else { return }
		let hudSize = NSSize(width: 130, height: 40)
		let topPadding: CGFloat = 41
		let sidePadding: CGFloat = 290
		let frame = NSRect(
			x: screen.frame.width - hudSize.width - sidePadding,
			y: screen.frame.height - hudSize.height - topPadding,
			width: hudSize.width,
			height: hudSize.height
		)

		let panel = NSPanel(contentRect: frame,
							styleMask: [.borderless, .nonactivatingPanel],
							backing: .buffered,
							defer: false)
		panel.level = .floating
		panel.isOpaque = false
		panel.backgroundColor = .clear
		panel.ignoresMouseEvents = true
		panel.hasShadow = true
		panel.becomesKeyOnlyIfNeeded = true
		panel.isFloatingPanel = true
		panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
		hudWindow = panel

		let contentView = HUDViewBuilder.buildHUDView(isCapsOn: isCapsOn, size: frame.size)
		panel.contentView?.addSubview(contentView)

		panel.makeKeyAndOrderFront(nil)

		contentView.alphaValue = 0
		NSAnimationContext.runAnimationGroup { context in
			context.duration = 0.2
			contentView.animator().alphaValue = 1
		}

		let hideDelay = isCapsOn ? 1.5 : 0.8
		hudTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { [weak self] _ in
			self?.hideHUD()
		}
	}

	func hideHUD() {
		guard let panel = hudWindow else { return }
		hudTimer?.invalidate()
		hudTimer = nil

		if let contentView = panel.contentView?.subviews.first {
			NSAnimationContext.runAnimationGroup { context in
				context.duration = 0.25
				contentView.animator().alphaValue = 0
			} completionHandler: {
				panel.orderOut(nil)
				self.hudWindow = nil
			}
		} else {
			panel.orderOut(nil)
			hudWindow = nil
		}
	}
}

// MARK: - HUDViewBuilder
struct HUDViewBuilder {
	static func buildHUDView(isCapsOn: Bool, size: NSSize) -> NSView {
		let blurView = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
		blurView.autoresizingMask = [.width, .height]
		blurView.material = .hudWindow
		blurView.blendingMode = .behindWindow
		blurView.state = .active
		blurView.wantsLayer = true
		blurView.layer?.cornerRadius = 18
		blurView.layer?.masksToBounds = true

		let overlay = NSView(frame: blurView.bounds)
		overlay.autoresizingMask = [.width, .height]
		overlay.wantsLayer = true
		overlay.layer?.backgroundColor = NSColor(white: 0.86, alpha: 0.1).cgColor
		overlay.layer?.cornerRadius = 18
		blurView.addSubview(overlay)

		let container = NSStackView()
		container.orientation = .horizontal
		container.alignment = .centerY
		container.distribution = .fillProportionally
		container.spacing = 4
		container.translatesAutoresizingMaskIntoConstraints = false
		overlay.addSubview(container)

		NSLayoutConstraint.activate([
			container.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 10),
			container.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -10),
			container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
		])

		let imageView = NSImageView()
		imageView.image = NSImage(systemSymbolName: "capslock.fill", accessibilityDescription: nil)
		imageView.contentTintColor = .white
		imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
		container.addArrangedSubview(imageView)

		let label = NSTextField(labelWithString: "Caps Lock \(isCapsOn ? "On" : "Off")")
		label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
		label.textColor = .white
		label.backgroundColor = .clear
		label.isBezeled = false
		label.alignment = .center
		container.addArrangedSubview(label)

		return blurView
	}
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
	var statusItem: NSStatusItem?
	var infoWindow: NSWindow?
	var hudController = HUDController()
	var previousCapsState = false

	func applicationDidFinishLaunching(_ notification: Notification) {
		setupMenuBar()
		startCapsLockMonitor()
	}

	func setupMenuBar() {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		if let button = statusItem?.button {
			button.image = NSImage(systemSymbolName: "capslock.fill", accessibilityDescription: nil)
		}

		let menu = NSMenu()
		menu.addItem(NSMenuItem(title: "About spac", action: #selector(showInfo), keyEquivalent: ""))
		menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showInfo), keyEquivalent: ""))
		menu.addItem(NSMenuItem.separator())
		menu.addItem(NSMenuItem(title: "Quit spac", action: #selector(quit), keyEquivalent: ""))

		statusItem?.menu = menu
	}

	@objc func showInfo() {
		guard infoWindow == nil, let screen = NSScreen.main else { return }

		let windowSize = NSSize(width: 400, height: 200)
		let frame = NSRect(
			x: (screen.frame.width - windowSize.width) / 2,
			y: (screen.frame.height - windowSize.height) / 2,
			width: windowSize.width,
			height: windowSize.height
		)

		let window = NSWindow(
			contentRect: frame,
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)
		window.level = .floating
		window.title = "spac"
		window.isReleasedWhenClosed = false
		infoWindow = window

		// NSTabView
		let tabView = NSTabView(frame: window.contentView!.bounds)
		tabView.autoresizingMask = [.width, .height]

		// About tab
		let aboutTab = NSTabViewItem(identifier: "About")
		aboutTab.label = "About"
		let aboutView = NSStackView()
		aboutView.orientation = .vertical
		aboutView.alignment = .centerX
		aboutView.spacing = 8
		aboutView.translatesAutoresizingMaskIntoConstraints = false
		let aboutLabel = NSTextField(labelWithString: "Press ⌘Q to quit.\nGitHub: github.com/yourrepo")
		aboutLabel.alignment = .center
		aboutLabel.isSelectable = true
		aboutView.addArrangedSubview(aboutLabel)
		aboutTab.view = aboutView

		// Settings tab
		let settingsTab = NSTabViewItem(identifier: "Settings")
		settingsTab.label = "Settings"
		let settingsView = NSStackView()
		settingsView.orientation = .vertical
		settingsView.alignment = .centerX
		settingsView.spacing = 8
		settingsView.translatesAutoresizingMaskIntoConstraints = false
		let settingsLabel = NSTextField(labelWithString: "Settings placeholder")
		settingsLabel.alignment = .center
		settingsView.addArrangedSubview(settingsLabel)
		settingsTab.view = settingsView

		tabView.addTabViewItem(aboutTab)
		tabView.addTabViewItem(settingsTab)
		window.contentView?.addSubview(tabView)

		window.makeKeyAndOrderFront(nil)
	}


	@objc func quit() {
		NSApp.terminate(nil)
	}

	func showInfoWindow() {
		guard infoWindow == nil, let screen = NSScreen.main else { return }

		let windowSize = NSSize(width: 300, height: 120)
		let frame = NSRect(
			x: (screen.frame.width - windowSize.width) / 2,
			y: (screen.frame.height - windowSize.height) / 2,
			width: windowSize.width,
			height: windowSize.height
		)

		let window = NSWindow(contentRect: frame,
							  styleMask: [.titled, .closable],
							  backing: .buffered,
							  defer: false)
		window.level = .floating
		window.title = "Caps Lock HUD"
		window.isReleasedWhenClosed = false
		infoWindow = window

		let contentView = NSStackView()
		contentView.orientation = .vertical
		contentView.alignment = .centerX
		contentView.spacing = 8
		contentView.translatesAutoresizingMaskIntoConstraints = false
		window.contentView?.addSubview(contentView)
		NSLayoutConstraint.activate([
			contentView.centerXAnchor.constraint(equalTo: window.contentView!.centerXAnchor),
			contentView.centerYAnchor.constraint(equalTo: window.contentView!.centerYAnchor)
		])

		let label = NSTextField(labelWithString: "Press ⌘Q to quit.\nEnable menu bar icon in settings.\nGitHub: github.com/yourrepo")
		label.alignment = .center
		label.isSelectable = true
		contentView.addArrangedSubview(label)

		window.makeKeyAndOrderFront(nil)
	}

	func startCapsLockMonitor() {
		NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
			self?.flagsChanged(event: event)
		}
		NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
			self?.flagsChanged(event: event)
			return event
		}
	}

	func flagsChanged(event: NSEvent) {
		let currentCapsState = event.modifierFlags.contains(.capsLock)
		if currentCapsState != previousCapsState {
			hudController.showHUD(isCapsOn: currentCapsState)
			previousCapsState = currentCapsState
		}
	}
}

// MARK: - CALayer Animation Extension
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
