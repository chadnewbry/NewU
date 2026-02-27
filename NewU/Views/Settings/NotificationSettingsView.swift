import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Bindable var profile: UserProfile
    @StateObject private var notificationManager = NotificationManager.shared

    private let weekdays = [
        (1, "Sunday"), (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"),
        (5, "Thursday"), (6, "Friday"), (7, "Saturday")
    ]

    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $profile.notificationsEnabled)
                    .onChange(of: profile.notificationsEnabled) { _, enabled in
                        if enabled {
                            Task {
                                let granted = await notificationManager.requestPermission()
                                if !granted {
                                    profile.notificationsEnabled = false
                                }
                            }
                        }
                        notificationManager.updateReminders(for: profile)
                    }
            }

            if profile.notificationsEnabled {
                Section("Injection Day Reminder") {
                    Picker("Injection Day", selection: Binding(
                        get: { profile.injectionDayOfWeek ?? 2 },
                        set: { profile.injectionDayOfWeek = $0 }
                    )) {
                        ForEach(weekdays, id: \.0) { day in
                            Text(day.1).tag(day.0)
                        }
                    }

                    DatePicker("Reminder Time", selection: Binding(
                        get: {
                            Calendar.current.date(from: DateComponents(
                                hour: profile.reminderHour,
                                minute: profile.reminderMinute
                            )) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            profile.reminderHour = components.hour ?? 9
                            profile.reminderMinute = components.minute ?? 0
                        }
                    ), displayedComponents: .hourAndMinute)
                }

                Section("Optional Reminders") {
                    Toggle("Day-Before Reminder", isOn: $profile.dayBeforeReminderEnabled)
                    Toggle("Missed Injection Alert", isOn: $profile.missedInjectionReminderEnabled)
                }

                Section {
                    Button("Save & Update Reminders") {
                        notificationManager.updateReminders(for: profile)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
    }
}
