import SwiftUI
import UIKit

struct RitualTaskScreen: View {
    let title: String
    @Binding var secondsLeft: Int
    @Binding var isRunning: Bool

    let onStart: () -> Void
    let onComplete: () -> Void
    let onStoppedEarly: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var hasBegun = false
    @State private var isFinished = false


    init(
        title: String,
        secondsLeft: Binding<Int>,
        isRunning: Binding<Bool>,
        onStart: @escaping () -> Void,
        onComplete: @escaping () -> Void,
        onStoppedEarly: @escaping (String?) -> Void = { _ in }
    ) {
        self.title = title
        self._secondsLeft = secondsLeft
        self._isRunning = isRunning
        self.onStart = onStart
        self.onComplete = onComplete
        self.onStoppedEarly = onStoppedEarly
    }

    var body: some View {
        let payload = TaskRitualCopy.payload(for: title)

        ZStack {
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                // Single custom back chevron
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                // Engraved centered title
                Text(title.uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text(payload.mission)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(payload.rules.prefix(3), id: \.self) { rule in
                        Text(rule.uppercased())
                            .font(.caption.weight(.semibold))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(.top, 28)

                Spacer()

                // Circular ritual timer
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(isFinished ? 0.18 : 0.08), lineWidth: 1)
                        .frame(width: 190, height: 190)

                    Text(timeString(from: secondsLeft))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .animation(.easeOut(duration: 0.25), value: isFinished)

                Spacer()

                // Primary action changes based on state
                if secondsLeft <= 0 && !hasBegun {
                    Button {
                        dismiss()
                    } label: {
                        Text("CLOSE")
                            .font(.headline.weight(.bold))
                            .tracking(1)
                            .frame(maxWidth: 260)
                            .frame(height: 56)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.bottom, 40)

                } else if isFinished {
                    TaskCompletionConfirmationFlow(
                        taskTitle: title,
                        onConfirmFull: {
                            onComplete()
                        },
                        onStoppedEarly: { reflection in
                            onStoppedEarly(reflection)
                        },
                        onReturn: {
                            dismiss()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 24)

                } else {
                    Button {
                        hasBegun = true
                        onStart()
                    } label: {
                        Text(isRunning ? "IN PROGRESS" : "BEGIN")
                            .font(.headline.weight(.bold))
                            .tracking(1)
                            .frame(maxWidth: 260)
                            .frame(height: 56)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(isRunning ? 0.10 : 0.14))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(isRunning ? 0.14 : 0.20), lineWidth: 1)
                    )
                    .foregroundStyle(.white.opacity(isRunning ? 0.75 : 1.0))
                    .disabled(isRunning)
                    .padding(.bottom, 40)
                }
            }

            // Completion whisper overlay (stoic, not celebratory)
            if isFinished {
                VStack(spacing: 10) {
                    Text("DONE.")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 14)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: secondsLeft) { _, newValue in
            guard hasBegun else { return }
            if newValue <= 0 && !isRunning && !isFinished {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isFinished = true
                }
                successHaptic()
            }
        }
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let secs = max(0, seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func successHaptic() {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
    }
}
