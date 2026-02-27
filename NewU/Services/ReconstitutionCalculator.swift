import Foundation

/// Calculates reconstitution volumes for compound peptides.
struct ReconstitutionCalculator {

    struct Result {
        /// Concentration after reconstitution in mg/mL.
        let concentrationMgPerMl: Double
        /// Volume to draw into syringe in mL.
        let volumeMl: Double
        /// Syringe units (insulin syringe: 100 units = 1 mL).
        let syringeUnits: Double
    }

    /// Calculate reconstitution result.
    /// - Parameters:
    ///   - peptideAmountMg: Total peptide in the vial, in mg.
    ///   - waterVolumeMl: Bacteriostatic water added, in mL.
    ///   - desiredDoseMg: Desired dose in mg.
    func calculate(peptideAmountMg: Double, waterVolumeMl: Double, desiredDoseMg: Double) -> Result? {
        guard peptideAmountMg > 0, waterVolumeMl > 0, desiredDoseMg > 0 else { return nil }
        let concentration = peptideAmountMg / waterVolumeMl
        let volume = desiredDoseMg / concentration
        let units = volume * 100 // 100 units per mL on insulin syringe
        return Result(concentrationMgPerMl: concentration, volumeMl: volume, syringeUnits: units)
    }

    /// Convenience: desired dose in mcg.
    func calculate(peptideAmountMg: Double, waterVolumeMl: Double, desiredDoseMcg: Double) -> Result? {
        calculate(peptideAmountMg: peptideAmountMg, waterVolumeMl: waterVolumeMl, desiredDoseMg: desiredDoseMcg / 1000.0)
    }
}

// MARK: - Presets

struct PeptidePreset: Identifiable {
    let id = UUID()
    let name: String
    let commonVialSizeMg: Double
    let suggestedWaterMl: Double
    let typicalDoseMcg: Double

    static let allPresets: [PeptidePreset] = [
        PeptidePreset(name: "BPC-157", commonVialSizeMg: 5, suggestedWaterMl: 2, typicalDoseMcg: 250),
        PeptidePreset(name: "Semaglutide", commonVialSizeMg: 5, suggestedWaterMl: 2.5, typicalDoseMcg: 250),
        PeptidePreset(name: "Tirzepatide", commonVialSizeMg: 10, suggestedWaterMl: 2, typicalDoseMcg: 2500),
        PeptidePreset(name: "TB-500", commonVialSizeMg: 5, suggestedWaterMl: 2, typicalDoseMcg: 2500),
        PeptidePreset(name: "GHK-Cu", commonVialSizeMg: 50, suggestedWaterMl: 5, typicalDoseMcg: 200),
        PeptidePreset(name: "CJC-1295", commonVialSizeMg: 2, suggestedWaterMl: 2, typicalDoseMcg: 100),
        PeptidePreset(name: "Ipamorelin", commonVialSizeMg: 5, suggestedWaterMl: 2.5, typicalDoseMcg: 200),
    ]
}
