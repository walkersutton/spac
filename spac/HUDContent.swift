import SwiftUI

struct HUDContent: View {
	let isCapsOn: Bool

	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: isCapsOn ? "capslock.fill" : "capslock")
				.font(.system(size: 14, weight: .semibold))
				.foregroundStyle(.white.opacity(0.95))
				.symbolRenderingMode(.hierarchical)

			Text("Caps Lock \(isCapsOn ? "On" : "Off")")
				.font(.system(size: 13, weight: .semibold))
				.foregroundStyle(.white.opacity(0.95))
				.lineLimit(1)
				.fixedSize()
		}
		.padding(.horizontal, 16)
		.frame(width: HUDLayout.size.width, height: HUDLayout.size.height)
		.background {
			ZStack {
				BehindWindowBlurView(cornerRadius: HUDLayout.cornerRadius)

				// Subtle inner highlight for "liquid" feel
				RoundedRectangle(cornerRadius: HUDLayout.cornerRadius, style: .continuous)
					.stroke(
						LinearGradient(
							colors: [.white.opacity(0.25), .white.opacity(0.05), .white.opacity(0.12)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 0.5
					)

				// Inner dark ring for depth
				RoundedRectangle(cornerRadius: HUDLayout.cornerRadius, style: .continuous)
					.stroke(.black.opacity(0.1), lineWidth: 1)
					.blur(radius: 0.5)
					.mask(RoundedRectangle(cornerRadius: HUDLayout.cornerRadius, style: .continuous))
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: HUDLayout.cornerRadius, style: .continuous))
		.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
	}
}


