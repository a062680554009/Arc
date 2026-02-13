import SwiftUI

struct ArcCompletionView: View {
    @ObservedObject var viewModel: ArcViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let arc = viewModel.arc
        let full = ArcEngine.fullDaysCount(for: arc)
        let percent = Int((ArcEngine.completionPercent(for: arc) * 100.0).rounded())
        let finalRank = arc.finalRankRaw ?? "—"

        NavigationStack {
            VStack(spacing: 16) {

                Spacer(minLength: 8)

                VStack(spacing: 10) {
                    Text("30 Days.")
                        .font(.system(size: 40, weight: .black))
                        .tracking(0.5)

                    Text("You didn’t break.")
                        .font(.title2.weight(.bold))
                        .opacity(0.92)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Most people restart by Day 8.")
                        .font(.headline)
                        .opacity(0.9)

                    Text("You didn’t.")
                        .font(.headline.weight(.bold))
                        .opacity(0.95)

                    Text("You are now someone who finishes.")
                        .font(.headline.weight(.bold))
                        .opacity(0.95)
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)

                // Quiet stats (supporting evidence, not the headline)
                VStack(spacing: 10) {
                    row("Full Days", "\(full)/30")
                    row("Completion", "\(percent)%")
                    row("Final Rank", finalRank)
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)

                Button {
                    viewModel.startNewArc()
                    dismiss()
                } label: {
                    Text("Begin New Arc")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
                        )
                        .cornerRadius(16)
                }
                .padding(.top, 2)

                Spacer()
            }
            .padding()
            .navigationTitle("Completion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func row(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t).font(.headline)
            Spacer()
            Text(v).font(.headline.weight(.bold))
        }
    }
}
