import Foundation

struct ForgeAction: Identifiable, Hashable {
    let title: String
    let timeSeconds: Int? // nil = not time-based

    var id: String { title }
}

enum ForgeCatalog {
    static func actions(forDay dayNumber: Int) -> [ForgeAction] {
        let week = (dayNumber - 1) / 7 + 1

        switch week {
        case 1:
            return [
                .init(title: "20 min brisk walk", timeSeconds: 20*60),
                .init(title: "10 min bodyweight workout", timeSeconds: 10*60),
                .init(title: "50 push-ups (total)", timeSeconds: nil),
                .init(title: "8,000 steps", timeSeconds: nil),
                .init(title: "5 min cool/cold shower", timeSeconds: 5*60)
            ]
        case 2:
            return [
                .init(title: "25 min workout", timeSeconds: 25*60),
                .init(title: "70 push-ups total", timeSeconds: nil),
                .init(title: "10,000 steps", timeSeconds: nil),
                .init(title: "8 min cool/cold shower", timeSeconds: 8*60),
                .init(title: "15 min mobility work", timeSeconds: 15*60)
            ]
        case 3:
            return [
                .init(title: "30 min workout", timeSeconds: 30*60),
                .init(title: "100 push-ups total", timeSeconds: nil),
                .init(title: "12,000 steps", timeSeconds: nil),
                .init(title: "10 min cool/cold shower", timeSeconds: 10*60),
                .init(title: "Sprint intervals (10 rounds)", timeSeconds: nil)
            ]
        default: // week 4
            return [
                .init(title: "35–40 min workout", timeSeconds: 40*60),
                .init(title: "150 push-ups total", timeSeconds: nil),
                .init(title: "15,000 steps", timeSeconds: nil),
                .init(title: "Cool/cold shower + breath control", timeSeconds: 10*60),
                .init(title: "20 min core circuit", timeSeconds: 20*60)
            ]
        }
    }
}
