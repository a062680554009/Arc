import Foundation

extension Calendar {
    func startOfDayDate(_ date: Date) -> Date {
        startOfDay(for: date)
    }

    /// Returns 0 for same day, 1 for next day, etc.
    func dayIndex(from startDate: Date, to date: Date) -> Int {
        let s = startOfDay(for: startDate)
        let d = startOfDay(for: date)
        return dateComponents([.day], from: s, to: d).day ?? 0
    }
}
