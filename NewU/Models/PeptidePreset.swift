import Foundation

struct PeptidePreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let commonVialSizeMg: Double
    let suggestedWaterMl: Double
    let typicalDoseMcg: Double
    let halfLifeHours: Double
    let icon: String

    // Convenience aliases
    var vialAmountMg: Double { commonVialSizeMg }
    var defaultWaterMl: Double { suggestedWaterMl }
    var defaultDoseMcg: Double { typicalDoseMcg }

    static let allPresets: [PeptidePreset] = [
        PeptidePreset(name: "BPC-157", commonVialSizeMg: 5, suggestedWaterMl: 2, typicalDoseMcg: 250, halfLifeHours: 4, icon: "cross.vial.fill"),
        PeptidePreset(name: "Semaglutide", commonVialSizeMg: 5, suggestedWaterMl: 2.5, typicalDoseMcg: 250, halfLifeHours: 168, icon: "pills.fill"),
        PeptidePreset(name: "Tirzepatide", commonVialSizeMg: 10, suggestedWaterMl: 2, typicalDoseMcg: 2500, halfLifeHours: 120, icon: "pills.fill"),
        PeptidePreset(name: "TB-500", commonVialSizeMg: 5, suggestedWaterMl: 2, typicalDoseMcg: 2500, halfLifeHours: 8, icon: "cross.vial.fill"),
        PeptidePreset(name: "PT-141", commonVialSizeMg: 10, suggestedWaterMl: 2, typicalDoseMcg: 1750, halfLifeHours: 2, icon: "heart.fill"),
        PeptidePreset(name: "Ipamorelin", commonVialSizeMg: 5, suggestedWaterMl: 2.5, typicalDoseMcg: 200, halfLifeHours: 2, icon: "bolt.fill"),
        PeptidePreset(name: "CJC-1295", commonVialSizeMg: 2, suggestedWaterMl: 2, typicalDoseMcg: 100, halfLifeHours: 144, icon: "moon.fill"),
        PeptidePreset(name: "GHK-Cu", commonVialSizeMg: 50, suggestedWaterMl: 5, typicalDoseMcg: 200, halfLifeHours: 12, icon: "leaf.fill"),
    ]

    // Alias for backward compatibility
    static var presets: [PeptidePreset] { allPresets }
}
