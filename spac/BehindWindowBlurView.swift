import SwiftUI
import AppKit

struct BehindWindowBlurView: NSViewRepresentable {
	let cornerRadius: CGFloat

	func makeNSView(context: Context) -> NSVisualEffectView {
		let v = NSVisualEffectView()
		v.material = .hudWindow
		v.state = .active
		v.blendingMode = .behindWindow
		v.wantsLayer = true
		v.layer?.cornerRadius = cornerRadius
		v.layer?.masksToBounds = true
		// Enable vibrancy by setting the appearance to dark (system standard for HUDs)
		v.appearance = NSAppearance(named: .vibrantDark)
		return v
	}

	func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
		nsView.material = .hudWindow
		nsView.state = .active
		nsView.blendingMode = .behindWindow
		nsView.layer?.cornerRadius = cornerRadius
		nsView.appearance = NSAppearance(named: .vibrantDark)
	}
}


