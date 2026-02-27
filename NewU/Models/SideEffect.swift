import Foundation
import SwiftData

enum SideEffectType: String, Codable, CaseIterable {
    case nausea
    case heartburn
    case fatigue
    case moodSwings
    case constipation
    case diarrhea
    case headache
    case dizziness
    case custom

    var displayName: String {
        switch self {
        case .nausea: "Nausea"
        case .heartburn: "Heartburn"
        case .fatigue: "Fatigue"
        case .moodSwings: "Mood Swings"
        case .constipation: "Constipation"
        case .diarrhea: "Diarrhea"
        case .headache: "Headache"
        case .dizziness: "Dizziness"
        case .custom: "Custom"
        }
    }
}

@Model
final class SideEffect {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: SideEffectType
    var customName: String?
    var intensity: Int
    var notes: String?
    var relatedInjection: Injection?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        type: SideEffectType = .nausea,
        customName: String? = nil,
        intensity: Int = 1,
        notes: String? = nil,
        relatedInjection: Injection? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.customName = customName
        self.intensity = intensity
        self.notes = notes
        self.relatedInjection = relatedInjection
    }
}
