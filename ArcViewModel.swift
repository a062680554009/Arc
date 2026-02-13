import SwiftUI
import Combine
import SwiftData

@MainActor
final class ArcViewModel: ObservableObject {
    @Published var arc: Arc
    @Published var resetNotice: String? = nil
    @Published var momentumRingLockPulseID = UUID()

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.arc = ArcEngine.ensureArcExists(modelContext: modelContext)
    }
    func resetArcDueToMisses() {
        resetNotice = "Arc reset. Three misses.\nNo drama. Start again."

        let newArc = ArcEngine.createNewArc(startDate: Date())
        modelContext.insert(newArc)
        arc = newArc
        ArcEngine.updateDerived(arc: arc)
        save()
    }

    func refresh() {
        let oldDay = arc.currentDayNumber
        let oldStreak = arc.streak

        ArcEngine.updateDerived(arc: arc)

        // Controlled stakes: 3 missed days => reset
        if !arc.isCompleted && ArcEngine.shouldResetArcForMisses(arc) {
            resetArcDueToMisses()
            return
        }

        // Save only if derived values changed
        if arc.currentDayNumber != oldDay || arc.streak != oldStreak {
            save()
        }
    }


    func dayForCurrent() -> ArcDay {
        ArcEngine.updateDerived(arc: arc)
        let dayNum = arc.currentDayNumber
        if let day = arc.days.first(where: { $0.number == dayNum }) {
            return day
        }
        let fallback = ArcDay(number: dayNum)
        arc.days.append(fallback)
        save()
        return fallback
    }

    
    func pulseMomentumRingLock() {
        momentumRingLockPulseID = UUID()
    }

func updatePillar(day: ArcDay, type: PillarType, task: String, reflection: String, completed: Bool) {
        day.setPillar(type, task: task, reflection: reflection, completed: completed)
        ArcEngine.updateDerived(arc: arc)
        save()
    }

    func completeArcIfEligible() -> Bool {
        ArcEngine.updateDerived(arc: arc)
        guard ArcEngine.canCompleteArc(arc) else { return false }

        arc.isCompleted = true
        arc.completedAt = Date()
        arc.finalRankRaw = Rank.from(dayNumber: arc.currentDayNumber).rawValue

        // Long-term retention: after 3 completed arcs, unlock a permanent core.
        let key = "completedArcCount"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)

        save()
        return true
    }


    func startNewArc() {
        let newArc = ArcEngine.createNewArc(startDate: Date())
        modelContext.insert(newArc)
        arc = newArc
        ArcEngine.updateDerived(arc: arc)
        save()
    }

    private func save() {
        do { try modelContext.save() }
        catch { print("Save error:", error) }
    }


    // MARK: - Task Completion Confirmation Flow

    /// Awards a single "momentum point" for an honestly confirmed full timed task.
    /// Stored in UserDefaults for now to avoid changing persistence schema.
    func awardMomentumPoint() {
        let key = "momentumPoints"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
        pulseMomentumRingLock()
    }

    /// Records an early stop reflection (optional). Safe no-op storage for now.
    func recordEarlyStop(reflection: String?) {
        // Keep the data lightweight and private to the device.
        guard let reflection, !reflection.isEmpty else { return }
        let key = "earlyStopNotes"
        var notes = UserDefaults.standard.stringArray(forKey: key) ?? []
        notes.append(reflection)
        // Prevent unbounded growth
        if notes.count > 50 { notes = Array(notes.suffix(50)) }
        UserDefaults.standard.set(notes, forKey: key)
    }

}