import Foundation
import SwiftData

enum MedicationType: String, Codable, CaseIterable {
    case semaglutide
    case tirzepatide
    case custom
}

@Model
final class Medication {
    @Attribute(.unique) var id: UUID
    var name: String
    var brandName: String?
    var type: MedicationType
    var halfLifeHours: Double
    var defaultDosages: [Double]
    var isCompound: Bool

    @Relationship(deleteRule: .cascade, inverse: \Injection.medication)
    var injections: [Injection]?

    init(
        id: UUID = UUID(),
        name: String,
        brandName: String? = nil,
        type: MedicationType,
        halfLifeHours: Double,
        defaultDosages: [Double] = [],
        isCompound: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brandName = brandName
        self.type = type
        self.halfLifeHours = halfLifeHours
        self.defaultDosages = defaultDosages
        self.isCompound = isCompound
    }

    static func semaglutideDefault() -> Medication {
        Medication(
            name: "Semaglutide",
            brandName: "Ozempic",
            type: .semaglutide,
            halfLifeHours: 168,
            defaultDosages: [0.25, 0.5, 1.0, 1.7, 2.4],
            isCompound: false
        )
    }

    static func tirzepatideDefault() -> Medication {
        Medication(
            name: "Tirzepatide",
            brandName: "Mounjaro",
            type: .tirzepatide,
            halfLifeHours: 120,
            defaultDosages: [2.5, 5.0, 7.5, 10.0, 12.5, 15.0],
            isCompound: false
        )
    }
}
