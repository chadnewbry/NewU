import SwiftUI

struct NotificationStepView: View {
    @Binding var notificationsEnabled: Bool
    let onContinue: () -> Void

    @State private var requestInProgress = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 8) {
                    Text("Never miss a\nshot day")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("Get reminders on injection day, the day before, and if you forget to log.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()
            Spacer()

            VStack(spacing: 12) {
                Button {
                    requestNotifications()
                } label: {
                    HStack(spacing: 8) {
                        if requestInProgress {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Enable Notifications")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(requestInProgress)

                Button(action: skip) {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func requestNotifications() {
        requestInProgress = true

        Task {
            let granted = await NotificationManager.shared.requestPermission()
            notificationsEnabled = granted
            requestInProgress = false
            onContinue()
        }
    }

    private func skip() {
        notificationsEnabled = false
        onContinue()
    }
}
