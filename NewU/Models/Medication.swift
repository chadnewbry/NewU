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

    @Relationship(deleteRule: .nullify, inverse: \Injection.medication)
    var injections: [Injection]?

    @Relationship(deleteRule: .nullify, inverse: \UserProfile.selectedMedication)
    var userProfiles: [UserProfile]?

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
}
