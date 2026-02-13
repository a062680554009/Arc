import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscription = SubscriptionManager()

    var body: some View {
        ZStack {
            ArcTheme.Colors.background.ignoresSafeArea()

            MainAppView(modelContext: modelContext)
                .environmentObject(subscription)
                .task { await subscription.refreshStatus() }
        }
        // Force dark scheme at the root so UIKit-backed colors resolve correctly.
        .environment(\.colorScheme, .dark)
    }
}
