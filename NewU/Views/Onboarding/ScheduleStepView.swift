import SwiftUI

struct ScheduleStepView: View {
    @Binding var injectionDayOfWeek: Int
    @Binding var reminderHour: Int
    @Binding var reminderMinute: Int
    let onContinue: () -> Void

    @State private var reminderDate: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }()

    private let days: [(name: String, short: String, value: Int)] = [
        ("Sunday", "Sun", 1),
        ("Monday", "Mon", 2),
        ("Tuesday", "Tue", 3),
        ("Wednesday", "Wed", 4),
        ("Thursday", "Thu", 5),
        ("Friday", "Fri", 6),
        ("Saturday", "Sat", 7),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("What day do you\ntake your shot?")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("We'll send you a reminder")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Day picker
                HStack(spacing: 8) {
                    ForEach(days, id: \.value) { day in
                        dayCircle(day: day)
                    }
                }
                .padding(.horizontal, 16)

                // Time picker
                VStack(spacing: 12) {
                    Text("Reminder time")
                        .font(.headline)

                    DatePicker(
                        "Reminder time",
                        selection: $reminderDate,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 150)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 80)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: saveAndContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
            .background(.ultraThinMaterial)
        }
        .onChange(of: reminderDate) { _, newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 9
            reminderMinute = components.minute ?? 0
        }
    }

    private func dayCircle(day: (name: String, short: String, value: Int)) -> some View {
        let isSelected = injectionDayOfWeek == day.value

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                injectionDayOfWeek = day.value
            }
        } label: {
            VStack(spacing: 4) {
                Text(String(day.short.prefix(1)))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)

                Text(String(day.short.prefix(3)))
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .tertiary)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            )
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.03), radius: isSelected ? 6 : 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func saveAndContinue() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        reminderHour = components.hour ?? 9
        reminderMinute = components.minute ?? 0
        onContinue()
    }
}
