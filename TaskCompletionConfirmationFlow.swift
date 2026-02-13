import SwiftUI
import UIKit

/// A calm, integrity-first confirmation flow shown after a timed task ends.
/// Designed to encourage honesty without guilt and to keep "momentum" meaningful.
struct TaskCompletionConfirmationFlow: View {
    enum Phase: Equatable {
        case confirm
        case recordingFull
    }

    let taskTitle: String
    let onConfirmFull: () -> Void
    let onStoppedEarly: (_ reflection: String?) -> Void
    let onReturn: () -> Void

    @State private var showReflection = false
    @State private var reflectionText: String = ""
    @State private var phase: Phase = .confirm

    var body: some View {
        VStack(spacing: 20) {
            header
            actions
        }
        .padding(20)
        .background(cardBackground)
        .sheet(isPresented: $showReflection) {
            EarlyStopReflectionSheet(
                taskTitle: taskTitle,
                reflection: $reflectionText,
                onSave: {
                    let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    onStoppedEarly(trimmed.isEmpty ? nil : trimmed)
                    onReturn()
                },
                onSkip: {
                    onStoppedEarly(nil)
                    onReturn()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 10) {
            Text(taskTitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .accessibilityLabel(Text("Task: \(taskTitle)"))

            Text("Time completed.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Text("Did you complete the full time?")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .padding(.horizontal, 12)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            primaryConfirmButton
            stoppedEarlyButton
        }
    }

    private var primaryConfirmButton: some View {
        Button {
            guard phase == .confirm else { return }
            phase = .recordingFull
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            // Quiet “receipt” feedback, then return.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onConfirmFull()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                onReturn()
            }
        } label: {
            PrimaryConfirmLabel(phase: phase)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(.plain)
        .background(primaryButtonBackground)
        .overlay(primaryButtonBorder)
        .accessibilityHint("Awards momentum and returns to ritual.")
    }

    private var stoppedEarlyButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showReflection = true
        } label: {
            Text("I stopped early")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(.plain)
        .background(secondaryButtonBackground)
        .overlay(secondaryButtonBorder)
        .accessibilityHint("No momentum awarded. Optional reflection before returning.")
    }

    // MARK: - Backgrounds / Borders (split out to help the compiler)

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.black.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var primaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(phase == .recordingFull ? 0.14 : 0.18))
    }

    private var primaryButtonBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.18), lineWidth: 1)
    }

    private var secondaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.08))
    }

    private var secondaryButtonBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.14), lineWidth: 1)
    }
}

// MARK: - Extracted label view (this is the big win for type-checking)

private struct PrimaryConfirmLabel: View {
    let phase: TaskCompletionConfirmationFlow.Phase

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private var iconName: String {
        phase == .recordingFull ? "checkmark.circle.fill" : "checkmark"
    }

    private var title: String {
        phase == .recordingFull ? "Recorded" : "Yes, I did"
    }
}

struct EarlyStopReflectionSheet: View {
    let taskTitle: String
    @Binding var reflection: String
    let onSave: () -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let chips: [String] = [
        "Got interrupted",
        "Energy dipped",
        "Time ran out",
        "Too ambitious today"
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What changed?")
                        .font(.title3.weight(.semibold))
                    Text("Optional. Helps you adjust tomorrow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Quick chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(chips, id: \.self) { chip in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                applyChip(chip)
                            } label: {
                                Text(chip)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }

                ZStack(alignment: .topLeading) {
                    if reflection.isEmpty {
                        Text("Add a short note (optional)")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 10)
                            .padding(.leading, 6)
                            .accessibilityHidden(true)
                    }

                    TextEditor(text: $reflection)
                        .frame(minHeight: 110)
                        .scrollContentBackground(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .accessibilityLabel("Reflection")
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle(taskTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                        onSkip()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                        onSave()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func applyChip(_ chip: String) {
        if reflection.isEmpty {
            reflection = chip
            return
        }
        if reflection.contains(chip) { return }

        let needsSpace = reflection.hasSuffix(".") || reflection.hasSuffix("!") || reflection.hasSuffix("?")
        reflection += needsSpace ? " " : ". "
        reflection += chip
    }
}

