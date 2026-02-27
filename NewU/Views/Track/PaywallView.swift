import SwiftUI

struct PaywallView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Free Logs Used Up")
                .font(.title2)
                .fontWeight(.bold)

            Text("Upgrade to NewU Pro to continue logging injections and tracking your progress.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button {
                // TODO: RevenueCat paywall integration
            } label: {
                Text("Upgrade to Pro")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            Button("Restore Purchases") {
                // TODO: RevenueCat restore
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
