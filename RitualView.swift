import SwiftUI
import UIKit
import AVFoundation

// MARK: - Haptics helper (micro-dopamine)

enum Haptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }

    static func soft() {
        if #available(iOS 17.0, *) { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        else { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }

    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

// MARK: - RitualView

struct RitualView: View {
    @ObservedObject var viewModel: ArcViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var day: ArcDay? = nil

    // MARK: - Dedicated Ritual Screen routing
    enum RitualRoutePillar { case forge, temper, align }
    struct RitualRoute {
        let pillar: RitualRoutePillar
        let title: String
        let seconds: Int
    }

    @State private var ritualRoute: RitualRoute? = nil
    @State private var showRitualScreen = false

    // MARK: - Confirm feedback
    enum ConfirmPhase { case idle, saving, confirmed }
    @State private var confirmPhase: ConfirmPhase = .idle
    @State private var confirmPressed: Bool = false

    // MARK: - Micro-pressure
    @State private var microMessage: String? = nil
    @State private var microMessageTask: Task<Void, Never>? = nil

    // MARK: - FORGE
    @State private var forgeSelected: ForgeAction? = nil
    @State private var forgeReflection = ""
    @State private var forgeDone = false
    @State private var forgeSecondsLeft: Int = 0
    @State private var forgeTimerRunning = false
    @State private var forgeTimer: Timer? = nil

    // MARK: - TEMPER
    @State private var temperSelected: TemperAction? = nil
    @State private var temperReflection = ""
    @State private var temperDone = false
    @State private var temperSecondsLeft: Int = 0
    @State private var temperTimerRunning = false
    @State private var temperTimer: Timer? = nil
    @State private var showFocusLockHint = false

    // MARK: - ALIGN
    @State private var alignSelected: AlignAction? = nil
    @State private var alignReflection = ""
    @State private var alignDone = false
    @State private var alignSecondsLeft: Int = 0
    @State private var alignTimerRunning = false
    @State private var alignTimer: Timer? = nil

    // MARK: - “Battle feel” feedback state
    @State private var screenPulse = false


// MARK: - Persist as you go (so selections don't reset when navigating)
private func persistForgeSelection(_ day: ArcDay) {
    viewModel.updatePillar(day: day, type: .forge, task: forgeSelected?.title ?? "", reflection: forgeReflection, completed: forgeDone)
}
private func persistTemperSelection(_ day: ArcDay) {
    viewModel.updatePillar(day: day, type: .temper, task: temperSelected?.title ?? "", reflection: temperReflection, completed: temperDone)
}
private func persistAlignSelection(_ day: ArcDay) {
    viewModel.updatePillar(day: day, type: .align, task: alignSelected?.title ?? "", reflection: alignReflection, completed: alignDone)
}

    // Forge level-up feedback
    @State private var forgePulse = false
    @State private var forgeFlameBoost = false
    @State private var forgeMomentum: Int = 0
    @State private var forgeMomentumBump = false

    // MARK: - Day Completion Ceremony
    @State private var isConfirming = false
    @State private var showCeremony = false
    @State private var ceremonyConfig: DayCeremonyConfig? = nil

    // MARK: - Day Lock Ritual Seal
    @State private var showDayLockSeal = false
    @State private var dayLockNumber: Int = 1
    @State private var dayLockTier: MomentumTier = .dormant
    @State private var dayLockHeat: IdentityHeat = IdentityHeat(value: 0, streakHeat: 0, rateHeat: 0)
    @State private var masteryUnlocked: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if let day {
                    ScrollView {
                        VStack(spacing: 14) {
                            Text("Ritual — Day \(day.number)")
                                .font(.title2.weight(.bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.white)

                            ForgeSectionView(
                                dayNumber: day.number,
                                actions: ForgeCatalog.actions(forDay: day.number),
                                selected: $forgeSelected,
                                reflection: $forgeReflection,
                                done: $forgeDone,
                                secondsLeft: $forgeSecondsLeft,
                                timerRunning: $forgeTimerRunning,
                                onPick: { a in
                                forgeSelected = a
                                forgeDone = false
                                stopForgeTimer()
                                forgeSecondsLeft = a.timeSeconds ?? 0
                                Haptics.light()
                                persistForgeSelection(day)
                            },
                                onOpenRitual: { title, sec in
                                    ritualRoute = RitualRoute(pillar: .forge, title: title, seconds: sec)
                                    showRitualScreen = true
                                }
                            )

                            TemperSectionView(
                                actions: TemperCatalog.actions(forDay: day.number),
                                selected: $temperSelected,
                                reflection: $temperReflection,
                                done: $temperDone,
                                secondsLeft: $temperSecondsLeft,
                                timerRunning: $temperTimerRunning,
                                onPick: { a in
                                temperSelected = a
                                temperDone = false
                                stopTemperTimer()
                                temperSecondsLeft = a.timeSeconds
                                Haptics.light()
                                persistTemperSelection(day)
                            },
                                onOpenRitual: { title, sec in
                                    ritualRoute = RitualRoute(pillar: .temper, title: title, seconds: sec)
                                    showRitualScreen = true
                                }
                            )

                            AlignSectionView(
                                actions: AlignCatalog.actions(forDay: day.number),
                                selected: $alignSelected,
                                reflection: $alignReflection,
                                done: $alignDone,
                                secondsLeft: $alignSecondsLeft,
                                timerRunning: $alignTimerRunning,
                                onPick: { a in
                                alignSelected = a
                                alignDone = false
                                stopAlignTimer()
                                alignSecondsLeft = a.timeSeconds
                                Haptics.light()
                                persistAlignSelection(day)
                            },
                                onOpenRitual: { title, sec in
                                    ritualRoute = RitualRoute(pillar: .align, title: title, seconds: sec)
                                    showRitualScreen = true
                                }
                            )

                            
// Confirm
Button {
    guard confirmPhase == .idle else { return }
    confirmPhase = .saving
    Haptics.light()
    onConfirmTapped(day: day)

    // Even if save is instant, acknowledge the tap.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        confirmPhase = .confirmed
        Haptics.success()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
        confirmPhase = .idle
    }
} label: {
    Text(confirmPhase == .saving ? "SAVING…" : (confirmPhase == .confirmed ? "CONFIRMED" : "CONFIRM"))
        .frame(maxWidth: .infinity)
}
.buttonStyle(ArcPrimaryButtonStyle())
.scaleEffect(confirmPressed ? 0.985 : 1.0)
.opacity(confirmPressed ? 0.92 : 1.0)
.animation(.easeOut(duration: 0.12), value: confirmPressed)
.simultaneousGesture(
    DragGesture(minimumDistance: 0)
        .onChanged { _ in confirmPressed = true }
        .onEnded { _ in confirmPressed = false }
)
.disabled(confirmPhase != .idle)
.padding(.top, 14)
                        }
                        .padding(.horizontal, ArcSpacing.screenPadding)
                        .padding(.vertical, 14)
                    }
.onChange(of: forgeReflection) { _ in persistForgeSelection(day) }
.onChange(of: forgeDone) { _ in persistForgeSelection(day) }
.onChange(of: temperReflection) { _ in persistTemperSelection(day) }
.onChange(of: temperDone) { _ in persistTemperSelection(day) }
.onChange(of: alignReflection) { _ in persistAlignSelection(day) }
.onChange(of: alignDone) { _ in persistAlignSelection(day) }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Ritual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        stopForgeTimer()
                        stopTemperTimer()
                        stopAlignTimer()
                        microMessageTask?.cancel()
                        dismiss()
                    }
                }
            }
            .task {
                let d = viewModel.dayForCurrent()
                day = d

                // preload Forge
                let fActions = ForgeCatalog.actions(forDay: d.number)
                if let match = fActions.first(where: { $0.title == d.forgeTask }) {
                    forgeSelected = match
                    forgeSecondsLeft = match.timeSeconds ?? 0
                } else {
                    forgeSelected = nil
                    forgeSecondsLeft = 0
                }
                forgeReflection = d.forgeReflection
                forgeDone = d.forgeCompleted
                forgeTimerRunning = false

                // preload Temper
                let tActions = TemperCatalog.actions(forDay: d.number)
                if let match = tActions.first(where: { $0.title == d.temperTask }) {
                    temperSelected = match
                    temperSecondsLeft = match.timeSeconds
                } else {
                    temperSelected = nil
                    temperSecondsLeft = 0
                }
                temperReflection = d.temperReflection
                temperDone = d.temperCompleted
                temperTimerRunning = false

                // preload Align
                let aActions = AlignCatalog.actions(forDay: d.number)
                if let match = aActions.first(where: { $0.title == d.alignTask }) {
                    alignSelected = match
                    alignSecondsLeft = match.timeSeconds
                } else {
                    alignSelected = nil
                    alignSecondsLeft = 0
                }
                alignReflection = d.alignReflection
                alignDone = d.alignCompleted
                alignTimerRunning = false
            }
            .navigationDestination(isPresented: $showRitualScreen) {
                if let route = ritualRoute {
                    switch route.pillar {
                    case .forge:
                        RitualTaskScreen(title: route.title, secondsLeft: $forgeSecondsLeft, isRunning: $forgeTimerRunning, onStart: { startForgeTimer() }, onComplete: { viewModel.awardMomentumPoint() }, onStoppedEarly: { note in viewModel.recordEarlyStop(reflection: note) })
                    case .temper:
                        RitualTaskScreen(title: route.title, secondsLeft: $temperSecondsLeft, isRunning: $temperTimerRunning, onStart: { startTemperTimer() }, onComplete: { viewModel.awardMomentumPoint() }, onStoppedEarly: { note in viewModel.recordEarlyStop(reflection: note) })
                    case .align:
                        RitualTaskScreen(title: route.title, secondsLeft: $alignSecondsLeft, isRunning: $alignTimerRunning, onStart: { startAlignTimer() }, onComplete: { viewModel.awardMomentumPoint() }, onStoppedEarly: { note in viewModel.recordEarlyStop(reflection: note) })
                    }
                } else {
                    EmptyView()
                }
            }
            .onChange(of: showRitualScreen) { _, newValue in
                if newValue == false { ritualRoute = nil }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

// MARK: - Confirm + Ceremony

    private func onConfirmTapped(day: ArcDay) {
        // Save Forge
        let forgeTask = forgeSelected?.title ?? ""
        viewModel.updatePillar(
            day: day,
            type: .forge,
            task: forgeTask,
            reflection: forgeReflection,
            completed: forgeDone
        )

        // Save Temper
        let temperTask = temperSelected?.title ?? ""
        viewModel.updatePillar(
            day: day,
            type: .temper,
            task: temperTask,
            reflection: temperReflection,
            completed: temperDone
        )

        // Save Align
        let alignTask = alignSelected?.title ?? ""
        viewModel.updatePillar(
            day: day,
            type: .align,
            task: alignTask,
            reflection: alignReflection,
            completed: alignDone
        )

        // Transition: pause -> darken -> silence -> ceremony
        isConfirming = true

        Task { @MainActor in
            // 0.5s pause (silence)
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Build ceremony config (dynamic)
            let streak = resolveStreak(fallbackDayNumber: day.number)
            ceremonyConfig = DayCeremonyConfig(
                dayNumber: day.number,
                streak: streak,
                arcTotalDays: 30
            )

            // Show ceremony
            withAnimation(.easeOut(duration: 0.18)) {
                showCeremony = true
            }

            // re-enable behind-the-scenes
            isConfirming = false
        }
    }

    /// If your ArcViewModel already exposes a real streak value, wire it here.
    private func resolveStreak(fallbackDayNumber: Int) -> Int {
        // Use the actual streak logic (counts consecutive FULL days)
        return ArcEngine.currentStreak(for: viewModel.arc)
    }

    // MARK: - Micro-pressure helpers

    private func showMicro(_ text: String) {
        microMessageTask?.cancel()
        withAnimation(.easeInOut(duration: 0.15)) {
            microMessage = text
        }

        microMessageTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000) // 1.6s
            withAnimation(.easeInOut(duration: 0.2)) {
                microMessage = nil
            }
        }
    }

    private func checkAllComplete() {
        if forgeDone && temperDone && alignDone {
            showMicro("You kept your word today.")
        }
    }

    // MARK: - Identity reinforcement micro-copy

    private func showForgeLockedIn() {
        showMicro("🔥 FORGE LOCKED IN\n“You did what you didn’t feel like doing.”")
    }

    private func showFocusHeld() {
        showMicro("🧠 FOCUS HELD\n“You controlled your attention.”")
    }

    private func showDirectionSet() {
        showMicro("🧭 DIRECTION SET\n“You decided your future.”")
    }

    // MARK: - Battle-feel triggers

    private func triggerScreenPulse() {
        screenPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            screenPulse = false
        }
    }

    private func triggerForgeLevelUp() {
        // 1) screen pulse
        triggerScreenPulse()

        // 2) card pulse
        withAnimation(.easeOut(duration: 0.18)) {
            forgePulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.24)) {
                forgePulse = false
            }
        }

        // 3) flame glow “ignition”
        forgeFlameBoost = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            forgeFlameBoost = false
        }

        // 4) momentum number climbs + anim bump
        forgeMomentum += 1
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            forgeMomentumBump = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                forgeMomentumBump = false
            }
        }

        // 5) haptic “identity shift”
        Haptics.success()
    }

    // MARK: - FORGE UI

    private func forgeCard(day: ArcDay) -> some View {
        let actions = ForgeCatalog.actions(forDay: day.number)

        let reflectionOK = !forgeReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let actionOK = forgeSelected != nil

        // If time-based, require finishing the timer.
        let timeOK: Bool = {
            guard let selected = forgeSelected else { return false }
            guard let sec = selected.timeSeconds, sec > 0 else { return true }
            return forgeSecondsLeft == 0
        }()

        let eligibleToMarkDone = actionOK && reflectionOK && timeOK

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(Color.yellow.opacity(forgeDone ? 0.95 : 0.75))
                        .shadow(color: Color.yellow.opacity((forgeDone || forgeFlameBoost) ? 0.65 : 0.12),
                                radius: (forgeDone || forgeFlameBoost) ? 10 : 2,
                                x: 0, y: 0)
                        .scaleEffect(forgeFlameBoost ? 1.08 : 1.0)
                        .animation(.easeOut(duration: 0.18), value: forgeFlameBoost)

                    Text("Forge")
                        .font(.headline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Body Discipline")
                        .font(.footnote)
                        .opacity(0.7)

                    // ✅ Momentum number animates upward
                    Text("Momentum \(forgeMomentum)")
                        .font(.footnote.weight(.semibold))
                        .monospacedDigit()
                        .opacity(0.85)
                        .scaleEffect(forgeMomentumBump ? 1.08 : 1.0)
                        .animation(.spring(response: 0.28, dampingFraction: 0.55), value: forgeMomentumBump)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Choose the resistance you will overcome")
                    .font(.footnote)
                    .opacity(0.75)

                ForEach(actions) { a in
                    SelectableTaskCard(
                        title: a.title,
                        isSelected: forgeSelected?.id == a.id,
                        accent: .yellow
                    ) {
                        forgeSelected = a
                        forgeDone = false
                        stopForgeTimer()
                        forgeSecondsLeft = a.timeSeconds ?? 0
                        Haptics.light()
                        if let sec = a.timeSeconds, sec > 0 {

                        }
                    }
                }

            }

            if let sec = forgeSelected?.timeSeconds, sec > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timer").font(.footnote).opacity(0.75)

                    HStack {
                        Text(formatTime(forgeSecondsLeft))
                            .font(.title3.weight(.bold))
                        Spacer()
                        Button(forgeTimerRunning ? "Pause" : "Start") {
                            forgeTimerRunning ? pauseForgeTimer() : startForgeTimer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                    }
                }
            }

            TextField("What did you want to avoid — but did anyway?", text: $forgeReflection)
                .textFieldStyle(.roundedBorder)

            HoldToConfirmButton(
                title: forgeDone ? "Forge Completed" : "Hold to lock it in",
                enabled: eligibleToMarkDone && !forgeDone,
                extraConfirmHaptic: { Haptics.success() }
            ) {
                forgeDone = true
                stopForgeTimer()
                showForgeLockedIn()

                // ✅ Make completion feel like leveling up
                triggerForgeLevelUp()

                checkAllComplete()
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        // ✅ Card “impact” (subtle pulse)
        .scaleEffect(forgePulse ? 1.012 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: forgePulse)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(forgePulse ? 0.40 : 0.0), lineWidth: 1)
                .animation(.easeOut(duration: 0.18), value: forgePulse)
        )
    }

    // MARK: - TEMPER UI

    private func temperCard(day: ArcDay) -> some View {
        let actions = TemperCatalog.actions(forDay: day.number)

        let reflectionOK = !temperReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let actionOK = temperSelected != nil
        let timeOK = (temperSelected != nil) && (temperSecondsLeft == 0)
        let eligibleToMarkDone = actionOK && reflectionOK && timeOK

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.headline)
                    .opacity(0.75)
                Text("Temper").font(.headline)
                Spacer()
                Text("Mind Discipline").font(.footnote).opacity(0.7)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What will you protect your attention from?").font(.footnote).opacity(0.75)

                ForEach(actions) { a in
                    SelectableTaskCard(
                        title: a.title,
                        isSelected: temperSelected?.id == a.id,
                        accent: .blue
                    ) {
                        temperSelected = a
                        temperDone = false
                        stopTemperTimer()
                        temperSecondsLeft = a.timeSeconds
                        showFocusLockHint = true
                        Haptics.light()
                    }
                }

            }

            if showFocusLockHint, temperSelected != nil {
                Text("No notifications. Stay with it.")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.85)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Timer").font(.footnote).opacity(0.75)

                HStack {
                    Text(formatTime(temperSecondsLeft))
                        .font(.title3.weight(.bold))
                    Spacer()
                    Button(temperTimerRunning ? "Pause" : "Start") {
                        temperTimerRunning ? pauseTemperTimer() : startTemperTimer()
                    }
                    .disabled(temperSelected == nil)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                }
            }

            TextField("Where did your discipline break?", text: $temperReflection)
                .textFieldStyle(.roundedBorder)

            HoldToConfirmButton(
                title: temperDone ? "Focus held" : "Hold to Mark Focus Held",
                enabled: eligibleToMarkDone && !temperDone
            ) {
                temperDone = true
                stopTemperTimer()
                showFocusHeld()
                triggerScreenPulse()
                checkAllComplete()
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }

    // MARK: - ALIGN UI

    private func alignCard(day: ArcDay) -> some View {
        let actions = AlignCatalog.actions(forDay: day.number)

        let reflectionOK = !alignReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let actionOK = alignSelected != nil
        let timeOK = (alignSelected != nil) && (alignSecondsLeft == 0)
        let eligibleToMarkDone = actionOK && reflectionOK && timeOK

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.headline)
                    .opacity(0.75)
                Text("Align").font(.headline)
                Spacer()
                Text("Direction").font(.footnote).opacity(0.7)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("If you don’t direct your days, they disappear.")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.9)

                Text("What moved your future forward today?")
                    .font(.footnote)
                    .opacity(0.75)

                ForEach(actions) { a in
                    SelectableTaskCard(
                        title: a.title,
                        isSelected: alignSelected?.id == a.id,
                        accent: .green
                    ) {
                        alignSelected = a
                        alignDone = false
                        stopAlignTimer()
                        alignSecondsLeft = a.timeSeconds
                        Haptics.light()

                    }
                }

            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Timer").font(.footnote).opacity(0.75)

                HStack {
                    Text(formatTime(alignSecondsLeft))
                        .font(.title3.weight(.bold))
                    Spacer()
                    Button(alignTimerRunning ? "Pause" : "Start") {
                        alignTimerRunning ? pauseAlignTimer() : startAlignTimer()
                    }
                    .disabled(alignSelected == nil)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                }
            }

            TextField("What moved your future forward today?", text: $alignReflection)
                .textFieldStyle(.roundedBorder)

            HoldToConfirmButton(
                title: alignDone ? "Direction chosen" : "Hold to Choose Direction",
                enabled: eligibleToMarkDone && !alignDone
            ) {
                alignDone = true
                stopAlignTimer()
                showDirectionSet()
                triggerScreenPulse()
                checkAllComplete()
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }

    // MARK: - Timer helpers (Forge)

    private func startForgeTimer() {
        guard forgeTimer == nil else { return }
        guard forgeSecondsLeft > 0 else { return }

        forgeTimerRunning = true
        forgeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if forgeSecondsLeft > 0 { forgeSecondsLeft -= 1 }
            if forgeSecondsLeft <= 0 { stopForgeTimer() }
        }
    }

    private func pauseForgeTimer() {
        forgeTimerRunning = false
        forgeTimer?.invalidate()
        forgeTimer = nil
    }

    private func stopForgeTimer() {
        forgeTimerRunning = false
        forgeTimer?.invalidate()
        forgeTimer = nil
    }

    // MARK: - Timer helpers (Temper)

    private func startTemperTimer() {
        guard temperTimer == nil else { return }
        guard temperSecondsLeft > 0 else { return }

        temperTimerRunning = true
        temperTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if temperSecondsLeft > 0 { temperSecondsLeft -= 1 }
            if temperSecondsLeft <= 0 { stopTemperTimer() }
        }
    }

    private func pauseTemperTimer() {
        temperTimerRunning = false
        temperTimer?.invalidate()
        temperTimer = nil
    }

    private func stopTemperTimer() {
        temperTimerRunning = false
        temperTimer?.invalidate()
        temperTimer = nil
    }

    // MARK: - Timer helpers (Align)

    private func startAlignTimer() {
        guard alignTimer == nil else { return }
        guard alignSecondsLeft > 0 else { return }

        alignTimerRunning = true
        alignTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if alignSecondsLeft > 0 { alignSecondsLeft -= 1 }
            if alignSecondsLeft <= 0 { stopAlignTimer() }
        }
    }

    private func pauseAlignTimer() {
        alignTimerRunning = false
        alignTimer?.invalidate()
        alignTimer = nil
    }

    private func stopAlignTimer() {
        alignTimerRunning = false
        alignTimer?.invalidate()
        alignTimer = nil
    }

    // MARK: - Utilities

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

}

// MARK: - Hold button (haptic on hold + gold flash 0.3s)

struct HoldToConfirmButton: View {
    let title: String
    let enabled: Bool
    var extraConfirmHaptic: (() -> Void)? = nil
    let onConfirm: () -> Void

    @State private var flash = false
    @State private var isPressing = false

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity)
            .padding()
            .background(enabled ? Color.yellow.opacity(0.18) : Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(enabled ? Color.yellow.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow.opacity(flash ? 0.28 : 0))
                    .allowsHitTesting(false)
            )
            .cornerRadius(16)
            .opacity(enabled ? 1 : 0.6)
            .scaleEffect(isPressing && enabled ? 0.995 : 1.0)
            .onLongPressGesture(
                minimumDuration: 1.2,
                maximumDistance: 18,
                pressing: { pressing in
                    guard enabled else { return }
                    if pressing && !isPressing { Haptics.soft() } // haptic when hold begins
                    isPressing = pressing
                },
                perform: {
                    guard enabled else { return }
                    Haptics.light()           // haptic on confirm
                    extraConfirmHaptic?()     // optional extra confirm haptic (Forge uses this)
                    triggerFlash()            // gold flash
                    onConfirm()
                }
            )
    }

    private func triggerFlash() {
        flash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            flash = false
        }
    }
}

// MARK: - Day Completion Ceremony (THE MOMENT PEOPLE REMEMBER)

struct DayCeremonyConfig: Equatable {
    let dayNumber: Int
    let streak: Int
    let arcTotalDays: Int
}

struct DayCompletionCeremonyView: View {
    let config: DayCeremonyConfig
    let onReturnHome: () -> Void

    // sequencing
    @State private var dimBackground = false
    @State private var flameOn = false
    @State private var showLine1 = false
    @State private var showLine2 = false
    @State private var showIdentity = false
    @State private var showProgress = false
    @State private var showButton = false

    // progress
    @State private var progressFill: CGFloat = 0

    var body: some View {
        ZStack {
            // background dim
            Color.black
                .opacity(dimBackground ? 0.72 : 0.0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: dimBackground)

            VStack(spacing: 18) {
                Spacer()

                // Impact: flame/ring ignition
                ZStack {
                    ArcRing(progress: progressFill)
                        .frame(width: 112, height: 112)
                        .opacity(flameOn ? 1.0 : 0.0)
                        .scaleEffect(flameOn ? 1.0 : 0.86)
                        .animation(.easeOut(duration: 0.35), value: flameOn)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color.yellow.opacity(0.92))
                        .opacity(flameOn ? 1.0 : 0.0)
                        .scaleEffect(flameOn ? 1.0 : 0.90)
                        .shadow(color: Color.yellow.opacity(flameOn ? 0.55 : 0.0), radius: flameOn ? 14 : 0)
                        .animation(.easeOut(duration: 0.35), value: flameOn)
                }
                .padding(.bottom, 6)

                VStack(spacing: 8) {
                    if showLine1 {
                        Text(primaryTitle)
                            .font(.title2.weight(.bold))
                            .transition(.opacity)
                    }

                    if showLine2 {
                        Text("You kept your word.")
                            .font(.headline.weight(.semibold))
                            .opacity(0.92)
                            .transition(.opacity)
                    }
                }
                .multilineTextAlignment(.center)

                if showIdentity {
                    Text(identityLine)
                        .font(.subheadline.weight(.semibold))
                        .opacity(0.85)
                        .transition(.opacity)
                        .padding(.top, 6)
                }

                if showProgress {
                    VStack(spacing: 10) {
                        // subtle 30-day arc progress label
                        Text("Arc \(config.dayNumber)/\(config.arcTotalDays)")
                            .font(.footnote.weight(.semibold))
                            .opacity(0.70)

                        // thin bar (secondary, not gamified)
                        ProgressView(value: Double(config.dayNumber), total: Double(config.arcTotalDays))
                            .tint(Color.yellow.opacity(0.65))
                            .scaleEffect(x: 1, y: 1.15, anchor: .center)
                            .opacity(0.92)
                            .frame(maxWidth: 240)
                    }
                    .transition(.opacity)
                }

                Spacer()

                if showButton {
                    Button {
                        Haptics.light()
                        onReturnHome()
                    } label: {
                        Text("Return to Home")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                    .transition(.opacity)
                }
            }
        }
        .allowsHitTesting(true)
        .task { await runSequence() }
    }

    private var primaryTitle: String {
        // Special layers
        if config.dayNumber >= config.arcTotalDays {
            return "Arc Complete."
        }
        return "Day \(config.dayNumber) Locked."
    }

    private var identityLine: String {
        // Day 30 (strong)
        if config.dayNumber >= config.arcTotalDays {
            return "You did not break."
        }

        // Day 7 (stronger)
        if config.dayNumber == 7 {
            return "Week 1 survived. Most people quit before this."
        }

        // Dynamic by streak (requested)
        if config.streak >= 7 { return "You are becoming disciplined." }
        if config.streak >= 3 { return "Standards rising." }
        return "Momentum begins."
    }

    @MainActor
    private func runSequence() async {
        // Step 1: pause already happened in parent; now darken
        withAnimation(.easeOut(duration: 0.25)) { dimBackground = true }

        // Silence. Then ignite (1.5 seconds impact window)
        try? await Task.sleep(nanoseconds: 350_000_000)

        // ignition spark / low thump (minimal)
        Haptics.soft()

        flameOn = true

        // ring fills to day progress (subtle)
        let target = CGFloat(min(max(Double(config.dayNumber) / Double(config.arcTotalDays), 0.0), 1.0))
        withAnimation(.easeOut(duration: 0.85)) {
            progressFill = target
        }

        try? await Task.sleep(nanoseconds: 550_000_000)
        withAnimation(.easeIn(duration: 0.35)) { showLine1 = true }

        try? await Task.sleep(nanoseconds: 380_000_000)
        withAnimation(.easeIn(duration: 0.35)) { showLine2 = true }

        // Let it sit. No clutter.
        try? await Task.sleep(nanoseconds: 900_000_000)

        // Identity reinforcement appears (after ~2s)
        withAnimation(.easeIn(duration: 0.30)) { showIdentity = true }

        // Visual progress + tiny haptic tap
        try? await Task.sleep(nanoseconds: 450_000_000)
        withAnimation(.easeIn(duration: 0.30)) { showProgress = true }
        Haptics.light()

        // Close ceremony (button fades in)
        try? await Task.sleep(nanoseconds: 650_000_000)
        withAnimation(.easeIn(duration: 0.25)) { showButton = true }
    }
}

// MARK: - Arc Ring (minimal, ritualistic)

struct ArcRing: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.yellow.opacity(0.70),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .drawingGroup()
    }
}
