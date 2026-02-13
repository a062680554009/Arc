import SwiftUI

// MARK: - UI Mapping

extension DayCompletion {
    var uiTitle: String {
        switch self {
        case .missed: return "Incomplete"
        case .partial: return "Partial Progress"
        case .full: return "Locked"
        }
    }

    var uiIcon: String {
        switch self {
        case .missed: return "circle"
        case .partial: return "circle.lefthalf.filled"
        case .full: return "checkmark.circle.fill"
        }
    }

    var uiAccent: Color {
        switch self {
        case .missed: return ArcTheme.Colors.textSecondary
        case .partial: return ArcTheme.Colors.brand
        case .full: return ArcTheme.Colors.brand
        }
    }
}

private extension ArcDay {
    func isPillarComplete(_ type: PillarType) -> Bool {
        switch type {
        case .forge: return forgeCompleted
        case .temper: return temperCompleted
        case .align: return alignCompleted
        }
    }

    var pillarsCompleteCount: Int { completedCount }
}

// MARK: - Day Completion Panel

/// Reusable Day Completion System UI.
/// Use on Home, Ritual summary, and Today Locked screens.
struct DayCompletionPanel: View {
    let day: ArcDay
    var primaryActionTitle: String
    var primaryAction: (() -> Void)?

    init(day: ArcDay, primaryActionTitle: String = "Complete Today", primaryAction: (() -> Void)? = nil) {
        self.day = day
        self.primaryActionTitle = primaryActionTitle
        self.primaryAction = primaryAction
    }

    var body: some View {
        VStack(spacing: ArcSpacing.blockSpacing) {
            DayStatusCard(day: day)

            PillarProgressRow(day: day)

            if let primaryAction {
                Button(action: primaryAction) {
                    Text(primaryActionTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ArcPrimaryButtonStyle())
                .accessibilityLabel(primaryActionTitle)
            }
        }
        .padding(.top, ArcSpacing.xl)
        .padding(.horizontal, ArcSpacing.screenPadding)
    }
}

// MARK: - Status Card

struct DayStatusCard: View {
    let day: ArcDay

    private var subtitle: String {
        switch day.completion {
        case .missed:
            return "Complete one task in each pillar—Body, Mind, and Direction—to lock today."
        case .partial:
            let remaining = max(0, 3 - day.pillarsCompleteCount)
            if remaining == 1 {
                return "2 of 3 pillars activated. One more to lock the day."
            } else {
                return "\(day.pillarsCompleteCount) of 3 pillars activated. Keep going to lock today."
            }
        case .full:
            return "All pillars aligned. Day secured."
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: ArcTheme.radiusXL, style: .continuous)
            .fill(day.completion == .full ? ArcTheme.Colors.surfaceElevated : ArcTheme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ArcTheme.radiusXL, style: .continuous)
                    .stroke(day.completion == .missed ? ArcTheme.Colors.borderUltraSubtle : ArcTheme.Colors.borderSubtle, lineWidth: 1)
                    .opacity(day.completion == .full ? 0.0 : 1.0)
            )
            .overlay(
                // Warm overlay for locked state (very subtle)
                RoundedRectangle(cornerRadius: ArcTheme.radiusXL, style: .continuous)
                    .fill(ArcTheme.Colors.brand.opacity(0.08))
                    .opacity(day.completion == .full ? 1.0 : 0.0)
            )
    }

    var body: some View {
        HStack(alignment: .top, spacing: ArcSpacing.lg) {
            VStack(alignment: .leading, spacing: ArcSpacing.sm) {
                Text(day.completion.uiTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(day.completion == .full ? ArcTheme.Colors.brand : ArcTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ArcTheme.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 0)

            Image(systemName: day.completion.uiIcon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(day.completion.uiAccent)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, ArcSpacing.cardPadding)
        .padding(.vertical, ArcSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(background)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(day.completion.uiTitle). \(subtitle)")
    }
}

// MARK: - Pillar Row

struct PillarProgressRow: View {
    let day: ArcDay

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: ArcSpacing.md), count: 3)

        LazyVGrid(columns: columns, spacing: ArcSpacing.md) {
            ForEach(PillarType.allCases) { type in
                PillarProgressCard(type: type, isActive: day.isPillarComplete(type))
            }
        }
    }
}

struct PillarProgressCard: View {
    let type: PillarType
    let isActive: Bool

    private var label: String {
        isActive ? "Activated" : "Not activated"
    }

    private var accessibilityValue: String {
        isActive ? "Activated" : "Not activated"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ArcSpacing.md) {
            HStack(spacing: 10) {
                Image(systemName: icon(for: type))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? ArcTheme.Colors.pillarAccent(type) : ArcTheme.Colors.textSecondary)
                    .accessibilityHidden(true)

                Text(type.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(ArcTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .allowsTightening(true)

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                CompletionRing(
                    isActive: isActive,
                    accent: isActive ? ArcTheme.Colors.pillarAccent(type) : ArcTheme.Colors.textSecondary
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isActive ? ArcTheme.Colors.pillarAccent(type) : ArcTheme.Colors.textSecondary)

                    Text(subtitle(for: type))
                        .font(.caption)
                        .foregroundStyle(ArcTheme.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(ArcSpacing.md)
        .frame(maxWidth: .infinity)
        .frame(height: 148, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ArcTheme.radiusLG, style: .continuous)
                .fill(isActive ? ArcTheme.Colors.pillarTint(type) : ArcTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ArcTheme.radiusLG, style: .continuous)
                .stroke(isActive ? ArcTheme.Colors.pillarAccent(type).opacity(0.25) : ArcTheme.Colors.borderUltraSubtle, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(type.title)
        .accessibilityValue(accessibilityValue)
    }

    private func subtitle(for type: PillarType) -> String {
        switch type {
        case .forge: return "Body"
        case .temper: return "Mind"
        case .align: return "Direction"
        }
    }

    private func icon(for type: PillarType) -> String {
        switch type {
        case .forge: return "flame"
        case .temper: return "brain.head.profile"
        case .align: return "scope"
        }
    }
}

// MARK: - Ring

struct CompletionRing: View {
    let isActive: Bool
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(ArcTheme.Colors.borderSubtle, lineWidth: 3)

            Circle()
                .trim(from: 0, to: isActive ? 1 : 0)
                .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: isActive)
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}
