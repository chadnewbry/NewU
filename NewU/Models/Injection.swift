import Foundation
import SwiftData

@Model
final class Injection {
    var date: Date
    var medication: String
    var dosage: Double
    var unit: String
    var site: String
    var notes: String

    init(date: Date = .now, medication: String = "", dosage: Double = 0, unit: String = "mg", site: String = "", notes: String = "") {
        self.date = date
        self.medication = medication
        self.dosage = dosage
        self.unit = unit
        self.site = site
        self.notes = notes
    }
}
