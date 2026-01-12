import Cocoa
import SwiftUI

final class InfoWindowController: NSWindowController {
	convenience init() {
		let windowSize = NSSize(width: 400, height: 200)
		let screen = NSScreen.main
		let origin = NSPoint(
			x: max(0, ((screen?.frame.width ?? windowSize.width) - windowSize.width) / 2),
			y: max(0, ((screen?.frame.height ?? windowSize.height) - windowSize.height) / 2)
		)
		let frame = NSRect(origin: origin, size: windowSize)
		let window = NSWindow(
			contentRect: frame,
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)
		window.level = .floating
		window.title = "spac"
		window.isReleasedWhenClosed = false
		self.init(window: window)
		buildContent()
	}

	private func buildContent() {
		guard let contentView = window?.contentView else { return }
		let tabView = NSTabView(frame: contentView.bounds)
		tabView.autoresizingMask = [.width, .height]

		let aboutTab = NSTabViewItem(identifier: "About")
		aboutTab.label = "About"
		let aboutView = NSStackView()
		aboutView.orientation = .vertical
		aboutView.alignment = .centerX
		aboutView.spacing = 8
		aboutView.translatesAutoresizingMaskIntoConstraints = false

		let versionString: String = {
			let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
			let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
			return [version, build].filter { !$0.isEmpty }.joined(separator: " (") + (build.isEmpty ? "" : ")")
		}()

		let titleLabel = NSTextField(labelWithString: "spac \(versionString)")
		titleLabel.font = .boldSystemFont(ofSize: 13)
		titleLabel.alignment = .center
		aboutView.addArrangedSubview(titleLabel)

		let linkField = NSTextField(labelWithAttributedString: {
			let urlString = "https://github.com/walkersutton/spac"
			let attributed = NSMutableAttributedString(string: "GitHub: \(urlString)")
			attributed.addAttributes([
				.link: URL(string: urlString) as Any,
				.foregroundColor: NSColor.linkColor,
				.underlineStyle: NSUnderlineStyle.single.rawValue
			], range: NSRange(location: 8, length: urlString.count))
			return attributed
		}())
		linkField.allowsEditingTextAttributes = true
		linkField.isSelectable = true
		linkField.alignment = .center
		aboutView.addArrangedSubview(linkField)

		let hintLabel = NSTextField(labelWithString: "Press ⌘Q to quit.")
		hintLabel.alignment = .center
		aboutView.addArrangedSubview(hintLabel)

		aboutTab.view = aboutView

		let settingsTab = NSTabViewItem(identifier: "Settings")
		settingsTab.label = "Settings"
		let hosting = NSHostingView(rootView: SettingsView(prefs: .shared))
		hosting.frame = contentView.bounds
		hosting.autoresizingMask = [.width, .height]
		settingsTab.view = hosting

		tabView.addTabViewItem(aboutTab)
		tabView.addTabViewItem(settingsTab)
		contentView.addSubview(tabView)
	}
}


