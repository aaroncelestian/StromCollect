import SwiftUI
import SwiftData

@main
struct StromatoliteCollectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SpecimenCollection.self, SpecimenRecord.self])
    }
}
