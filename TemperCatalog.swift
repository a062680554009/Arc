import Foundation

struct TemperAction: Identifiable, Hashable {
    let title: String
    let timeSeconds: Int

    var id: String { title }
}

enum TemperCatalog {
    static func actions(forDay dayNumber: Int) -> [TemperAction] {
        let week = (dayNumber - 1) / 7 + 1

        switch week {
        case 1:
            return [
                .init(title: "10 min deep work (single task, no phone)", timeSeconds: 10*60),
                .init(title: "10 min meditation", timeSeconds: 10*60),
                .init(title: "Read 10 pages", timeSeconds: 10*60), // timed proxy (keeps rules simple)
                .init(title: "10 min writing by hand", timeSeconds: 10*60)
            ]
        case 2:
            return [
                .init(title: "15 min deep work", timeSeconds: 15*60),
                .init(title: "12 min meditation", timeSeconds: 12*60),
                .init(title: "Read 15 pages", timeSeconds: 15*60),
                .init(title: "15 min structured writing", timeSeconds: 15*60)
            ]
        case 3:
            return [
                .init(title: "20 min deep work", timeSeconds: 20*60),
                .init(title: "15 min meditation", timeSeconds: 15*60),
                .init(title: "Read 20 pages", timeSeconds: 20*60),
                .init(title: "20 min writing", timeSeconds: 20*60)
            ]
        default: // week 4
            return [
                .init(title: "25 min deep work", timeSeconds: 25*60),
                .init(title: "20 min meditation", timeSeconds: 20*60),
                .init(title: "Read 25 pages", timeSeconds: 25*60),
                .init(title: "25 min structured writing", timeSeconds: 25*60)
            ]
        }
    }
}
