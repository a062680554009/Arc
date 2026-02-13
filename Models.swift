import Foundation
import SwiftData

@Model
final class Arc {
    @Attribute(.unique) var id: UUID
    var startDate: Date

    var isCompleted: Bool
    var completedAt: Date?

    /// Cached derived fields (updated by ArcEngine)
    var currentDayNumber: Int
    var streak: Int

    /// Optional stored final rank string (so it persists)
    var finalRankRaw: String?

    @Relationship(deleteRule: .cascade) var days: [ArcDay]

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        currentDayNumber: Int = 1,
        streak: Int = 0,
        finalRankRaw: String? = nil,
        days: [ArcDay] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.currentDayNumber = currentDayNumber
        self.streak = streak
        self.finalRankRaw = finalRankRaw
        self.days = days
    }

    var finalRank: Rank? {
        guard let raw = finalRankRaw else { return nil }
        return Rank(rawValue: raw)
    }
}

@Model
final class ArcDay {
    @Attribute(.unique) var id: UUID
    var number: Int // 1...30

    var forgeCompleted: Bool
    var temperCompleted: Bool
    var alignCompleted: Bool

    var forgeTask: String
    var forgeReflection: String

    var temperTask: String
    var temperReflection: String

    var alignTask: String
    var alignReflection: String

    init(
        id: UUID = UUID(),
        number: Int,
        forgeCompleted: Bool = false,
        temperCompleted: Bool = false,
        alignCompleted: Bool = false,
        forgeTask: String = "",
        forgeReflection: String = "",
        temperTask: String = "",
        temperReflection: String = "",
        alignTask: String = "",
        alignReflection: String = ""
    ) {
        self.id = id
        self.number = number
        self.forgeCompleted = forgeCompleted
        self.temperCompleted = temperCompleted
        self.alignCompleted = alignCompleted
        self.forgeTask = forgeTask
        self.forgeReflection = forgeReflection
        self.temperTask = temperTask
        self.temperReflection = temperReflection
        self.alignTask = alignTask
        self.alignReflection = alignReflection
    }

    var completedCount: Int {
        [forgeCompleted, temperCompleted, alignCompleted].filter { $0 }.count
    }

    var completion: DayCompletion {
        switch completedCount {
        case 3: return .full
        case 1...2: return .partial
        default: return .missed
        }
    }

    func setPillar(_ type: PillarType, task: String, reflection: String, completed: Bool) {
        let cleanedTask = task.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanedReflection = reflection
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {
        case .forge:
            forgeTask = cleanedTask
            forgeReflection = cleanedReflection
            forgeCompleted = completed
        case .temper:
            temperTask = cleanedTask
            temperReflection = cleanedReflection
            temperCompleted = completed
        case .align:
            alignTask = cleanedTask
            alignReflection = cleanedReflection
            alignCompleted = completed
        }
    }
}
