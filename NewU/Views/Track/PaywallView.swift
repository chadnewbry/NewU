import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = false
    @State private var isRestoring = false
    @State private var purchaseSucceeded = false
    @State private var errorMessage: String?

    private let features: [(icon: String, text: String)] = [
        ("syringe.fill",          "Unlimited injection logging"),
        ("chart.xyaxis.line",     "Complete medication tracking history"),
        ("waveform.path.ecg",     "Medication level monitoring & insights"),
        ("heart.text.clipboard",  "Side effect pattern analysis"),
        ("scalemass.fill",        "Weight & nutrition progress tracking"),
        ("heart.fill",            "Apple Health integration"),
        ("square.grid.2x2.fill",  "Home screen widgets"),
        ("doc.richtext",          "PDF health summary export"),
    ]

    var body: some View {
        if purchaseSucceeded || purchaseManager.isPurchased {
            successView
        } else {
            paywallContent
        }
    }

    // MARK: - Paywall Content

    private var paywallContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 96, height: 96)

                        Image(systemName: "syringe.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 8) {
                        Text("Unlock NewU Forever")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("No subscriptions. No recurring fees.\nJust $6.99.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                // Feature List
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(features, id: \.text) { feature in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(.green.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: feature.icon)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }

                            Text(feature.text)
                                .font(.subheadline)

                            Spacer()

                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)

                        if feature.text != features.last?.text {
                            Divider()
                                .padding(.leading, 66)
                        }
                    }
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                .padding(.horizontal, 20)

                // Competitor comparison
                Text("Others charge $40–120/year. NewU is $6.99 forever.")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }

                // CTA Buttons
                VStack(spacing: 12) {
                    Button {
                        triggerPurchase()
                    } label: {
                        ZStack {
                            Text("Unlock for $6.99")
                                .fontWeight(.semibold)
                                .opacity(isLoading ? 0 : 1)

                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(isLoading || isRestoring)

                    Button {
                        triggerRestore()
                    } label: {
                        HStack(spacing: 6) {
                            if isRestoring {
                                ProgressView()
                                    .scaleEffect(0.75)
                                    .tint(.blue)
                            }
                            Text("Restore Purchase")
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.blue)
                    .disabled(isLoading || isRestoring)

                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                Text("Welcome to NewU Pro! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("You now have full access to all features — forever.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                dismiss()
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.green, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Actions

    private func triggerPurchase() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await purchaseManager.purchase()
                if result {
                    purchaseSucceeded = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func triggerRestore() {
        isRestoring = true
        errorMessage = nil
        Task {
            do {
                let restored = try await purchaseManager.restorePurchases()
                if restored {
                    purchaseSucceeded = true
                } else {
                    errorMessage = "No previous purchase found."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isRestoring = false
        }
    }
}

#Preview {
    PaywallView()
}
