import SwiftUI

// MARK: - Reusable section wrapper

struct RitualSectionHeader: View {
    let title: String
    let subtitle: String?
    let accent: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Stoic indicator (subtle, not color-coded blocks)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.primary.opacity(0.22))
                .frame(width: 3, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Forge

struct ForgeSectionView: View {
    let dayNumber: Int
    let actions: [ForgeAction]

    @Binding var selected: ForgeAction?
    @Binding var reflection: String
    @Binding var done: Bool

    @Binding var secondsLeft: Int
    @Binding var timerRunning: Bool

    let onPick: (ForgeAction) -> Void
    let onOpenRitual: (String, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RitualSectionHeader(
                title: "FORGE",
                subtitle: "Choose the resistance you will overcome",
                accent: .white
            )

            VStack(alignment: .leading, spacing: 8) {
                ForEach(actions) { a in
                    SelectableTaskCard(
                        title: a.title,
                        isSelected: selected?.title == a.title,
                        accent: .white
                    ) {
                        onPick(a)
                        if let sec = a.timeSeconds, sec > 0 {
                            onOpenRitual(a.title, sec)
                        }
                    }
                }
            }

            // Reflection (kept minimal; users requested no lectures)
            VStack(alignment: .leading, spacing: 8) {
                Text("Reflection")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("One line.", text: $reflection, axis: .vertical)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    )
                    .foregroundStyle(.primary)

            }

            Toggle(isOn: $done) {
                Text("Mark complete")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .toggleStyle(.switch)
        }
    }
}

// MARK: - Temper

struct TemperSectionView: View {
    let actions: [TemperAction]

    @Binding var selected: TemperAction?
    @Binding var reflection: String
    @Binding var done: Bool

    @Binding var secondsLeft: Int
    @Binding var timerRunning: Bool

    let onPick: (TemperAction) -> Void
    let onOpenRitual: (String, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RitualSectionHeader(
                title: "TEMPER",
                subtitle: "Hold focus. No drift.",
                accent: .white
            )

            VStack(alignment: .leading, spacing: 8) {
                ForEach(actions) { a in
                    SelectableTaskCard(
                        title: a.title,
                        isSelected: selected?.title == a.title,
                        accent: .white
                    ) {
                        onPick(a)
                        onOpenRitual(a.title, a.timeSeconds)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Reflection")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("One line.", text: $reflection, axis: .vertical)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    )
                    .foregroundStyle(.primary)

            }

            Toggle(isOn: $done) {
                Text("Mark complete")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .toggleStyle(.switch)
        }
    }
}

// MARK: - Align

struct AlignSectionView: View {
    let actions: [AlignAction]

    @Binding var selected: AlignAction?
    @Binding var reflection: String
    @Binding var done: Bool

    @Binding var secondsLeft: Int
    @Binding var timerRunning: Bool

    let onPick: (AlignAction) -> Void
    let onOpenRitual: (String, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RitualSectionHeader(
                title: "ALIGN",
                subtitle: "Set direction. Remove noise.",
                accent: .white
            )

            VStack(alignment: .leading, spacing: 8) {
                ForEach(actions) { a in
                    SelectableTaskCard(
                        title: a.title,
                        isSelected: selected?.title == a.title,
                        accent: .white
                    ) {
                        onPick(a)
                        onOpenRitual(a.title, a.timeSeconds)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Reflection")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("One line.", text: $reflection, axis: .vertical)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    )
                    .foregroundStyle(.primary)

            }

            Toggle(isOn: $done) {
                Text("Mark complete")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .toggleStyle(.switch)
        }
    }
}
