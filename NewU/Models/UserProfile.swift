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
    var hasCompletedOnboarding: Bool
    var hasPurchasedFullAccess: Bool
    var freeUsesRemaining: Int

    init(
        id: UUID = UUID(),
        heightInches: Double = 0,
        goalWeightLbs: Double = 0,
        startWeightLbs: Double = 0,
        startDate: Date = .now,
        dailyProteinGoalGrams: Double = 0,
        dailyFiberGoalGrams: Double = 27.5,
        dailyCalorieGoal: Int = 0,
        dailyWaterGoalOz: Double = 64,
        dailyStepGoal: Int = 10000,
        selectedMedication: Medication? = nil,
        currentDosageMg: Double? = nil,
        injectionDayOfWeek: Int? = nil,
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
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasPurchasedFullAccess = hasPurchasedFullAccess
        self.freeUsesRemaining = freeUsesRemaining
    }
}
