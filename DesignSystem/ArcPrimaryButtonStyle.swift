import SwiftUI

/// Primary CTA: warm brand fill, high legibility, calm motion.
/// Designed for conversion without looking gamified.
struct ArcPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.black.opacity(0.92))
            .frame(maxWidth: .infinity)
            .frame(height: ArcTheme.primaryButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: ArcTheme.radiusMD, style: .continuous)
                    .fill(ArcTheme.Colors.brand.opacity(configuration.isPressed ? 0.92 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ArcTheme.radiusMD, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.0 : 0.18), radius: 12, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
            .accessibilityAddTraits(.isButton)
    }
}
