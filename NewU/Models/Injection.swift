import Foundation
import SwiftData

enum InjectionSite: String, Codable, CaseIterable {
    case leftAbdomen
    case rightAbdomen
    case leftThigh
    case rightThigh
    case leftArm
    case rightArm

    var displayName: String {
        switch self {
        case .leftAbdomen: "Left Abdomen"
        case .rightAbdomen: "Right Abdomen"
        case .leftThigh: "Left Thigh"
        case .rightThigh: "Right Thigh"
        case .leftArm: "Left Arm"
        case .rightArm: "Right Arm"
        }
    }
}

@Model
final class Injection {
    @Attribute(.unique) var id: UUID
    var date: Date
    var time: Date
    var medication: Medication?
    var dosageMg: Double
    var dosageUnits: Int?
    var injectionSite: InjectionSite
    var painLevel: Int
    var notes: String?
    var prepChecklistCompleted: Bool

    @Relationship(deleteRule: .nullify, inverse: \SideEffect.relatedInjection)
    var sideEffects: [SideEffect]?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        time: Date = .now,
        medication: Medication? = nil,
        dosageMg: Double = 0,
        dosageUnits: Int? = nil,
        injectionSite: InjectionSite = .leftAbdomen,
        painLevel: Int = 1,
        notes: String? = nil,
        prepChecklistCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.time = time
        self.medication = medication
        self.dosageMg = dosageMg
        self.dosageUnits = dosageUnits
        self.injectionSite = injectionSite
        self.painLevel = painLevel
        self.notes = notes
        self.prepChecklistCompleted = prepChecklistCompleted
    }
}
