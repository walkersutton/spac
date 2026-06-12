import SwiftUI

struct DialogTabButton<Label: View>: View {
	let isSelected: Bool
	let action: () -> Void
	let alignment: Alignment
	let cornerRadius: CGFloat
	let selectedBackground: Color
	let selectedForeground: Color
	let normalForeground: Color
	let horizontalPadding: CGFloat
	let verticalPadding: CGFloat
	@ViewBuilder let label: () -> Label

	init(
		isSelected: Bool,
		alignment: Alignment = .leading,
		cornerRadius: CGFloat = 6,
		selectedBackground: Color = .accentColor,
		selectedForeground: Color = .white,
		normalForeground: Color = .primary,
		horizontalPadding: CGFloat = 10,
		verticalPadding: CGFloat = 6,
		action: @escaping () -> Void,
		@ViewBuilder label: @escaping () -> Label
	) {
		self.isSelected = isSelected
		self.action = action
		self.alignment = alignment
		self.cornerRadius = cornerRadius
		self.selectedBackground = selectedBackground
		self.selectedForeground = selectedForeground
		self.normalForeground = normalForeground
		self.horizontalPadding = horizontalPadding
		self.verticalPadding = verticalPadding
		self.label = label
	}

	var body: some View {
		Button(action: action) {
			label()
				.foregroundColor(isSelected ? selectedForeground : normalForeground)
				.padding(.vertical, verticalPadding)
				.padding(.horizontal, horizontalPadding)
				.frame(maxWidth: .infinity, alignment: alignment)
				.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.background(isSelected ? selectedBackground : Color.clear)
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
	}
}
