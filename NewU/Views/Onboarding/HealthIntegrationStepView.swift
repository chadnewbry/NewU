import SwiftUI

struct HealthIntegrationStepView: View {
    @Binding var healthKitConnected: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.red)

                VStack(spacing: 8) {
                    Text("Connect\nApple Health?")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("Sync data automatically for a complete picture of your health journey.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(alignment: .leading, spacing: 14) {
                    healthBullet(icon: "scalemass.fill", color: .blue, text: "Weight measurements")
                    healthBullet(icon: "figure.walk", color: .green, text: "Daily step count")
                    healthBullet(icon: "flame.fill", color: .orange, text: "Active calories burned")
                    healthBullet(icon: "bed.double.fill", color: .purple, text: "Sleep data")
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }

            Spacer()
            Spacer()

            VStack(spacing: 12) {
                Button {
                    healthKitConnected = true
                    onContinue()
                } label: {
                    Text("Connect Apple Health")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    healthKitConnected = false
                    onContinue()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func healthBullet(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28)

            Text(text)
                .font(.body)
        }
    }
}
