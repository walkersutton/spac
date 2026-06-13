import SwiftUI

enum HUDLayout {
	static let size = NSSize(width: 170, height: 44)
	static let topPadding: CGFloat = 10
	static let sidePadding: CGFloat = 12
	static let cornerRadius: CGFloat = 22
}

struct HUDContent: View {
	let isCapsOn: Bool

	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: isCapsOn ? "capslock.fill" : "capslock")
				.font(.system(size: 14, weight: .semibold))
				.symbolRenderingMode(.hierarchical)

			Text("Caps Lock \(isCapsOn ? "On" : "Off")")
				.font(.system(size: 13, weight: .semibold))
				.lineLimit(1)
				.fixedSize()
		}
		.padding(.horizontal, 16)
		.frame(width: HUDLayout.size.width, height: HUDLayout.size.height)
		.modifier(LiquidGlassPill())
	}
}

/// Applies a Liquid Glass pill background. On macOS 26+ this uses Apple's
/// native `glassEffect` (real refraction + specular edges + adaptive
/// legibility); older systems fall back to a hand-tuned glass material.
private struct LiquidGlassPill: ViewModifier {
	func body(content: Content) -> some View {
		// `glassEffect` only exists in the macOS 26 SDK (Xcode 26 / Swift 6.2).
		// The compiler guard keeps this buildable on older toolchains, where the
		// symbol is absent from the SDK and a runtime `#available` check alone
		// would still fail to compile.
		#if compiler(>=6.2)
		if #available(macOS 26.0, *) {
			content
				// `.primary` lets the glass drive vibrancy/contrast for us.
				.foregroundStyle(.primary)
				.glassEffect(.regular, in: .capsule)
		} else {
			legacy(content)
		}
		#else
		legacy(content)
		#endif
	}

	@ViewBuilder
	private func legacy(_ content: Content) -> some View {
		content
			.foregroundStyle(.white.opacity(0.95))
			.background { LegacyGlassBackground() }
			.clipShape(Capsule(style: .continuous))
			.overlay { SpecularRim() }
			.shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 7)
			.shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)
	}
}

/// Pre-Tahoe approximation of Liquid Glass: behind-window blur plus a
/// light-wrapping sheen that brightens the top edge and the very bottom.
private struct LegacyGlassBackground: View {
	var body: some View {
		ZStack {
			BehindWindowBlurView(cornerRadius: HUDLayout.cornerRadius)

			// Light wrapping over the surface — bright at top, dark mid,
			// a faint catch at the bottom, mimicking a curved glass body.
			LinearGradient(
				stops: [
					.init(color: .white.opacity(0.20), location: 0.0),
					.init(color: .white.opacity(0.04), location: 0.35),
					.init(color: .clear, location: 0.6),
					.init(color: .white.opacity(0.06), location: 1.0)
				],
				startPoint: .top,
				endPoint: .bottom
			)
			.blendMode(.plusLighter)
		}
	}
}

/// A thin specular highlight that traces the rim — strongest along the top
/// edge where light hits, fading around the body. This is the detail that
/// reads as "glass" rather than a flat translucent panel.
private struct SpecularRim: View {
	var body: some View {
		Capsule(style: .continuous)
			.strokeBorder(
				LinearGradient(
					colors: [
						.white.opacity(0.65),
						.white.opacity(0.12),
						.white.opacity(0.0),
						.white.opacity(0.30)
					],
					startPoint: .top,
					endPoint: .bottom
				),
				lineWidth: 0.75
			)
			.blendMode(.plusLighter)
	}
}
