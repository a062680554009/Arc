import SwiftUI
import SwiftData

@main
struct ArcApp: App {

    // SwiftData uses Core Data under the hood; creating Application Support up front
    // prevents noisy "Failed to stat" logs on first launch.
    let container: ModelContainer

    init() {
        let schema = Schema([Arc.self, ArcDay.self])

        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // Ensure the directory exists before SwiftData/Core Data tries to create the store file.
        try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true)

        let storeURL = appSupport.appendingPathComponent("default.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
