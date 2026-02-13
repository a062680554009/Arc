import SwiftUI

/// Premium card surface: subtle elevation + stroke, tuned for calm dark UI.
struct ArcCardModifier: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(ArcSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: ArcTheme.radiusLG, style: .continuous)
                    .fill(elevated ? ArcTheme.Colors.surfaceElevated : ArcTheme.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ArcTheme.radiusLG, style: .continuous)
                    .stroke(ArcTheme.Colors.borderUltraSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(elevated ? 0.16 : 0.10), radius: elevated ? 18 : 14, x: 0, y: elevated ? 12 : 10)
    }
}

extension View {
    func arcCard(elevated: Bool = false) -> some View {
        self.modifier(ArcCardModifier(elevated: elevated))
    }
}
