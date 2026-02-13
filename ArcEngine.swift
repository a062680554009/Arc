import Foundation
import SwiftData

struct ArcEngine {
    static let arcLength = 30
    static let requiredFullFraction = 0.85
    static let freeLimitDays = 7
    static let maxMissedDaysBeforeReset = 3

    static func ensureArcExists(modelContext: ModelContext) -> Arc {
        let fetch = FetchDescriptor<Arc>(sortBy: [SortDescriptor(\Arc.startDate, order: .reverse)])
        if let existing = try? modelContext.fetch(fetch).first {
            updateDerived(arc: existing)
            return existing
        }
        let newArc = createNewArc(startDate: Date())
        modelContext.insert(newArc)
        updateDerived(arc: newArc)
        return newArc
    }

    static func createNewArc(startDate: Date) -> Arc {
        let arc = Arc(startDate: startDate)
        arc.days = (1...arcLength).map { ArcDay(number: $0) }
        arc.currentDayNumber = 1
        arc.streak = 0
        arc.isCompleted = false
        arc.completedAt = nil
        arc.finalRankRaw = nil
        return arc
    }

    static func updateDerived(arc: Arc) {
        arc.currentDayNumber = currentDayNumber(for: arc)
        arc.streak = currentStreak(for: arc)
    }

    static func currentDayNumber(for arc: Arc) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: arc.startDate)
        let today = cal.startOfDay(for: Date())
        let diff = cal.dateComponents([.day], from: start, to: today).day ?? 0
        return min(max(diff + 1, 1), arcLength)
    }

    /// Strict streak:
    /// - Only FULL days count.
    /// - If latest day (up to currentDayNumber) isn't FULL -> streak = 0.
    static func currentStreak(for arc: Arc) -> Int {
        let ordered = arc.days.sorted { $0.number < $1.number }
        let maxDay = min(arc.currentDayNumber, ordered.count)
        guard maxDay >= 1 else { return 0 }

        let relevant = ordered.prefix(maxDay)
        guard let latest = relevant.last, latest.completion == .full else { return 0 }

        var s = 0
        for day in relevant.reversed() {
            if day.completion == .full { s += 1 } else { break }
        }
        return s
    }

    static func fullDaysCount(for arc: Arc) -> Int {
        arc.days.filter { $0.completion == .full }.count
    }

    static func completionPercent(for arc: Arc) -> Double {
        Double(fullDaysCount(for: arc)) / Double(arcLength)
    }

    static func requiredFullDays() -> Int {
        Int(ceil(requiredFullFraction * Double(arcLength))) // 26
    }

    static func canCompleteArc(_ arc: Arc) -> Bool {
        guard arc.currentDayNumber >= arcLength else { return false }
        return fullDaysCount(for: arc) >= requiredFullDays()
    }

    static func isFreeLimitReached(arc: Arc, isSubscribed: Bool) -> Bool {
        guard !isSubscribed else { return false }
        return arc.currentDayNumber > freeLimitDays
    }
    static func currentWeekRange(for arc: Arc) -> ClosedRange<Int> {
        let day = arc.currentDayNumber
        let start = ((day - 1) / 7) * 7 + 1
        let end = min(start + 6, arcLength)
        return start...end
    }

    static func weekStats(for arc: Arc) -> (full: Int, partial: Int, missed: Int, percent: Int) {
        let range = currentWeekRange(for: arc)
        let weekDays = arc.days.filter { range.contains($0.number) }
        guard !weekDays.isEmpty else { return (0, 0, 0, 0) }

        let full = weekDays.filter { $0.completion == .full }.count
        let partial = weekDays.filter { $0.completion == .partial }.count
        let missed = weekDays.filter { $0.completion == .missed }.count
        let percent = Int((Double(full) / Double(weekDays.count) * 100.0).rounded())
        return (full, partial, missed, percent)
    }

    static func weakestPillar(for arc: Arc) -> PillarType? {
        let forgeCount = arc.days.filter { $0.forgeCompleted }.count
        let temperCount = arc.days.filter { $0.temperCompleted }.count
        let alignCount = arc.days.filter { $0.alignCompleted }.count

        let tuples: [(PillarType, Int)] = [
            (PillarType.forge, forgeCount),
            (PillarType.temper, temperCount),
            (PillarType.align, alignCount)
        ]

        return tuples.min(by: { $0.1 < $1.1 })?.0
    }
    static func missedDaysSoFar(for arc: Arc) -> Int {
        // Count only days that are already in the past.
        // Today can still be completed later, so we exclude current day.
        let cutoff = max(1, arc.currentDayNumber - 1)

        return arc.days
            .filter { $0.number <= cutoff }
            .filter { $0.completion == .missed }
            .count
    }

    static func shouldResetArcForMisses(_ arc: Arc) -> Bool {
        missedDaysSoFar(for: arc) >= maxMissedDaysBeforeReset
    }

}
