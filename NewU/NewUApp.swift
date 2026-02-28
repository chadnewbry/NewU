import SwiftUI
import SwiftData

@main
struct NewUApp: App {
    let dataManager = DataManager.shared
    let purchaseManager = PurchaseManager.shared

    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch appColorSchemeRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredColorScheme)
                .onAppear {
                    dataManager.seedDefaultMedications()
                    _ = dataManager.getOrCreateUserProfile()
                    Task {
                        await purchaseManager.checkPurchaseStatus()
                    }
                }
        }
        .modelContainer(dataManager.modelContainer)
    }
}
