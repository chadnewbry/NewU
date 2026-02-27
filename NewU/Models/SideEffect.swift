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
    case injectionSiteReaction
    case lossOfAppetite
    case bloating
    case hairThinning
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
        case .injectionSiteReaction: "Injection Site Reaction"
        case .lossOfAppetite: "Loss of Appetite"
        case .bloating: "Bloating"
        case .hairThinning: "Hair Thinning"
        case .custom: "Other"
        }
    }

    var icon: String {
        switch self {
        case .nausea: "stomach"
        case .heartburn: "flame"
        case .fatigue: "battery.25percent"
        case .moodSwings: "brain.head.profile"
        case .constipation: "arrow.down.to.line"
        case .diarrhea: "arrow.up.to.line"
        case .headache: "head.profile.arrow.forward.and.visionpro"
        case .dizziness: "tornado"
        case .injectionSiteReaction: "bandage"
        case .lossOfAppetite: "fork.knife"
        case .bloating: "circle.dashed"
        case .hairThinning: "comb"
        case .custom: "ellipsis.circle"
        }
    }

    /// All common types (excluding custom)
    static var commonTypes: [SideEffectType] {
        allCases.filter { $0 != .custom }
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

    var displayName: String {
        type == .custom ? (customName ?? "Other") : type.displayName
    }

    static let intensityLabels: [Int: String] = [
        1: "Mild",
        2: "Minor",
        3: "Moderate",
        4: "Strong",
        5: "Severe"
    ]
}
