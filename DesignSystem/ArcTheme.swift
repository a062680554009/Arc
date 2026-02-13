import SwiftUI

/// Central design tokens for Arc.
/// Dark-mode first, with adaptive light-mode values for accessibility.
enum ArcTheme {

    // MARK: - Layout
    static let screenPadding: CGFloat = ArcSpacing.screenPadding

    // MARK: - Radii
    static let radiusXL: CGFloat = 24
    static let radiusLG: CGFloat = 20
    static let radiusMD: CGFloat = 16
    static let radiusSM: CGFloat = 12

    // MARK: - Control sizing
    static let primaryButtonHeight: CGFloat = 56
    static let secondaryButtonHeight: CGFloat = 48

    // MARK: - Colors (semantic)
    enum Colors {

        // Base neutrals
        static let background = Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(red: 0.055, green: 0.059, blue: 0.071, alpha: 1.0) : UIColor.systemBackground
        })

        static let surface = Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(red: 0.102, green: 0.110, blue: 0.129, alpha: 1.0) : UIColor.secondarySystemBackground
        })

        static let surfaceElevated = Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(red: 0.141, green: 0.149, blue: 0.176, alpha: 1.0) : UIColor.tertiarySystemBackground
        })

        static let borderSubtle = Color.primary.opacity(0.12)
        static let borderUltraSubtle = Color.primary.opacity(0.08)

        // Text
        static let textPrimary = Color.primary.opacity(0.94)
        static let textSecondary = Color.primary.opacity(0.68)
        static let textDisabled = Color.primary.opacity(0.38)

        // Brand (warm, premium—no neon)
        static let brand = Color(uiColor: UIColor { t in
            // Burnt amber
            t.userInterfaceStyle == .dark ? UIColor(red: 0.965, green: 0.565, blue: 0.204, alpha: 1.0) : UIColor(red: 0.82, green: 0.37, blue: 0.09, alpha: 1.0)
        })

        static let brandSoft = brand.opacity(0.10)
        static let brandSurface = brand.opacity(0.06)

        // Pillar accents (only used as subtle tints)
        static let forge = Color(uiColor: UIColor { _ in UIColor(red: 0.965, green: 0.565, blue: 0.204, alpha: 1.0) }).opacity(0.16)  // Body
        static let temper = Color(uiColor: UIColor { _ in UIColor(red: 0.340, green: 0.620, blue: 0.920, alpha: 1.0) }).opacity(0.16) // Mind
        static let align = Color(uiColor: UIColor { _ in UIColor(red: 0.620, green: 0.520, blue: 0.960, alpha: 1.0) }).opacity(0.16)  // Direction

        static func pillarTint(_ type: PillarType) -> Color {
            switch type {
            case .forge: return forge
            case .temper: return temper
            case .align: return align
            }
        }

        static func pillarAccent(_ type: PillarType) -> Color {
            switch type {
            case .forge: return Color(uiColor: UIColor(red: 0.965, green: 0.565, blue: 0.204, alpha: 1.0))
            case .temper: return Color(uiColor: UIColor(red: 0.340, green: 0.620, blue: 0.920, alpha: 1.0))
            case .align: return Color(uiColor: UIColor(red: 0.620, green: 0.520, blue: 0.960, alpha: 1.0))
            }
        }
    }
}
