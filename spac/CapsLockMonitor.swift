import Cocoa
import ApplicationServices

final class CapsLockMonitor {
	// CGEvent tap (reliable across app activation states)
	private var eventTap: CFMachPort?
	private var eventTapRunLoopSource: CFRunLoopSource?
    private var lastCapsOn: Bool?
	private var permissionCheckTimer: Timer?
	private var hasShownPermissionAlert = false

	var onChange: ((Bool) -> Void)?

	func start() {
		stop()
		checkAndRequestPermissions()
	}
	
	private func checkAndRequestPermissions() {
		let isTrusted = AXIsProcessTrusted()
		
		if isTrusted {
			// Permissions granted, start monitoring
			installEventTap()
			stopPermissionMonitoring()
		} else {
			// Request permissions with prompt
			let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
			_ = AXIsProcessTrustedWithOptions(options)
			
			// Start monitoring for permission changes FIRST (before showing alert)
			// This ensures the timer is running even if the alert blocks
			startPermissionMonitoring()
			
			// Show alert to guide user
			if !hasShownPermissionAlert {
				hasShownPermissionAlert = true
				showPermissionAlert()
			}
		}
	}
	
	private func showPermissionAlert() {
		DispatchQueue.main.async {
			let alert = NSAlert()
			alert.messageText = "Accessibility Permission Required"
			alert.informativeText = "spac needs Accessibility permissions to monitor your Caps Lock key. Please enable it in System Settings."
			alert.alertStyle = .informational
			alert.addButton(withTitle: "Open System Settings")
			alert.addButton(withTitle: "OK")
			
			let response = alert.runModal()
			if response == .alertFirstButtonReturn {
				// Open System Settings to Accessibility pane
				if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
					NSWorkspace.shared.open(url)
				}
			}
		}
	}
	
	private func startPermissionMonitoring() {
		// Check every 2 seconds if permissions have been granted
		permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			
			if AXIsProcessTrusted() {
				print("[CapsLockMonitor] Permissions granted! Starting event tap...")
				self.installEventTap()
				self.stopPermissionMonitoring()
			}
		}
	}
	
	private func stopPermissionMonitoring() {
		permissionCheckTimer?.invalidate()
		permissionCheckTimer = nil
	}

	func stop() {
		if let eventTap {
			CGEvent.tapEnable(tap: eventTap, enable: false)
		}
		if let eventTapRunLoopSource {
			CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapRunLoopSource, .commonModes)
		}
		eventTapRunLoopSource = nil
		eventTap = nil
		stopPermissionMonitoring()
	}

	private func installEventTap() {
		let mask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
		let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
			if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
				if let monitor = Unmanaged<CapsLockMonitor>.fromOpaque(userInfo!).takeUnretainedValue() as CapsLockMonitor? {
					DispatchQueue.main.async { [weak monitor] in
						if let tap = monitor?.eventTap {
							CGEvent.tapEnable(tap: tap, enable: true)
						}
					}
				}
				return nil
			}

            // Detect every press of the Caps Lock key (keycode 57) to ensure responsiveness
            // even if the system's "long-press" filter prevents a toggle.
            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                if keyCode == 57 { // Caps Lock key
                    if let monitor = Unmanaged<CapsLockMonitor>.fromOpaque(userInfo!).takeUnretainedValue() as CapsLockMonitor? {
                        // Use the ACTUAL current system state at the moment of press.
                        let currentState = NSEvent.modifierFlags.contains(.capsLock)
                        monitor.lastCapsOn = currentState
                        DispatchQueue.main.async {
                            monitor.onChange?(currentState)
                        }
                    }
                    return Unmanaged.passUnretained(event)
                }
            }

			guard type == .flagsChanged else { return Unmanaged.passUnretained(event) }

			// Read caps state directly from the CGEvent's flags for reliability.
			let flags = event.flags
			let capsOn = flags.contains(.maskAlphaShift)

			if let monitor = Unmanaged<CapsLockMonitor>.fromOpaque(userInfo!).takeUnretainedValue() as CapsLockMonitor? {
                // Emit on every flagsChanged that results in a bit change.
				if monitor.lastCapsOn != capsOn {
					monitor.lastCapsOn = capsOn
					DispatchQueue.main.async {
						monitor.onChange?(capsOn)
					}
				}
			}
			return Unmanaged.passUnretained(event)
		}

		let userInfo = Unmanaged.passUnretained(self).toOpaque()

		if let tap = CGEvent.tapCreate(
			tap: .cgSessionEventTap,
			place: .headInsertEventTap,
			options: .defaultTap,
			eventsOfInterest: CGEventMask(mask),
			callback: callback,
			userInfo: userInfo
		) {
            print("[CapsLockMonitor] Event tap created successfully.")
			eventTap = tap
			if let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) {
				eventTapRunLoopSource = source
				CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
				CGEvent.tapEnable(tap: tap, enable: true)

				// Initialize state tracking without triggering HUD
				let initialCapsOn = NSEvent.modifierFlags.contains(.capsLock)
				DispatchQueue.main.async { [weak self] in
					self?.lastCapsOn = initialCapsOn
				}
			}
		}
	}

	deinit {
		stop()
	}
}
