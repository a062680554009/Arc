import SwiftUI
import AudioToolbox

// MARK: - Momentum Visual System
// Momentum = Identity Heat (not streak math)

enum MomentumTier: Int, CaseIterable, Comparable {
    case dormant      // Level 0
    case spark        // Level 1
    case rising       // Level 2
    case burning      // Level 3
    case relentless   // Level 4

    static func < (lhs: MomentumTier, rhs: MomentumTier) -> Bool { lhs.rawValue < rhs.rawValue }

    var levelLabel: String {
        switch self {
        case .dormant: return "Level 0"
        case .spark: return "Level 1"
        case .rising: return "Level 2"
        case .burning: return "Level 3"
        case .relentless: return "Level 4"
        }
    }

    var title: String {
        switch self {
        case .dormant: return "Dormant"
        case .spark: return "Spark"
        case .rising: return "Rising"
        case .burning: return "Burning"
        case .relentless: return "Relentless"
        }
    }

    /// Short, identity-forward subtitle.
    var message: String {
        switch self {
        case .dormant: return "Cold."
        case .spark: return "You’ve begun."
        case .rising: return "Momentum forming."
        case .burning: return "You keep your word."
        case .relentless: return "Standards locked."
        }
    }

    var style: FlameStyle {
        switch self {
        case .dormant:
            return FlameStyle(core: Color.gray.opacity(0.55),
                              aura: Color.clear,
                              glow: 0,
                              scale: 0.84,
                              warmth: 0.00,
                              pulsePeriod: 0,            // no pulse
                              shimmer: false,
                              particles: false,
                              ringOpacity: 0.10,
                              ringGlow: 0)
        case .spark:
            return FlameStyle(core: Color.yellow.opacity(0.62),   // dim gold
                              aura: Color.yellow.opacity(0.16),
                              glow: 10,
                              scale: 0.94,
                              warmth: 0.10,
                              pulsePeriod: 5.0,          // soft pulse every ~5s
                              shimmer: false,
                              particles: false,
                              ringOpacity: 0.35,
                              ringGlow: 6)
        case .rising:
            return FlameStyle(core: Color.yellow.opacity(0.82),
                              aura: Color.yellow.opacity(0.26),
                              glow: 16,
                              scale: 1.02,
                              warmth: 0.18,
                              pulsePeriod: 2.8,
                              shimmer: true,             // subtle heat shimmer
                              particles: false,
                              ringOpacity: 0.55,
                              ringGlow: 10)
        case .burning:
            return FlameStyle(core: Color.yellow.opacity(0.92),
                              aura: Color.orange.opacity(0.20),
                              glow: 22,
                              scale: 1.10,
                              warmth: 0.26,
                              pulsePeriod: 1.8,          // continuous soft pulse
                              shimmer: false,
                              particles: false,
                              ringOpacity: 0.75,
                              ringGlow: 14)
        case .relentless:
            return FlameStyle(core: Color.yellow.opacity(0.98),
                              aura: Color.red.opacity(0.18),
                              glow: 28,
                              scale: 1.18,
                              warmth: 0.34,
                              pulsePeriod: 1.5,
                              shimmer: false,
                              particles: true,           // micro sparks
                              ringOpacity: 1.00,          // fully lit outer ring
                              ringGlow: 18)
        }
    }
}

struct FlameStyle {
    let core: Color
    let aura: Color
    let glow: CGFloat
    let scale: CGFloat
    let warmth: Double

    /// Full in→out→in cycle duration in seconds. 0 disables breathing.
    let pulsePeriod: Double

    let shimmer: Bool
    let particles: Bool

    /// Outer ring visibility (thin identity ring).
    let ringOpacity: Double

    /// Outer ring glow radius.
    let ringGlow: CGFloat
}

// MARK: - Arc ↔ Momentum mapping

extension Arc {
    /// This is your identity heat: consecutive FULL days.
    var momentum: Int { streak }

    var momentumTier: MomentumTier {
        switch momentum {
        case 0: return .dormant
        case 1...3: return .spark
        case 4...7: return .rising
        case 8...14: return .burning
        default: return .relentless
        }
    }

    /// Represents the 30‑day arc progress (thin arc behind the flame).
    var arcProgress: Double {
        guard ArcEngine.arcLength > 0 else { return 0 }
        let p = Double(min(max(currentDayNumber, 0), ArcEngine.arcLength)) / Double(ArcEngine.arcLength)
        return min(max(p, 0), 1)
    }
}

// MARK: - Sound

enum ArcSound {
    static func heavyDrop() {
        // Subtle, heavy feel. Best-effort (safe fallback).
        AudioServicesPlaySystemSound(1104)
    }
}


// MARK: - Identity Heat (Momentum Ring)
// Ring represents CURRENT identity heat, not 30-day arc progress.

struct IdentityHeat {
    /// Combined heat value (0...1)
    let value: Double
    let streakHeat: Double
    let rateHeat: Double
}

extension Double {
    func clamped01() -> Double { min(1, max(0, self)) }
}

extension ArcEngine {
    /// Consecutive MISSED days (past days only; excludes today).
    static func consecutiveMissesSoFar(for arc: Arc) -> Int {
        let cutoff = max(1, arc.currentDayNumber - 1)
        let relevant = arc.days
            .filter { $0.number <= cutoff }
            .sorted { $0.number < $1.number }

        var misses = 0
        for day in relevant.reversed() {
            if day.completion == .missed { misses += 1 }
            else { break }
        }
        return misses
    }

    /// Recent completion rate (0...1) over the last N days up to today.
    /// Full=1, Partial=0.5, Missed=0.
    static func recentCompletionRate(for arc: Arc, window: Int = 7) -> Double {
        let ordered = arc.days.sorted { $0.number < $1.number }
        let maxDay = min(arc.currentDayNumber, ordered.count)
        guard maxDay > 0 else { return 0 }

        let relevant = Array(ordered.prefix(maxDay)).suffix(window)
        guard !relevant.isEmpty else { return 0 }

        let score = relevant.reduce(0.0) { acc, day in
            switch day.completion {
            case .full: return acc + 1.0
            case .partial: return acc + 0.5
            case .missed: return acc + 0.0
            }
        }
        return (score / Double(relevant.count)).clamped01()
    }

    /// Identity heat combines strict FULL streak + recent completion stability.
    static func identityHeat(for arc: Arc) -> IdentityHeat {
        let streakCap = 14.0
        let streakHeat = (Double(currentStreak(for: arc)) / streakCap).clamped01()
        let rateHeat = recentCompletionRate(for: arc, window: 7).clamped01()
        let value = (0.70 * streakHeat + 0.30 * rateHeat).clamped01()
        return IdentityHeat(value: value, streakHeat: streakHeat, rateHeat: rateHeat)
    }
}

// MARK: - Momentum Decay

struct MomentumDecayState {
    let glowMultiplier: Double
    let shouldRingFlicker: Bool
    let forceGreyFlame: Bool
}

func momentumDecayState(consecutiveMisses: Int) -> MomentumDecayState {
    switch consecutiveMisses {
    case 0:
        return .init(glowMultiplier: 1.0, shouldRingFlicker: false, forceGreyFlame: false)
    case 1:
        return .init(glowMultiplier: 0.72, shouldRingFlicker: false, forceGreyFlame: false)
    case 2:
        return .init(glowMultiplier: 0.55, shouldRingFlicker: true, forceGreyFlame: false)
    default:
        // Miss 3: instant cold drop. No drama. Silence.
        return .init(glowMultiplier: 0.0, shouldRingFlicker: false, forceGreyFlame: true)
    }
}

func resolvedFlameStyle(base: FlameStyle, decay: MomentumDecayState) -> FlameStyle {
    if decay.forceGreyFlame {
        return FlameStyle(core: Color.gray.opacity(0.55),
                          aura: Color.clear,
                          glow: 0,
                          scale: base.scale,
                          warmth: 0.0,
                          pulsePeriod: 0,
                          shimmer: false,
                          particles: false,
                          ringOpacity: 0.10,
                          ringGlow: 0)
    }

    return FlameStyle(core: base.core,
                      aura: base.aura.opacity(decay.glowMultiplier),
                      glow: base.glow * decay.glowMultiplier,
                      scale: base.scale,
                      warmth: base.warmth * decay.glowMultiplier,
                      pulsePeriod: base.pulsePeriod,
                      shimmer: base.shimmer,
                      particles: base.particles,
                      ringOpacity: base.ringOpacity * decay.glowMultiplier,
                      ringGlow: base.ringGlow * decay.glowMultiplier)
}
