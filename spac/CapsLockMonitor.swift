import Cocoa
import ApplicationServices

final class CapsLockMonitor {
	// CGEvent tap (reliable across app activation states)
	private var eventTap: CFMachPort?
	private var eventTapRunLoopSource: CFRunLoopSource?
    private var lastCapsOn: Bool?

	var onChange: ((Bool) -> Void)?

	func start() {
		stop()
		requestAccessibilityTrustIfNeeded()
		installEventTap()
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
	}

	private func requestAccessibilityTrustIfNeeded() {
		let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
		_ = AXIsProcessTrustedWithOptions(options)
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
