import SwiftUI
import SwiftData
import UIKit

struct MainAppView: View {
    private let modelContext: ModelContext
    @StateObject private var viewModel: ArcViewModel

    init(modelContext: ModelContext) {
    self.modelContext = modelContext
    _viewModel = StateObject(wrappedValue: ArcViewModel(modelContext: modelContext))

    // Stoic tab bar styling (subtle, less "default glass")
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor.black
    appearance.shadowColor = UIColor.clear

    appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 1.0, alpha: 0.55)
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(white: 1.0, alpha: 0.55)]
    appearance.stackedLayoutAppearance.selected.iconColor = UIColor(white: 1.0, alpha: 0.95)
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(white: 1.0, alpha: 0.95)]

    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
}

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(viewModel: viewModel)
            }
            .tabItem { Label("Home", systemImage: "flame") }

            NavigationStack {
                WeeklyReviewView(viewModel: viewModel)
            }
            .tabItem { Label("Review", systemImage: "calendar") }
        }
        .tint(.white.opacity(0.95))
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.black.opacity(0.92), for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
