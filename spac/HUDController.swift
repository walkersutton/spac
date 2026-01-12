import Cocoa
import SwiftUI

enum HUDTiming {
	static let fadeIn: TimeInterval = 0.05
	static let fadeOut: TimeInterval = 0.2
	static let maxVisibleAfterEvent: TimeInterval = 0.8
}

final class HUDController {
	private var hudWindow: NSWindow?
    private var hideWorkItem: DispatchWorkItem?

    init() {
        if Thread.isMainThread {
            _ = makeWindowIfNeeded()
        } else {
            DispatchQueue.main.sync { _ = makeWindowIfNeeded() }
        }
    }

	func presentCapsState(_ isCapsOn: Bool) {
		if Thread.isMainThread {
			showHUD(isCapsOn: isCapsOn)
		} else {
			DispatchQueue.main.async { [weak self] in self?.showHUD(isCapsOn: isCapsOn) }
		}
	}

	private func makeWindowIfNeeded() -> NSWindow {
		if let window = hudWindow { return window }
        
        // Expansion to prevent shadow clipping. Total 100pt provides plenty of room.
        let expansion: CGFloat = 100
        
        // 1. Calculate the ideal "pill" frame in screen coordinates
        let primaryScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens.first
        let screenFrame = primaryScreen?.frame ?? .zero
        
        let pillX = screenFrame.maxX - HUDLayout.size.width - HUDLayout.sidePadding
        let pillY = screenFrame.maxY - HUDLayout.size.height - HUDLayout.topPadding
        
        // 2. Expand it to include shadow room, then clamp top/right to screen edges 
        // to prevent OS clamping from moving our internal coordinates.
        var windowFrame = NSRect(x: pillX - expansion/2, 
                               y: pillY - expansion/2, 
                               width: HUDLayout.size.width + expansion, 
                               height: HUDLayout.size.height + expansion)
        
        if windowFrame.maxY > screenFrame.maxY {
            windowFrame.origin.y -= (windowFrame.maxY - screenFrame.maxY)
        }
        if windowFrame.maxX > screenFrame.maxX {
            windowFrame.origin.x -= (windowFrame.maxX - screenFrame.maxX)
        }
        
        let frame = windowFrame

		let panel = NSPanel(contentRect: frame,
							styleMask: [.borderless, .nonactivatingPanel],
							backing: .buffered,
							defer: false)
		panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.overlayWindow)))
		panel.isOpaque = false
		panel.backgroundColor = .clear
		panel.ignoresMouseEvents = true
		panel.hasShadow = false
		panel.becomesKeyOnlyIfNeeded = true
		panel.isFloatingPanel = true
		panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
		
        panel.contentView?.wantsLayer = true
		panel.contentView?.layer?.backgroundColor = .clear
        panel.contentView?.layer?.isOpaque = false

        panel.alphaValue = 0
        panel.orderOut(nil)
		hudWindow = panel
		return panel
	}

	func showHUD(isCapsOn: Bool) {
        let panel = makeWindowIfNeeded()
        
        // Always recalculate positioning to stay in sync with layout constants
        let expansion: CGFloat = 100
        let primaryScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens.first
        let screenFrame = primaryScreen?.frame ?? .zero
        
        let pillX = screenFrame.maxX - HUDLayout.size.width - HUDLayout.sidePadding
        let pillY = screenFrame.maxY - HUDLayout.size.height - HUDLayout.topPadding
        
        var windowFrame = NSRect(x: pillX - expansion/2, 
                               y: pillY - expansion/2, 
                               width: HUDLayout.size.width + expansion, 
                               height: HUDLayout.size.height + expansion)
        
        if windowFrame.maxY > screenFrame.maxY { windowFrame.origin.y -= (windowFrame.maxY - screenFrame.maxY) }
        if windowFrame.maxX > screenFrame.maxX { windowFrame.origin.x -= (windowFrame.maxX - screenFrame.maxX) }
        
        panel.setFrame(windowFrame, display: true)
        
        // Calculate the pill's origin relative to the window's contentView
        let relativeX = pillX - windowFrame.origin.x
        let relativeY = pillY - windowFrame.origin.y
        let pillContentFrame = NSRect(x: relativeX, y: relativeY, width: HUDLayout.size.width, height: HUDLayout.size.height)

        // Refresh content
        if let hosting = panel.contentView?.subviews.first(where: { $0 is NSHostingView<HUDContent> }) as? NSHostingView<HUDContent> {
            hosting.rootView = HUDContent(isCapsOn: isCapsOn)
            hosting.frame = pillContentFrame
        } else {
            let hosting = NSHostingView(rootView: HUDContent(isCapsOn: isCapsOn))
            hosting.frame = pillContentFrame
            hosting.wantsLayer = true
            hosting.layer?.backgroundColor = .clear
            hosting.layer?.isOpaque = false
            panel.contentView?.addSubview(hosting)
        }

        hideWorkItem?.cancel()
        hideWorkItem = nil

        // Bring to front and fade in
        panel.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = HUDTiming.fadeIn
            panel.animator().alphaValue = 1
        }

        restartHideTimer()
	}

	func hideHUD() {
		if !Thread.isMainThread {
			return DispatchQueue.main.async { [weak self] in self?.hideHUD() }
		}
		guard let panel = hudWindow else { return }
        
        hideWorkItem?.cancel()
        hideWorkItem = nil

        NSAnimationContext.runAnimationGroup { context in
            context.duration = HUDTiming.fadeOut
            panel.animator().alphaValue = 0
        } completionHandler: {
            // Check again after animation: did a new showHUD call happen during fade?
            if panel.alphaValue == 0 {
                panel.orderOut(nil)
            }
        }
	}

    private func restartHideTimer() {
        hideWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.hideHUD()
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + HUDTiming.maxVisibleAfterEvent, execute: work)
    }

    deinit {
        hideWorkItem?.cancel()
    }
}


