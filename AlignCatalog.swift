import Foundation

struct AlignAction: Identifiable, Hashable {
    let title: String
    let timeSeconds: Int // always short: 5–15 min

    var id: String { title }
}

enum AlignCatalog {
    static func actions(forDay dayNumber: Int) -> [AlignAction] {
        let week = (dayNumber - 1) / 7 + 1

        switch week {
        case 1: // Awareness
            return [
                .init(title: "Write tomorrow’s top priority", timeSeconds: 5*60),
                .init(title: "Define 1 long-term goal", timeSeconds: 10*60),
                .init(title: "Plan next day (3 tasks)", timeSeconds: 10*60),
                .init(title: "Clean workspace", timeSeconds: 15*60)
            ]
        case 2: // Control
            return [
                .init(title: "Break 1 long-term goal into steps", timeSeconds: 15*60),
                .init(title: "Remove 1 distraction from life", timeSeconds: 10*60),
                .init(title: "Schedule a key action", timeSeconds: 10*60),
                .init(title: "Declutter digital files", timeSeconds: 15*60)
            ]
        case 3: // Commitment
            return [
                .init(title: "Take 1 uncomfortable action toward goal", timeSeconds: 10*60),
                .init(title: "Send difficult message", timeSeconds: 5*60),
                .init(title: "Apply for opportunity", timeSeconds: 15*60),
                .init(title: "Set 7-day challenge", timeSeconds: 10*60)
            ]
        default: // week 4 — Ownership
            return [
                .init(title: "Write 30-day self-review", timeSeconds: 15*60),
                .init(title: "Adjust life priorities", timeSeconds: 10*60),
                .init(title: "Cut 1 unaligned habit", timeSeconds: 10*60),
                .init(title: "Create next 30-day plan", timeSeconds: 15*60)
            ]
        }
    }
}
