import SwiftUI

/// Separate from Momentum Ring.
/// This represents the 30-day arc progression (Arc X/30).
struct ArcProgressBar: View {
    let currentDay: Int
    let totalDays: Int

    var body: some View {
        let clampedDay = min(max(currentDay, 1), max(totalDays, 1))
        let progress = Double(clampedDay) / Double(max(totalDays, 1))
        let percent = Int((progress * 100).rounded())

        VStack(alignment: .leading, spacing: ArcSpacing.sm) {
            HStack {
                Text("Arc \(clampedDay)/\(totalDays)")
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .opacity(0.85)
                Spacer()
                Text("\(percent)%")
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .opacity(0.60)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))

                    Capsule()
                        .fill(Color.primary.opacity(0.26))
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.45), value: progress)
                }
            }
            .frame(height: 8)
            .accessibilityElement()
            .accessibilityLabel("Arc progress")
            .accessibilityValue("\(clampedDay) of \(totalDays) days, \(percent) percent")
        }
        .padding(.horizontal, 4)
    }
}
