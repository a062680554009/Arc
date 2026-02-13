import SwiftUI

struct SingleChoiceSection<Item: Identifiable & Hashable>: View {
    let title: String
    let rightLabel: String?
    let prompt: String
    let iconSystemName: String?
    let accent: Color

    let items: [Item]
    let itemTitle: (Item) -> String
    let itemSubtitle: (Item) -> String?

    @Binding var selection: Item?
    let onSelect: (() -> Void)?

    init(
        title: String,
        rightLabel: String? = nil,
        prompt: String,
        iconSystemName: String? = nil,
        accent: Color,
        items: [Item],
        selection: Binding<Item?>,
        itemTitle: @escaping (Item) -> String,
        itemSubtitle: @escaping (Item) -> String? = { _ in nil },
        onSelect: (() -> Void)? = nil
    ) {
        self.title = title
        self.rightLabel = rightLabel
        self.prompt = prompt
        self.iconSystemName = iconSystemName
        self.accent = accent
        self.items = items
        self._selection = selection
        self.itemTitle = itemTitle
        self.itemSubtitle = itemSubtitle
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {
                if let iconSystemName {
                    Image(systemName: iconSystemName)
                        .font(.headline)
                        .foregroundStyle(accent)
                }

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                if let rightLabel {
                    Text(rightLabel)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Text(prompt)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            VStack(spacing: 10) {
                ForEach(items) { item in
                    SelectableTaskCard(
                        title: itemTitle(item),
                        subtitle: itemSubtitle(item),
                        isSelected: selection == item,
                        accent: accent
                    ) {
                        selection = item
                        onSelect?()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}
