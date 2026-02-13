import SwiftUI

struct TodayLockedView: View {
    @ObservedObject var viewModel: ArcViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let arc = viewModel.arc
        let completedArcs = UserDefaults.standard.integer(forKey: "completedArcCount")
        let masteryUnlocked = completedArcs >= 3

        let heat = ArcEngine.identityHeat(for: arc)
        let misses = ArcEngine.consecutiveMissesSoFar(for: arc)
        let decay = momentumDecayState(consecutiveMisses: misses)
        let today = viewModel.dayForCurrent()


        ZStack {
            ArcTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 18)

                ZStack {
                    MomentumRingCoreView(
                        heat: heat.value,
                        tier: arc.momentumTier,
                        masteryUnlocked: masteryUnlocked,
                        shattered: false,
                        shouldFlicker: false,
                        glowMultiplier: 0.75,   // subtle glow
                        lockPulseID: UUID()
                    )
                    FlameView(tier: arc.momentumTier, decay: decay, masteryUnlocked: masteryUnlocked)
                        .scaleEffect(1.06)      // slightly glowing
                }
                .frame(width: 190, height: 190)
                .padding(.top, 8)

                VStack(spacing: ArcSpacing.md) {
                    DayStatusCard(day: today)
                    PillarProgressRow(day: today)
                }
                .padding(.horizontal, ArcSpacing.screenPadding)

                VStack(spacing: 12) {
                    VStack(spacing: 6) {
                        Text("Momentum Level")
                            .font(.footnote.weight(.semibold))
                            .opacity(0.85)

                        Text(momentumLabel(for: arc.momentumTier))
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundStyle(.white)

                    ArcProgressBar(currentDay: arc.currentDayNumber, totalDays: ArcEngine.arcLength)
                        .padding(.horizontal, 8)

                    Text("Arc \(arc.currentDayNumber)/\(ArcEngine.arcLength)")
                        .font(.footnote.weight(.semibold))
                        .opacity(0.8)
                        .foregroundStyle(.white)
                }
                .padding(.top, 6)
                .padding(.horizontal, 24)

                Spacer()

                Button("Return to Home") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(ArcSecondaryButtonStyle())
                .padding(.horizontal, ArcSpacing.screenPadding)
                .padding(.bottom, 28)
            }
        }
    }

    private func momentumLabel(for tier: MomentumTier) -> String {
        switch tier {
        case .dormant: return "Dormant"
        case .spark: return "Spark"
        case .rising: return "Rising"
        case .burning: return "Burning"
        case .relentless: return "Relentless"
        }
    }
}
