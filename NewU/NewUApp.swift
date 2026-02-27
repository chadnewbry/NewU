import SwiftUI
import SwiftData

@main
struct NewUApp: App {
    let dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    dataManager.seedDefaultMedications()
                }
        }
        .modelContainer(dataManager.modelContainer)
    }
}
