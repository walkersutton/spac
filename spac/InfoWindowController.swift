import Cocoa
import SwiftUI

// MARK: - Design tokens

struct SpacToken {
	let dark: Bool

	var sidebarBg: Color { dark ? Color(hex: 0x232326) : Color(hex: 0xe7e7ea) }
	var contentBg: Color { dark ? Color(hex: 0x1c1c1e) : Color(hex: 0xf4f4f6) }
	var cardBg: Color { dark ? Color(hex: 0x2b2b2e) : .white }
	var divider: Color { dark ? .white.opacity(0.085) : .black.opacity(0.085) }
	var text: Color { dark ? .white : Color(hex: 0x1b1b1f) }
	var text2: Color {
		dark ? Color(red: 0.922, green: 0.922, blue: 0.961).opacity(0.62)
		     : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.62)
	}
	var text3: Color {
		dark ? Color(red: 0.922, green: 0.922, blue: 0.961).opacity(0.34)
		     : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.40)
	}
	var selBg: Color { dark ? .white.opacity(0.10) : .black.opacity(0.075) }
	var controlBg: Color { dark ? Color(hex: 0x3a3a3d) : .white }
	var controlBorder: Color { dark ? .white.opacity(0.10) : .black.opacity(0.14) }
	var topEdge: Color { dark ? .white.opacity(0.06) : .white.opacity(0.70) }
	var pillBg: Color { dark ? .white.opacity(0.07) : .black.opacity(0.04) }
	var pillBorder: Color { dark ? .white.opacity(0.10) : .black.opacity(0.08) }
}

extension Color {
	init(hex: UInt32) {
		self.init(
			.sRGB,
			red: Double((hex >> 16) & 0xff) / 255,
			green: Double((hex >> 8) & 0xff) / 255,
			blue: Double(hex & 0xff) / 255
		)
	}
}

// MARK: - Shared components

struct SpacSectionLabel: View {
	let title: String
	var spaced: Bool = false
	let t: SpacToken
	init(_ title: String, spaced: Bool = false, t: SpacToken) {
		self.title = title; self.spaced = spaced; self.t = t
	}
	var body: some View {
		Text(title)
			.font(.system(size: 15, weight: .semibold))
			.tracking(-0.15)
			.foregroundStyle(t.text)
			.padding(.top, spaced ? 22 : 0)
			.padding(.bottom, 9)
			.padding(.horizontal, 4)
	}
}

struct SpacCard<Content: View>: View {
	let t: SpacToken
	@ViewBuilder let content: () -> Content
	var body: some View {
		VStack(spacing: 0) { content() }
			.background(t.cardBg)
			.clipShape(RoundedRectangle(cornerRadius: 10))
			.overlay {
				if !t.dark {
					RoundedRectangle(cornerRadius: 10)
						.stroke(Color.black.opacity(0.05), lineWidth: 0.5)
				}
			}
			.shadow(color: !t.dark ? .black.opacity(0.04) : .clear, radius: 2, x: 0, y: 1)
	}
}

struct SpacRow<Control: View>: View {
	let label: String
	var description: String?
	let t: SpacToken
	@ViewBuilder let control: () -> Control
	init(_ label: String, description: String? = nil, t: SpacToken,
	     @ViewBuilder control: @escaping () -> Control) {
		self.label = label; self.description = description; self.t = t; self.control = control
	}
	var body: some View {
		HStack(alignment: .center, spacing: 14) {
			VStack(alignment: .leading, spacing: 2) {
				Text(label)
					.font(.system(size: 14))
					.foregroundStyle(t.text)
				if let desc = description {
					Text(desc)
						.font(.system(size: 12))
						.foregroundStyle(t.text2)
				}
			}
			Spacer()
			control()
		}
		.padding(.horizontal, 14)
		.padding(.vertical, 11)
		.frame(minHeight: 46)
	}
}

struct SpacRowDivider: View {
	let t: SpacToken
	var body: some View {
		Rectangle()
			.fill(t.divider)
			.frame(height: 1)
			.padding(.leading, 14)
	}
}

struct SpacButtonStyle: ButtonStyle {
	let t: SpacToken
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.system(size: 13, weight: .medium))
			.foregroundStyle(t.text)
			.padding(.vertical, 5)
			.padding(.horizontal, 12)
			.background(t.controlBg)
			.clipShape(RoundedRectangle(cornerRadius: 7))
			.overlay {
				RoundedRectangle(cornerRadius: 7)
					.stroke(t.controlBorder, lineWidth: 1)
			}
			.shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
			.opacity(configuration.isPressed ? 0.75 : 1.0)
	}
}

// MARK: - Window controller

private enum InfoTab { case general, about }

@MainActor
final class InfoWindowController: NSWindowController {
	convenience init() {
		let window = InfoWindow(
			contentRect: NSRect(x: 0, y: 0, width: 540, height: 420),
			styleMask: [.titled, .closable, .fullSizeContentView],
			backing: .buffered,
			defer: false
		)
		window.title = "spac"
		window.titlebarAppearsTransparent = true
		window.titleVisibility = .hidden
		window.isReleasedWhenClosed = false
		window.level = .floating
		window.center()
		self.init(window: window)
		window.contentView = NSHostingView(rootView: SpacSettingsRoot())
	}
}

private class InfoWindow: NSWindow {
	override func performKeyEquivalent(with event: NSEvent) -> Bool {
		if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
		   event.charactersIgnoringModifiers?.lowercased() == "w" {
			performClose(nil)
			return true
		}
		return super.performKeyEquivalent(with: event)
	}
}

// MARK: - Root layout

private struct SpacSettingsRoot: View {
	@State private var selectedTab: InfoTab = .general
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		let t = SpacToken(dark: colorScheme == .dark)
		HStack(spacing: 0) {
			SidebarView(selected: $selectedTab, t: t)
				.frame(width: 180)
			ContentArea(selected: $selectedTab, t: t)
		}
		.ignoresSafeArea()
	}
}

// MARK: - Sidebar

private struct SidebarView: View {
	@Binding var selected: InfoTab
	let t: SpacToken

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			NavRow(label: "General", icon: "gearshape", isSelected: selected == .general, t: t) {
				selected = .general
			}
			NavRow(label: "About", icon: "info.circle", isSelected: selected == .about, t: t) {
				selected = .about
			}
			Spacer()
		}
		.padding(.top, 44)
		.padding(.horizontal, 12)
		.padding(.bottom, 12)
		.frame(maxHeight: .infinity)
		.background(t.sidebarBg)
	}
}

private struct NavRow: View {
	let label: String
	let icon: String
	let isSelected: Bool
	let t: SpacToken
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: 10) {
				Image(systemName: icon)
					.font(.system(size: 14, weight: .regular))
					.frame(width: 17, height: 17)
					.foregroundStyle(isSelected ? t.text : t.text2)
				Text(label)
					.font(.system(size: 14))
					.foregroundStyle(t.text)
				Spacer()
			}
			.padding(.vertical, 7)
			.padding(.horizontal, 9)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.background(isSelected ? t.selBg : .clear)
		.clipShape(RoundedRectangle(cornerRadius: 7))
	}
}

// MARK: - Content area

private struct ContentArea: View {
	@Binding var selected: InfoTab
	let t: SpacToken

	var body: some View {
		ZStack(alignment: .topTrailing) {
			switch selected {
			case .general:
				SettingsView(prefs: .shared, updateController: .shared, t: t)
			case .about:
				AboutTab(t: t)
			}

			if selected == .general {
				AppPill(t: t)
					.padding(.top, 14)
					.padding(.trailing, 18)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.overlay(alignment: .top) { t.topEdge.frame(height: 1) }
		.overlay(alignment: .leading) { t.divider.frame(width: 1) }
		.background(t.contentBg)
	}
}

// MARK: - App pill

private struct AppPill: View {
	let t: SpacToken

	var body: some View {
		HStack(spacing: 7) {
			Image(systemName: "capslock")
				.font(.system(size: 11, weight: .medium))
				.foregroundStyle(t.text)
			Text("spac")
				.font(.system(size: 13.5, weight: .semibold))
				.foregroundStyle(t.text)
		}
		.padding(.leading, 9)
		.padding(.trailing, 13)
		.padding(.vertical, 6)
		.background(t.pillBg)
		.clipShape(Capsule())
		.overlay { Capsule().stroke(t.pillBorder, lineWidth: 1) }
	}
}

// MARK: - About tab

private struct AboutTab: View {
	let t: SpacToken
	private let githubURL = URL(string: "https://github.com/walkersutton/spac")!

	var body: some View {
		VStack(spacing: 0) {
			Spacer()

			Image("SettingsLogo")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 86, height: 86)
				.clipShape(RoundedRectangle(cornerRadius: 21))
				.shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 5)

			Text("spac")
				.font(.system(size: 24, weight: .semibold))
				.tracking(-0.36)
				.foregroundStyle(t.text)
				.padding(.top, 18)

			Text("Version \(AppVersion.displayString)")
				.font(.system(size: 13))
				.foregroundStyle(t.text2)
				.padding(.top, 5)

			Text("A minimal Caps Lock indicator that stays out of your way.")
				.font(.system(size: 13))
				.foregroundStyle(t.text2)
				.multilineTextAlignment(.center)
				.frame(maxWidth: 260)
				.padding(.top, 16)

			Link("GitHub", destination: githubURL)
				.foregroundStyle(Color.accentColor)
				.font(.system(size: 13))
				.onHover { inside in
					if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
				}
				.padding(.top, 20)

			Text("© 2025 Walker Sutton")
				.font(.system(size: 12))
				.foregroundStyle(t.text3)
				.padding(.top, 26)

			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(.top, 44)
		.padding(.horizontal, 32)
		.padding(.bottom, 32)
	}
}
