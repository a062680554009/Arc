import SwiftUI

struct SelectableTaskCard: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let accent: Color
    let onTap: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        accent: Color = .white,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.accent = accent
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {

                // Tight stoic indicator (quiet, controlled)
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(isSelected ? 0.35 : 0.18), lineWidth: 1)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.primary.opacity(0.35))
                            .frame(width: 8, height: 8)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: 0.15), value: isSelected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(isSelected ? 0.14 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
