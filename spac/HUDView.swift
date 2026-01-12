import Cocoa

enum HUDLayout {
	static let size = NSSize(width: 170, height: 44)
	static let topPadding: CGFloat = 10
	static let sidePadding: CGFloat = 12
	static let cornerRadius: CGFloat = 14
}

final class HUDView: NSView {
	private let iconView = NSImageView()
	private let label = NSTextField(labelWithString: "")

	init(isCapsOn: Bool, frame: NSRect) {
		super.init(frame: frame)
		wantsLayer = true
		buildViewHierarchy()
		update(isCapsOn: isCapsOn)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) { nil }

	func update(isCapsOn: Bool) {
		label.stringValue = "Caps Lock \(isCapsOn ? "On" : "Off")"
	}

	private func buildViewHierarchy() {
		let blurView = NSVisualEffectView(frame: bounds)
		blurView.autoresizingMask = [.width, .height]
		blurView.material = .hudWindow
		blurView.blendingMode = .behindWindow
		blurView.state = .active
		blurView.wantsLayer = true
		blurView.layer?.cornerRadius = HUDLayout.cornerRadius
		blurView.layer?.masksToBounds = true
		addSubview(blurView)


		let container = NSStackView()
		container.orientation = .horizontal
		container.alignment = .centerY
		container.distribution = .fillProportionally
		container.spacing = 4
		container.translatesAutoresizingMaskIntoConstraints = false
		blurView.addSubview(container)

		NSLayoutConstraint.activate([
			container.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: 10),
			container.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -10),
			container.centerYAnchor.constraint(equalTo: blurView.centerYAnchor)
		])

		iconView.image = NSImage(systemSymbolName: "capslock.fill", accessibilityDescription: nil)
		iconView.contentTintColor = .white
		iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
		container.addArrangedSubview(iconView)

		label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
		label.textColor = .white
		label.backgroundColor = .clear
		label.isBezeled = false
		label.alignment = .center
		container.addArrangedSubview(label)
	}
}


