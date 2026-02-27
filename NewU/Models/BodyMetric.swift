import Foundation
import SwiftData

@Model
final class BodyMetric {
    var date: Date
    var weight: Double?
    var bodyFat: Double?
    var notes: String

    init(date: Date = .now, weight: Double? = nil, bodyFat: Double? = nil, notes: String = "") {
        self.date = date
        self.weight = weight
        self.bodyFat = bodyFat
        self.notes = notes
    }
}
