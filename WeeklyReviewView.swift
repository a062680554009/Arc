import SwiftUI

struct WeeklyReviewView: View {
    @ObservedObject var viewModel: ArcViewModel
    @State private var nextWeekProtection: String = ""
    @State private var ringPulse: Bool = false
    var body: some View {
        let arc = viewModel.arc

        let ordered = arc.days.sorted { $0.number < $1.number }
        let maxDay = min(arc.currentDayNumber, ordered.count)
        let relevant = Array(ordered.prefix(maxDay))

        let full = relevant.filter { $0.completion == .full }.count
        let partial = relevant.filter { $0.completion == .partial }.count
        let missed = relevant.filter { $0.completion == .missed }.count

        let percent = Int((ArcEngine.completionPercent(for: arc) * 100.0).rounded())
        let weakest = ArcEngine.weakestPillar(for: arc)?.title ?? "—"

        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                let completedArcs = UserDefaults.standard.integer(forKey: "completedArcCount")
                let masteryUnlocked = completedArcs >= 3

                VStack(spacing: 12) {
                    let heat = ArcEngine.identityHeat(for: arc)
                    let misses = ArcEngine.consecutiveMissesSoFar(for: arc)
                    let decay = momentumDecayState(consecutiveMisses: misses)

                    ZStack {
    MomentumRingCoreView(
        heat: heat.value,
        tier: arc.momentumTier,
        masteryUnlocked: masteryUnlocked,
        shattered: false,
        shouldFlicker: decay.shouldRingFlicker,
        glowMultiplier: decay.glowMultiplier,
        lockPulseID: viewModel.momentumRingLockPulseID
    )

    // Promise-kept progress arc (monochrome, stoic)
    Circle()
        .trim(from: 0, to: max(0.02, CGFloat(percent) / 100.0))
        .stroke(
            Color.white.opacity(0.18 + (Double(percent) / 100.0) * 0.22),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .padding(8)
        .animation(.easeOut(duration: 0.6), value: percent)

    FlameView(tier: arc.momentumTier, decay: decay, masteryUnlocked: masteryUnlocked)
        .scaleEffect(1.02)

    // Subtle breath pulse
    Circle()
        .stroke(Color.white.opacity(0.08), lineWidth: 1)
        .scaleEffect(ringPulse ? 1.08 : 1.00)
        .opacity(ringPulse ? 0.0 : 1.0)
        .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false), value: ringPulse)
}
.frame(width: 160, height: 160)
.onAppear { ringPulse = true }

                    Text("Your identity this week: \(arc.momentumTier.title)")
                        .font(.system(size: 22, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Text("""
This week exposed your standard.
That's not shame. That's data.
""")
                        .font(.system(size: 16, weight: .medium))
                        .opacity(0.85)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 22)
                }
                .padding(.bottom, 2)


                HStack(spacing: 12) {
                    card("Full", "\(full)")
                    card("Partial", "\(partial)")
                    card("Missed", "\(missed)")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(mirrorTitle(for: percent))
                        .font(.headline)

                    Text(mirrorBody(for: percent))
                        .font(.footnote.weight(.semibold))
                        .opacity(0.85)

                    Divider()
                        .opacity(0.25)
                        .padding(.vertical, 2)

                    Text("Promise kept rate: \(percent)%")
                        .font(.footnote)
                        .opacity(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weakest pillar: \(weakest)")
                        .font(.headline)

                    Text("This is where your standards are lowest.")
                        .font(.footnote.weight(.semibold))
                        .opacity(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)

                momentumCard(streak: arc.streak)

                // ✅ Transformative Weekly Challenge
                VStack(alignment: .leading, spacing: 10) {
                    Text("Next week, protect this one thing:")
                        .font(.headline)

                    TextField("____", text: $nextWeekProtection)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)

                    Text("Force the decision. Then live up to it.")
                        .font(.footnote.weight(.semibold))
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Weekly Review")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.refresh()
                // Optional: preload from the model if you add persistence later.
                // nextWeekProtection = viewModel.weeklyProtectionText ?? ""
            }
            // Optional: save as user types if you add persistence later.
            // .onChange(of: nextWeekProtection) { newValue in
            //     viewModel.setWeeklyProtection(newValue)
            // }
        }
    }


private func identityRangeLabel(percent: Int) -> String {
    switch percent {
    case 0...20: return "0–20% • DORMANT"
    case 21...50: return "21–50% • UNSTABLE"
    case 51...80: return "51–80% • ACTIVE"
    default: return "81–100% • RELENTLESS"
    }
}

private func momentumCard(streak: Int) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .firstTextBaseline) {
            Text("Momentum")
                .font(.headline)
            Spacer()
            Text("\(streak)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
        }

        Text(streak == 0 ? "Momentum is not given. It's earned." : "Protect the streak. No drift.")
            .font(.footnote.weight(.semibold))
            .opacity(0.85)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.07))
    )
    .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.10), lineWidth: 1)
    )
}

    // MARK: - Mirror Logic

    private func mirrorTitle(for percent: Int) -> String {
        return "Identity Mirror"
    }

    private func mirrorBody(for percent: Int) -> String {
        // Cold but factual. No shame.
        return "This week exposed your standard. That's not shame. That's data."
    }

    // MARK: - UI Components

    private func card(_ t: String, _ v: String) -> some View {
        VStack(spacing: 6) {
            Text(t).font(.footnote).opacity(0.7)
            Text(v).font(.title2.weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }

    private func wide(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t).font(.headline)
            Text(v).font(.headline.weight(.bold))
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
}
