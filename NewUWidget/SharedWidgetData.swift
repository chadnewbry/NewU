import Foundation

// MARK: - Shared Keys (mirrors WidgetDataManager.Key)

enum WidgetKey: String {
    case nextInjectionDays   = "widget.nextInjectionDays"
    case medicationName      = "widget.medicationName"
    case dosageMg            = "widget.dosageMg"
    case medicationLevelPct  = "widget.medicationLevelPct"
    case currentWeightLbs    = "widget.currentWeightLbs"
    case goalWeightLbs       = "widget.goalWeightLbs"
    case todayProteinG       = "widget.todayProteinG"
    case proteinGoalG        = "widget.proteinGoalG"
    case todayFiberG         = "widget.todayFiberG"
    case fiberGoalG          = "widget.fiberGoalG"
    case todayWaterOz        = "widget.todayWaterOz"
    case waterGoalOz         = "widget.waterGoalOz"
    case todayCalories       = "widget.todayCalories"
    case calorieGoal         = "widget.calorieGoal"
    case lastUpdated         = "widget.lastUpdated"
}

// MARK: - Widget Entry Data

struct WidgetEntryData {
    let nextInjectionDays: Int
    let medicationName: String
    let dosageMg: Double
    let medicationLevelPct: Double
    let currentWeightLbs: Double
    let goalWeightLbs: Double
    let todayProteinG: Double
    let proteinGoalG: Double
    let todayFiberG: Double
    let fiberGoalG: Double
    let todayWaterOz: Double
    let waterGoalOz: Double
    let todayCalories: Int
    let calorieGoal: Int

    static var placeholder: WidgetEntryData {
        WidgetEntryData(
            nextInjectionDays: 3,
            medicationName: "Semaglutide",
            dosageMg: 0.5,
            medicationLevelPct: 0.72,
            currentWeightLbs: 185,
            goalWeightLbs: 160,
            todayProteinG: 65,
            proteinGoalG: 100,
            todayFiberG: 14,
            fiberGoalG: 28,
            todayWaterOz: 40,
            waterGoalOz: 64,
            todayCalories: 1200,
            calorieGoal: 1800
        )
    }

    static func fromSharedDefaults() -> WidgetEntryData {
        let suite = UserDefaults(suiteName: "group.com.newu.shared")

        func int(_ key: WidgetKey) -> Int { suite?.integer(forKey: key.rawValue) ?? 0 }
        func dbl(_ key: WidgetKey) -> Double { suite?.double(forKey: key.rawValue) ?? 0 }
        func str(_ key: WidgetKey) -> String { suite?.string(forKey: key.rawValue) ?? "" }

        return WidgetEntryData(
            nextInjectionDays: int(.nextInjectionDays),
            medicationName: str(.medicationName),
            dosageMg: dbl(.dosageMg),
            medicationLevelPct: dbl(.medicationLevelPct),
            currentWeightLbs: dbl(.currentWeightLbs),
            goalWeightLbs: dbl(.goalWeightLbs),
            todayProteinG: dbl(.todayProteinG),
            proteinGoalG: dbl(.proteinGoalG),
            todayFiberG: dbl(.todayFiberG),
            fiberGoalG: dbl(.fiberGoalG),
            todayWaterOz: dbl(.todayWaterOz),
            waterGoalOz: dbl(.waterGoalOz),
            todayCalories: int(.todayCalories),
            calorieGoal: int(.calorieGoal)
        )
    }
}
