import SwiftUI

struct WelcomeStepView: View {
    let onContinue: () -> Void

    @State private var animate = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "cross.vial.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.pulse, options: .repeating, value: animate)

                Text("NewU")
                    .font(.largeTitle.bold())

                Text("Your peptide journey, simplified.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 48)

            VStack(spacing: 20) {
                valuePropRow(
                    icon: "syringe.fill",
                    color: .blue,
                    title: "Track Injections",
                    subtitle: "Log doses, sites, and side effects"
                )

                valuePropRow(
                    icon: "function",
                    color: .orange,
                    title: "Calculate Dosages",
                    subtitle: "Reconstitution math made easy"
                )

                valuePropRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    title: "Monitor Progress",
                    subtitle: "Weight, nutrition, and medication levels"
                )
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear { animate = true }
    }

    private func valuePropRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
