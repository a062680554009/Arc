import Foundation

enum PillarType: String, CaseIterable, Codable, Identifiable {
    case forge, temper, align
    var id: String { rawValue }

    var title: String {
        switch self {
        case .forge: return "Forge"
        case .temper: return "Temper"
        case .align: return "Align"
        }
    }
}

enum DayCompletion: String, Codable {
    case full, partial, missed
}

enum Rank: String, Codable {
    case initiate = "Initiate"
    case disciplined = "Disciplined"
    case relentless = "Relentless"
    case unbreakable = "Unbreakable"

    static func from(dayNumber: Int) -> Rank {
        switch dayNumber {
        case 1...7: return .initiate
        case 8...14: return .disciplined
        case 15...21: return .relentless
        default: return .unbreakable
        }
    }
}
