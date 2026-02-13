import SwiftUI
import UIKit

struct DayLockRitualOverlay: View {
    let dayNumber: Int
    let tier: MomentumTier
    let identityHeat: IdentityHeat
    let masteryUnlocked: Bool
    let consecutiveMisses: Int
    let onFinished: () -> Void

    @State private var dimOpacity: Double = 0
    @State private var flameScale: CGFloat = 1.0
    @State private var ringPulse: CGFloat = 0.0
    @State private var ringOpacity: Double = 0.0

    @State private var showLine1 = false
    @State private var showLine2 = false
    @State private var showLine3 = false

    var body: some View {
        let decay = momentumDecayState(consecutiveMisses: consecutiveMisses)

        ZStack {
            Color.black
                .opacity(dimOpacity)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Give the pulse enough layout space so blur+scale never get cropped.
                let pulseBase: CGFloat = 220
                let pulseBox: CGFloat = 360

                ZStack {
                    // Pulse layer (base size, then scale up)
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.22), lineWidth: 2)

                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 6)
                    }
                    .compositingGroup()
                    .blur(radius: 2.5)
                    .frame(width: pulseBase, height: pulseBase)
                    .scaleEffect(1.0 + ringPulse)
                    .frame(width: pulseBox, height: pulseBox) // ✅ layout buffer for blur + scale
                    .opacity(ringOpacity)

                    // Core ring + flame
                    ZStack {
                        MomentumRingCoreView(
                            heat: identityHeat.value,
                            tier: tier,
                            masteryUnlocked: masteryUnlocked,
                            shattered: false,
                            shouldFlicker: false,
                            glowMultiplier: 1.0,
                            lockPulseID: UUID()
                        )

                        FlameView(tier: tier, decay: decay, masteryUnlocked: masteryUnlocked)
                            .scaleEffect(flameScale)
                    }
                    .frame(width: 180, height: 180)
                }
                .frame(width: pulseBox, height: pulseBox)
                .padding(.top, 44) // <- keeps it away from status bar

                VStack(spacing: 8) {
                    if showLine1 {
                        Text("Day \(dayNumber) Locked.")
                            .font(.system(size: 22, weight: .semibold))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    if showLine2 {
                        Text("You kept your word.")
                            .font(.system(size: 18, weight: .medium))
                            .opacity(0.9)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    if showLine3 {
                        Text("Momentum begins.")
                            .font(.system(size: 18, weight: .medium))
                            .opacity(0.9)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
        }
        .ignoresSafeArea()
        // ✅ DO NOT add compositingGroup/drawingGroup here (it clips blur)
        .onAppear { runSequence() }
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.18)) { dimOpacity = 0.35 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.35)) { flameScale = 1.10 }
            withAnimation(.easeInOut(duration: 0.45)) {
                ringPulse = 0.45
                ringOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeIn(duration: 0.35)) {
                ringPulse = 0.0
                ringOpacity = 0.0
                flameScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.easeOut(duration: 0.25)) { showLine1 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
            withAnimation(.easeOut(duration: 0.25)) { showLine2 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            withAnimation(.easeOut(duration: 0.25)) { showLine3 = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { heavySealHaptic() }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            withAnimation(.easeIn(duration: 0.20)) { dimOpacity = 0.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { onFinished() }
        }
    }

    private func heavySealHaptic() {
        let heavy = UIImpactFeedbackGenerator(style: .rigid)
        heavy.prepare()
        heavy.impactOccurred(intensity: 1.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let soft = UIImpactFeedbackGenerator(style: .soft)
            soft.prepare()
            soft.impactOccurred(intensity: 0.55)
        }
    }
}
