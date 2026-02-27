import SwiftUI
import SwiftData

@main
struct NewUApp: App {
    @StateObject private var dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    dataManager.seedDefaultMedications()
                }
        }
        .modelContainer(dataManager.container)
    }
}
