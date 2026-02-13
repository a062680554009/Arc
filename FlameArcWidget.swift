import SwiftUI
import UIKit

struct FlameArcWidget: View {
    let tier: MomentumTier
    let identityHeat: IdentityHeat
    let heldDays: Int
    let decay: MomentumDecayState
    let lockPulseID: UUID
    let resetTrigger: Bool
    let masteryUnlocked: Bool

    @State private var levelUpBump: CGFloat = 1.0
    @State private var shattered = false
    @State private var desaturate: Double = 1.0

    var body: some View {
        // Resolve final flame style using the decay state provided by the caller.
        let style = resolvedFlameStyle(base: tier.style, decay: decay)
        let bgWarmth = style.warmth

        ZStack {
            // Environmental warmth (subtle; users feel evolution)
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.10 + bgWarmth * 0.30),
                            Color.black.opacity(0.42),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08 + bgWarmth * 0.22), lineWidth: 1)
                )

            HStack(spacing: 16) {
                ZStack {
                    MomentumRingCoreView(heat: identityHeat.value,
                                         tier: tier,
                                         masteryUnlocked: masteryUnlocked,
                                         shattered: shattered,
                                         shouldFlicker: decay.shouldRingFlicker,
                                         glowMultiplier: decay.glowMultiplier,
                                         lockPulseID: lockPulseID)

                    FlameView(tier: tier, decay: decay, masteryUnlocked: masteryUnlocked)
                        .scaleEffect(style.scale * levelUpBump)
                        .animation(.easeInOut(duration: 0.45), value: tier)
                        .animation(.easeOut(duration: 0.8), value: levelUpBump)
                }
                .frame(width: 92, height: 92)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Momentum")
                        .font(.caption.weight(.semibold))
                        .opacity(0.75)

                    Text("\(tier.levelLabel) — \(tier.title)")
                        .font(.headline.weight(.bold))

                    Text(heldSubtitle)
                        .font(.subheadline.weight(.semibold))
                        .opacity(0.85)

                    Text(tier.message)
                        .font(.footnote.weight(.semibold))
                        .opacity(0.70)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .saturation(desaturate)
        .onAppear {
            updateDesaturation(reset: resetTrigger)
        }
        .onChange(of: heldDays) { oldValue, newValue in
            // Micro-level up bump when a day is completed.
            if newValue > oldValue {
                levelUp()
            }
        }
        .onChange(of: resetTrigger) { _, newValue in
            updateDesaturation(reset: newValue)
        }
    }

    private var heldSubtitle: String {
        if heldDays <= 0 { return "Begin again." }
        if heldDays == 1 { return "1 day held." }
        return "\(heldDays) days held."
    }

    private func levelUp() {
        // Slight vibration on completion events (Burning+)
        if tier >= .burning {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        levelUpBump = 1.03
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            levelUpBump = 1.0
        }
    }

    private func updateDesaturation(reset: Bool) {
        // Reset experience: glow disappears, screen slightly desaturates.
        withAnimation(.easeIn(duration: 0.35)) {
            desaturate = reset ? 0.70 : 1.0
        }
        if reset {
            shattered = true
            ArcSound.heavyDrop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                shattered = false
            }
        }
    }
}

struct MomentumRingCoreView: View {
    let heat: Double                 // 0...1 identity heat
    let tier: MomentumTier
    let masteryUnlocked: Bool
    let shattered: Bool

    // Decay inputs
    let shouldFlicker: Bool
    let glowMultiplier: Double

    // Lock pulse trigger
    let lockPulseID: UUID

    @State private var flickerPhase = false
    @State private var glow = false

    var body: some View {
        // Build a local decay state from ring inputs (prevents scope issues).
        let localDecay = MomentumDecayState(
            glowMultiplier: glowMultiplier,
            shouldRingFlicker: shouldFlicker,
            forceGreyFlame: glowMultiplier <= 0.001
        )
        let style = resolvedFlameStyle(base: tier.style, decay: localDecay)
        let p = min(max(heat, 0), 1)

        ZStack {
            // Barely-visible base ring
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 3)

            // Identity heat ring (fills by heat)
            Circle()
                .trim(from: 0, to: p)
                .stroke(
                    (masteryUnlocked ? Color.white.opacity(0.28) : Color.yellow.opacity(0.18))
                        .opacity(currentOpacity(style: style)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.yellow.opacity(0.18), radius: style.ringGlow * glowMultiplier, x: 0, y: 0)
                .opacity(shattered ? 0 : 1)
                .animation(.easeInOut(duration: 0.55), value: heat)
                .animation(.easeInOut(duration: 0.25), value: shattered)

            // Lock glow (brief)
            Circle()
                .trim(from: 0, to: p)
                .stroke(Color.white.opacity(glow ? 0.55 : 0.0),
                        style: StrokeStyle(lineWidth: glow ? 5 : 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: glow ? 2 : 0)
                .opacity(shattered ? 0 : 1)
                .animation(.easeOut(duration: 0.22), value: glow)
        }
        .padding(10)
        .onAppear { startOrStopFlicker() }
        .onChange(of: shouldFlicker) { _, _ in startOrStopFlicker() }
        .onChange(of: lockPulseID) { _, _ in pulseLock() }
    }

    private func currentOpacity(style: FlameStyle) -> Double {
        let base = style.ringOpacity * glowMultiplier
        if shouldFlicker {
            return flickerPhase ? base * 0.55 : base
        }
        return base
    }

    private func startOrStopFlicker() {
        guard shouldFlicker else {
            flickerPhase = false
            return
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            flickerPhase.toggle()
        }
    }

    private func pulseLock() {
        glow = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            glow = false
        }
    }
}


struct FlameView: View {
    let tier: MomentumTier
    let decay: MomentumDecayState
    let masteryUnlocked: Bool

    @State private var breathe = false
    @State private var shimmerShift: CGFloat = -1.0
    @State private var particleSpin = false

    var body: some View {
        let style = resolvedFlameStyle(base: tier.style, decay: decay)

        // Mastery layer: permanent core, never fully ember.
        let core = masteryUnlocked ? Color.yellow.opacity(0.96) : style.core
        let aura = masteryUnlocked ? Color.white.opacity(0.18) : style.aura
        let glow = masteryUnlocked ? max(style.glow, 18) : style.glow

        ZStack {
            if style.particles {
                ParticleHalo(spin: particleSpin)
                    .transition(.opacity)
            }

            // Aura
            Image(systemName: "flame.fill")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(aura)
                .blur(radius: glow)
                .opacity(breathe ? 0.85 : 0.55)

            // Core
            Image(systemName: "flame.fill")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(core)
                .shadow(color: core.opacity(0.55), radius: glow, x: 0, y: 0)
                .scaleEffect(breathe ? 1.02 : 0.98)

            if style.shimmer {
                HeatShimmer(shift: shimmerShift)
                    .mask(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 42, weight: .heavy))
                    )
                    .blendMode(.screen)
                    .opacity(0.35)
            }
        }
        .onAppear {
            startBreathingIfNeeded()
            startShimmerIfNeeded()
            startParticlesIfNeeded()
        }
        .onChange(of: tier) { _, _ in
            startBreathingIfNeeded()
            startShimmerIfNeeded()
            startParticlesIfNeeded()
        }
    }

    private func startBreathingIfNeeded() {
        let period = tier.style.pulsePeriod
        guard period > 0 else {
            breathe = false
            return
        }
        // repeatForever w/ autoreverse: full cycle ~= 2 * duration
        let duration = max(0.35, period / 2.0)
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            breathe.toggle()
        }
    }

    private func startShimmerIfNeeded() {
        guard tier.style.shimmer else {
            shimmerShift = -1.0
            return
        }
        shimmerShift = -1.0
        withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
            shimmerShift = 1.0
        }
    }

    private func startParticlesIfNeeded() {
        guard tier.style.particles else {
            particleSpin = false
            return
        }
        particleSpin = false
        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
            particleSpin = true
        }
    }
}

/// Subtle heat shimmer (no “cuteness” — just distortion).
private struct HeatShimmer: View {
    let shift: CGFloat

    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.00),
                Color.white.opacity(0.18),
                Color.white.opacity(0.00),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .scaleEffect(x: 0.9, y: 1.4)
        .offset(x: shift * 10, y: -shift * 6)
        .blur(radius: 1.4)
    }
}

/// Tiny spark particles around the flame (Level 4).
private struct ParticleHalo: View {
    let spin: Bool

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                let angle = Double(i) * (360.0 / 10.0)
                let radius: CGFloat = (i % 2 == 0) ? 26 : 30
                Circle()
                    .frame(width: (i % 3 == 0) ? 2.2 : 1.6,
                           height: (i % 3 == 0) ? 2.2 : 1.6)
                    .foregroundStyle(Color.yellow.opacity(0.65))
                    .offset(x: cos(angle * .pi / 180.0) * radius,
                            y: sin(angle * .pi / 180.0) * radius)
                    .opacity(spin ? 0.35 : 0.75)
            }
        }
        .rotationEffect(.degrees(spin ? 360 : 0))
        .animation(.linear(duration: 6.0).repeatForever(autoreverses: false), value: spin)
    }
}
