import SwiftUI

/// Secondary action: quiet outline, still big + tappable.
struct ArcSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(ArcTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: ArcTheme.secondaryButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: ArcTheme.radiusMD, style: .continuous)
                    .fill(ArcTheme.Colors.surface.opacity(configuration.isPressed ? 0.86 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ArcTheme.radiusMD, style: .continuous)
                    .stroke(ArcTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
            .accessibilityAddTraits(.isButton)
    }
}
