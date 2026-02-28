import Foundation
import StoreKit
import SwiftData

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPurchased: Bool = false

    private let productID = "com.newu.glpcalculator.fullaccess"
    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task {
            for await result in Transaction.updates {
                await self.handle(transactionResult: result)
            }
        }
        Task {
            _ = await checkPurchaseStatus()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Public API

    @discardableResult
    func checkPurchaseStatus() async -> Bool {
        var purchased = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                purchased = true
                break
            }
        }
        isPurchased = purchased
        if purchased {
            updateUserProfile(purchased: true)
        }
        return purchased
    }

    func purchase() async throws -> Bool {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            if case .verified(let transaction) = verificationResult {
                await transaction.finish()
                isPurchased = true
                updateUserProfile(purchased: true)
                return true
            }
            return false
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws -> Bool {
        try await AppStore.sync()
        return await checkPurchaseStatus()
    }

    // MARK: - Private

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult,
              transaction.productID == productID,
              transaction.revocationDate == nil else { return }
        await transaction.finish()
        isPurchased = true
        updateUserProfile(purchased: true)
    }

    private func updateUserProfile(purchased: Bool) {
        let dataManager = DataManager.shared
        guard let profile = dataManager.getUserProfile() else { return }
        profile.hasPurchasedFullAccess = purchased
        dataManager.save()
    }
}

enum PurchaseError: LocalizedError {
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in the App Store."
        }
    }
}
