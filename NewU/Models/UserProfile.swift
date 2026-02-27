import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var heightInches: Double
    var goalWeightLbs: Double
    var startWeightLbs: Double
    var startDate: Date
    var dailyProteinGoalGrams: Double
    var dailyFiberGoalGrams: Double
    var dailyCalorieGoal: Int
    var dailyWaterGoalOz: Double
    var dailyStepGoal: Int
    var selectedMedication: Medication?
    var currentDosageMg: Double?
    var injectionDayOfWeek: Int?
    var reminderHour: Int
    var reminderMinute: Int
    var dayBeforeReminderEnabled: Bool
    var missedInjectionReminderEnabled: Bool
    var notificationsEnabled: Bool
    var hasCompletedOnboarding: Bool
    var hasPurchasedFullAccess: Bool
    var freeUsesRemaining: Int

    init(
        id: UUID = UUID(),
        heightInches: Double = 70,
        goalWeightLbs: Double = 150,
        startWeightLbs: Double = 200,
        startDate: Date = .now,
        dailyProteinGoalGrams: Double = 100,
        dailyFiberGoalGrams: Double = 28,
        dailyCalorieGoal: Int = 2000,
        dailyWaterGoalOz: Double = 64,
        dailyStepGoal: Int = 10000,
        selectedMedication: Medication? = nil,
        currentDosageMg: Double? = nil,
        injectionDayOfWeek: Int? = nil,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        dayBeforeReminderEnabled: Bool = true,
        missedInjectionReminderEnabled: Bool = true,
        notificationsEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false,
        hasPurchasedFullAccess: Bool = false,
        freeUsesRemaining: Int = 5
    ) {
        self.id = id
        self.heightInches = heightInches
        self.goalWeightLbs = goalWeightLbs
        self.startWeightLbs = startWeightLbs
        self.startDate = startDate
        self.dailyProteinGoalGrams = dailyProteinGoalGrams
        self.dailyFiberGoalGrams = dailyFiberGoalGrams
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyWaterGoalOz = dailyWaterGoalOz
        self.dailyStepGoal = dailyStepGoal
        self.selectedMedication = selectedMedication
        self.currentDosageMg = currentDosageMg
        self.injectionDayOfWeek = injectionDayOfWeek
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.dayBeforeReminderEnabled = dayBeforeReminderEnabled
        self.missedInjectionReminderEnabled = missedInjectionReminderEnabled
        self.notificationsEnabled = notificationsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasPurchasedFullAccess = hasPurchasedFullAccess
        self.freeUsesRemaining = freeUsesRemaining
    }
}
