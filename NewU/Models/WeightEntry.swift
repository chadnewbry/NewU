import Foundation
import SwiftData

enum WeightSource: String, Codable, CaseIterable {
    case manual
    case healthKit
}

@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weightLbs: Double
    var source: WeightSource

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weightLbs: Double = 0,
        source: WeightSource = .manual
    ) {
        self.id = id
        self.date = date
        self.weightLbs = weightLbs
        self.source = source
    }

    var weightKg: Double {
        weightLbs * 0.453592
    }
}
