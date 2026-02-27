import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    // MARK: - Notification Identifiers

    private enum Identifier {
        static let injectionReminder = "injection-reminder"
        static let dayBeforeReminder = "day-before-reminder"
        static let missedInjection = "missed-injection-reminder"
    }

    private init() {
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            print("NotificationManager: permission request failed — \(error)")
            isAuthorized = false
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Injection Day Reminder

    func scheduleInjectionReminder(dayOfWeek: Int, time: DateComponents, medicationName: String) {
        var dateComponents = DateComponents()
        dateComponents.weekday = dayOfWeek
        dateComponents.hour = time.hour
        dateComponents.minute = time.minute

        let content = UNMutableNotificationContent()
        content.title = "Shot Day! 💉"
        content.body = "Time for your \(medicationName) injection. Tap to log it."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.injectionReminder,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("NotificationManager: failed to schedule injection reminder — \(error)")
            }
        }
    }

    // MARK: - Schedule Day-Before Reminder

    func scheduleDayBeforeReminder(dayOfWeek: Int, time: DateComponents) {
        // Day before the injection day (wrap Sunday 1 -> Saturday 7)
        let dayBefore = dayOfWeek == 1 ? 7 : dayOfWeek - 1

        var dateComponents = DateComponents()
        dateComponents.weekday = dayBefore
        dateComponents.hour = time.hour
        dateComponents.minute = time.minute

        let content = UNMutableNotificationContent()
        content.title = "Reminder 📋"
        content.body = "Tomorrow is shot day — make sure your supplies are ready!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.dayBeforeReminder,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("NotificationManager: failed to schedule day-before reminder — \(error)")
            }
        }
    }

    // MARK: - Schedule Missed Injection Reminder

    /// Schedules a reminder for the morning after injection day.
    /// In practice, you'd cancel this when an injection is logged on shot day.
    func scheduleMissedInjectionReminder(dayOfWeek: Int, medicationName: String) {
        // Morning after injection day
        let dayAfter = dayOfWeek == 7 ? 1 : dayOfWeek + 1

        var dateComponents = DateComponents()
        dateComponents.weekday = dayAfter
        dateComponents.hour = 9
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Missed Injection ⚠️"
        content.body = "It looks like you didn't log your \(medicationName) injection yesterday. Did you forget?"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.missedInjection,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("NotificationManager: failed to schedule missed injection reminder — \(error)")
            }
        }
    }

    // MARK: - Cancel

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelMissedInjectionReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.missedInjection])
    }

    // MARK: - Update All Reminders

    /// Reconfigures all notifications based on the user's current profile.
    func updateReminders(for userProfile: UserProfile) {
        cancelAllReminders()

        guard userProfile.notificationsEnabled,
              let dayOfWeek = userProfile.injectionDayOfWeek else {
            return
        }

        let medicationName = userProfile.selectedMedication?.name ?? "medication"

        var time = DateComponents()
        time.hour = userProfile.reminderHour
        time.minute = userProfile.reminderMinute

        // Main injection day reminder
        scheduleInjectionReminder(dayOfWeek: dayOfWeek, time: time, medicationName: medicationName)

        // Day-before reminder
        if userProfile.dayBeforeReminderEnabled {
            scheduleDayBeforeReminder(dayOfWeek: dayOfWeek, time: time)
        }

        // Missed injection reminder
        if userProfile.missedInjectionReminderEnabled {
            scheduleMissedInjectionReminder(dayOfWeek: dayOfWeek, medicationName: medicationName)
        }
    }
}
