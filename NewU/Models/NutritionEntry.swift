import Foundation
import SwiftData

@Model
final class NutritionEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var proteinGrams: Double
    var fiberGrams: Double
    var calories: Int
    var waterOz: Double

    init(
        id: UUID = UUID(),
        date: Date = .now,
        proteinGrams: Double = 0,
        fiberGrams: Double = 0,
        calories: Int = 0,
        waterOz: Double = 0
    ) {
        self.id = id
        self.date = date
        self.proteinGrams = proteinGrams
        self.fiberGrams = fiberGrams
        self.calories = calories
        self.waterOz = waterOz
    }
}
