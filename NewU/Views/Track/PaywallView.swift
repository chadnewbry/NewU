import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RevenueCatUI.PaywallView()
            .onPurchaseCompleted { customerInfo in
                purchaseManager.handleCustomerInfo(customerInfo)
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                purchaseManager.handleCustomerInfo(customerInfo)
                if purchaseManager.isPurchased {
                    dismiss()
                }
            }
    }
}

#Preview {
    PaywallView()
}
