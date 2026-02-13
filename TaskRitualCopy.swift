import Foundation

enum TaskRitualCopy {
    static func mission(for title: String) -> String {
        let t = title.lowercased()

        if t.contains("clean workspace") { return "Clear your environment. Clear your mind." }
        if t.contains("deep work") { return "Protect attention. One target. No escape." }
        if t.contains("cold shower") || t.contains("cool/cold shower") { return "Do not negotiate." }
        if t.contains("meditation") { return "Hold the line inside." }
        if t.contains("read") && t.contains("pages") { return "Train focus. Feed the mind." }
        if t.contains("walk") { return "Move with intent. Build momentum." }
        if t.contains("workout") || t.contains("push-ups") { return "Stress the body. Strengthen the will." }
        if t.contains("plan next day") { return "Decide tomorrow now." }
        if t.contains("top priority") { return "Name the target. Remove noise." }
        if t.contains("long-term goal") { return "Aim the arc. Commit the path." }

        // Default: neutral, operational, non-lecture
        return "Execute the standard. No drift."
    }

    static func rules(for title: String) -> [String] {
        let t = title.lowercased()

        if t.contains("clean workspace") {
            return ["Remove trash", "Put everything back in place", "Leave only what you need for tomorrow"]
        }
        if t.contains("deep work") {
            return ["One single task", "Phone away", "No switching"]
        }
        if t.contains("cold shower") || t.contains("cool/cold shower") {
            return ["No music", "No gradual warming", "Stay until timer ends"]
        }
        if t.contains("meditation") {
            return ["Sit still", "Breathe slow", "Return when the mind drifts"]
        }
        if t.contains("read") && t.contains("pages") {
            return ["One book", "No skimming", "No phone"]
        }
        if t.contains("walk") {
            return ["Move fast", "No phone", "Finish the full time"]
        }
        if t.contains("workout") {
            return ["No pauses", "Full range", "Finish strong"]
        }
        if t.contains("push-ups") {
            return ["Strict reps", "Short rests", "Finish the total"]
        }
        if t.contains("plan next day") {
            return ["Write 3 tasks", "Pick the first task", "Remove one distraction"]
        }
        if t.contains("top priority") {
            return ["Write 1 priority", "Write next action", "Delete one low-value task"]
        }
        if t.contains("long-term goal") {
            return ["Write 1 goal", "Write 1 constraint", "Write the next step"]
        }

        return ["Remove distractions", "Commit to completion", "Finish clean"]
    }

    static func payload(for title: String) -> (mission: String, rules: [String]) {
        (mission(for: title), rules(for: title))
    }
}
