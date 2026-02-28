import Foundation

/// Writes key app data to the shared App Group UserDefaults so WidgetKit extensions can read it.
/// Call `updateWidgetData(...)` whenever relevant data changes.
final class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupID = "group.com.newu.shared"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private init() {}

    // MARK: - Keys

    enum Key: String {
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

    // MARK: - Write

    func updateWidgetData(
        nextInjectionDays: Int,
        medicationName: String,
        dosageMg: Double,
        medicationLevelPct: Double,
        currentWeightLbs: Double,
        goalWeightLbs: Double,
        todayProteinG: Double,
        proteinGoalG: Double,
        todayFiberG: Double,
        fiberGoalG: Double,
        todayWaterOz: Double,
        waterGoalOz: Double,
        todayCalories: Int,
        calorieGoal: Int
    ) {
        guard let defaults else { return }

        defaults.set(nextInjectionDays, forKey: Key.nextInjectionDays.rawValue)
        defaults.set(medicationName, forKey: Key.medicationName.rawValue)
        defaults.set(dosageMg, forKey: Key.dosageMg.rawValue)
        defaults.set(medicationLevelPct, forKey: Key.medicationLevelPct.rawValue)
        defaults.set(currentWeightLbs, forKey: Key.currentWeightLbs.rawValue)
        defaults.set(goalWeightLbs, forKey: Key.goalWeightLbs.rawValue)
        defaults.set(todayProteinG, forKey: Key.todayProteinG.rawValue)
        defaults.set(proteinGoalG, forKey: Key.proteinGoalG.rawValue)
        defaults.set(todayFiberG, forKey: Key.todayFiberG.rawValue)
        defaults.set(fiberGoalG, forKey: Key.fiberGoalG.rawValue)
        defaults.set(todayWaterOz, forKey: Key.todayWaterOz.rawValue)
        defaults.set(waterGoalOz, forKey: Key.waterGoalOz.rawValue)
        defaults.set(todayCalories, forKey: Key.todayCalories.rawValue)
        defaults.set(calorieGoal, forKey: Key.calorieGoal.rawValue)
        defaults.set(Date(), forKey: Key.lastUpdated.rawValue)
    }

    // MARK: - Read (for widgets)

    func readInt(_ key: Key, default defaultValue: Int = 0) -> Int {
        defaults?.integer(forKey: key.rawValue) ?? defaultValue
    }

    func readDouble(_ key: Key, default defaultValue: Double = 0) -> Double {
        defaults?.double(forKey: key.rawValue) ?? defaultValue
    }

    func readString(_ key: Key, default defaultValue: String = "") -> String {
        defaults?.string(forKey: key.rawValue) ?? defaultValue
    }

    func readDate(_ key: Key) -> Date? {
        defaults?.object(forKey: key.rawValue) as? Date
    }
}
