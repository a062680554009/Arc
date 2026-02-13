import SwiftUI
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isSubscribed: Bool = false

    func refreshStatus() async {
        // TODO StoreKit 2 later
    }

    func debugToggle() { isSubscribed.toggle() }
}
