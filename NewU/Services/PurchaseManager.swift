import Foundation
import RevenueCat
import SwiftData

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPurchased: Bool = false
    @Published var currentOffering: Offering?

    private let entitlementID = "GLP 1 Tracker Pro"

    private init() {}

    // MARK: - Configure (call once at launch)

    func configure(apiKey: String) {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self

        Task {
            await checkPurchaseStatus()
            await fetchOffering()
        }
    }

    // MARK: - Public API

    @discardableResult
    func checkPurchaseStatus() async -> Bool {
        guard let customerInfo = try? await Purchases.shared.customerInfo() else { return false }
        let purchased = customerInfo.entitlements[entitlementID]?.isActive == true
        isPurchased = purchased
        if purchased { updateUserProfile(purchased: true) }
        return purchased
    }

    func fetchOffering() async {
        guard let offerings = try? await Purchases.shared.offerings() else { return }
        currentOffering = offerings.current
    }

    func purchase(package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        let purchased = result.customerInfo.entitlements[entitlementID]?.isActive == true
        isPurchased = purchased
        if purchased { updateUserProfile(purchased: true) }
        return purchased
    }

    func restorePurchases() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        let purchased = customerInfo.entitlements[entitlementID]?.isActive == true
        isPurchased = purchased
        if purchased { updateUserProfile(purchased: true) }
        return purchased
    }

    // MARK: - Called by PaywallView callbacks

    func handleCustomerInfo(_ customerInfo: CustomerInfo) {
        let purchased = customerInfo.entitlements[entitlementID]?.isActive == true
        isPurchased = purchased
        if purchased { updateUserProfile(purchased: true) }
    }

    // MARK: - Private

    private func updateUserProfile(purchased: Bool) {
        let dataManager = DataManager.shared
        guard let profile = dataManager.getUserProfile() else { return }
        profile.hasPurchasedFullAccess = purchased
        dataManager.save()
    }
}

// MARK: - PurchasesDelegate (handles background transaction updates)

extension PurchaseManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            let purchased = customerInfo.entitlements[self.entitlementID]?.isActive == true
            self.isPurchased = purchased
            if purchased { self.updateUserProfile(purchased: true) }
        }
    }
}
