import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Unlock Full Arc")
                    .font(.largeTitle.weight(.bold))

                Text("Free access is limited to 7 days. Subscribe to complete all 30 days and run unlimited arcs.")
                    .multilineTextAlignment(.center)
                    .opacity(0.85)

                VStack(spacing: 10) {
                    option("Monthly", "$9.99 / month")
                    option("Yearly", "$69 / year")
                }

                Button("Continue") {
                    // TODO StoreKit 2 purchase
                    dismiss()
                }
                
            .buttonStyle(ArcPrimaryButtonStyle()).frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.6), lineWidth: 1))
                .cornerRadius(16)

                Spacer()
            }
            .padding()
            .navigationTitle("Paywall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                
            .buttonStyle(ArcPrimaryButtonStyle())}
            }
        }
    }

    private func option(_ t: String, _ p: String) -> some View {
        HStack {
            Text(t).font(.headline)
            Spacer()
            Text(p).font(.headline.weight(.bold))
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
            .padding(.horizontal, ArcSpacing.screenPadding)}
}
