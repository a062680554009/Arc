import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: ArcViewModel
    @EnvironmentObject private var subscription: SubscriptionManager

    @State private var showRitual = false
    @State private var showLockedToday = false
    @State private var showPaywall = false
    @State private var showCompletion = false
    @State private var showWeekly = false

    var body: some View {
        let arc = viewModel.arc
        let blocked = ArcEngine.isFreeLimitReached(arc: arc, isSubscribed: subscription.isSubscribed)
        let dayNum = arc.currentDayNumber

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                // Header (identity pressure + micro-narrative progression)
                VStack(spacing: 8) {
                    Text("DAY \(dayNum)")
                        .font(.system(size: 34, weight: .black))
                        .tracking(1)

                    Text(microNarrativeLine(for: dayNum))
                        .font(.title3.weight(.semibold))
                        .opacity(0.9)
                }
                .padding(.top, 12)

                // Controlled Stakes (only at start of arc)
                if dayNum == 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("This is Day 1.")
                            .font(.footnote.weight(.semibold))
                            .opacity(0.95)

                        Text("The version of you that quits\nends here.")
                            .font(.footnote.weight(.semibold))
                            .opacity(0.9)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Miss 3 days.\nBack to zero.")
                            .font(.footnote.weight(.semibold))
                            .opacity(0.9)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .arcCard()
                }

                // Milestone Micro-Narratives (journey beats)
                if dayNum == 7 {
                    milestoneCard(
                        title: "7 Days.",
                        subtitle: "Most people stop here.\nYou’re still standing."
                    )
                }

                if dayNum == 14 {
                    milestoneCard(
                        title: "14 Days.",
                        subtitle: "This isn’t effort anymore.\nIt’s starting to look like you."
                    )
                }

                if dayNum == 21 {
                    milestoneCard(
                        title: "21 Days.",
                        subtitle: "This is who you are now.\nProtect it."
                    )
                }

                if dayNum == 30 {
                    milestoneCard(
                        title: "30 Days.",
                        subtitle: "You built evidence.\nYou can trust yourself."
                    )
                }

                // Reset Notice (if triggered)
                if let notice = viewModel.resetNotice {
                    Text(notice)
                        .font(.footnote.weight(.semibold))
                        .opacity(0.9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .arcCard()
                        .onTapGesture {
                            viewModel.resetNotice = nil
                        }
                }

                // Momentum Visual System
                let completedArcs = UserDefaults.standard.integer(forKey: "completedArcCount")
                let masteryUnlocked = completedArcs >= 3

                let heat = ArcEngine.identityHeat(for: arc)
                let misses = ArcEngine.consecutiveMissesSoFar(for: arc)
                let decay = momentumDecayState(consecutiveMisses: misses)

                FlameArcWidget(
                    tier: arc.momentumTier,
                    identityHeat: heat,
                    heldDays: arc.streak,
                    decay: decay,
                    lockPulseID: viewModel.momentumRingLockPulseID,
                    resetTrigger: viewModel.resetNotice != nil,
                    masteryUnlocked: masteryUnlocked
                )

                ArcProgressBar(currentDay: dayNum, totalDays: ArcEngine.arcLength)

                // Supporting stats (kept minimal)
                HStack(spacing: 12) {
                    stat("Full Days", "\(ArcEngine.fullDaysCount(for: arc))")
                    stat("Days Remaining", "\(max(0, ArcEngine.arcLength - dayNum))")
                }

                Button {
if blocked {
                        showPaywall = true
                    } else {
                        // If today's ritual is already fully completed, show the locked screen.
                        let today = viewModel.dayForCurrent()
                        if today.completion == .full {
                            showLockedToday = true
                        } else {
                            showRitual = true
                        }
                    }
} label: {
    Text("Begin Ritual")
        .frame(maxWidth: .infinity)
}
.buttonStyle(ArcPrimaryButtonStyle())
Button {
                    if blocked { showPaywall = true } else { showWeekly = true }
} label: {
    Text("Weekly Review")
        .frame(maxWidth: .infinity)
}
.buttonStyle(ArcSecondaryButtonStyle())
Button {
                    if blocked { showPaywall = true; return }
                    if viewModel.completeArcIfEligible() { showCompletion = true }
} label: {
    Text("Complete Arc (if eligible)")
        .frame(maxWidth: .infinity)
}
.buttonStyle(ArcSecondaryButtonStyle())
.disabled(!ArcEngine.canCompleteArc(arc) || blocked)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, ArcSpacing.screenPadding)
            .padding(.top, ArcSpacing.lg)
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 8) }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showRitual) {
                RitualView(viewModel: viewModel)
                    .presentationBackground(.black) // or just REMOVE the line entirely
            }

            .fullScreenCover(isPresented: $showLockedToday) {
                TodayLockedView(viewModel: viewModel)
                    .presentationBackground(.black)
            }
          .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showCompletion) { ArcCompletionView(viewModel: viewModel) }
            .sheet(isPresented: $showWeekly) { WeeklyReviewView(viewModel: viewModel) }
            .task { viewModel.refresh() }
        }
    }

    // MARK: - Micro-Narrative Progression

    private func microNarrativeLine(for day: Int) -> String {
        switch day {
        case 1: return "You begin."
        case 2...4: return "Show up again."
        case 5: return "You’re proving something."
        case 6: return "One more day."
        case 7: return "A week. You didn’t flinch."
        case 8...9: return "Keep it boring. Keep it real."
        case 10: return "Discipline is becoming normal."
        case 11...13: return "No hype. Just reps."
        case 14: return "Two weeks. Identity is forming."
        case 15...20: return "You don’t negotiate with weakness."
        case 21: return "This is who you are now."
        case 22...29: return "Protect the streak. Protect the standard."
        case 30: return "You built evidence."
        default: return "Unbreakable is built daily."
        }
    }

    // MARK: - UI Helpers

    private func milestoneCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.weight(.bold))
            Text(subtitle)
                .font(.footnote.weight(.semibold))
                .opacity(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .arcCard()
    }

    private func stat(_ t: String, _ v: String) -> some View {
        VStack(spacing: 6) {
            Text(t).font(.footnote).opacity(0.7)
            Text(v)
                .font(.title2.weight(.bold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .arcCard()
    }
}