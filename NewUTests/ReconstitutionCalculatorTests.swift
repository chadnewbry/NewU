import XCTest
@testable import NewU

final class ReconstitutionCalculatorTests: XCTestCase {
    let calculator = ReconstitutionCalculator()

    // MARK: - Basic Calculations

    func testBasicReconstitution() {
        // 5mg peptide in 2mL water, want 250mcg dose
        let result = calculator.calculate(peptideAmountMg: 5, waterVolumeMl: 2, desiredDoseMcg: 250)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.concentrationMgPerMl, 2.5, accuracy: 1e-10) // 5mg / 2mL
        XCTAssertEqual(result!.volumeMl, 0.1, accuracy: 1e-10)            // 0.25mg / 2.5mg/mL
        XCTAssertEqual(result!.syringeUnits, 10, accuracy: 1e-10)         // 0.1mL * 100
    }

    func testReconstitutionMgDose() {
        // 10mg in 2mL, want 2.5mg
        let result = calculator.calculate(peptideAmountMg: 10, waterVolumeMl: 2, desiredDoseMg: 2.5)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.concentrationMgPerMl, 5.0, accuracy: 1e-10)
        XCTAssertEqual(result!.volumeMl, 0.5, accuracy: 1e-10)
        XCTAssertEqual(result!.syringeUnits, 50, accuracy: 1e-10)
    }

    // MARK: - Edge Cases

    func testZeroPeptideAmount() {
        let result = calculator.calculate(peptideAmountMg: 0, waterVolumeMl: 2, desiredDoseMg: 1)
        XCTAssertNil(result)
    }

    func testZeroWaterVolume() {
        let result = calculator.calculate(peptideAmountMg: 5, waterVolumeMl: 0, desiredDoseMg: 1)
        XCTAssertNil(result)
    }

    func testZeroDose() {
        let result = calculator.calculate(peptideAmountMg: 5, waterVolumeMl: 2, desiredDoseMg: 0)
        XCTAssertNil(result)
    }

    func testNegativeInputs() {
        let result = calculator.calculate(peptideAmountMg: -5, waterVolumeMl: 2, desiredDoseMg: 1)
        XCTAssertNil(result)
    }

    // MARK: - Presets

    func testPresetsExist() {
        XCTAssertFalse(PeptidePreset.allPresets.isEmpty)
        let names = PeptidePreset.allPresets.map(\.name)
        XCTAssertTrue(names.contains("BPC-157"))
        XCTAssertTrue(names.contains("Semaglutide"))
        XCTAssertTrue(names.contains("Tirzepatide"))
    }

    func testPresetCalculation() {
        // Use BPC-157 preset values
        let bpc = PeptidePreset.allPresets.first { $0.name == "BPC-157" }!
        let result = calculator.calculate(
            peptideAmountMg: bpc.commonVialSizeMg,
            waterVolumeMl: bpc.suggestedWaterMl,
            desiredDoseMcg: bpc.typicalDoseMcg
        )
        XCTAssertNotNil(result)
        // 5mg / 2mL = 2.5 mg/mL concentration
        XCTAssertEqual(result!.concentrationMgPerMl, 2.5, accuracy: 1e-10)
        // 250mcg = 0.25mg, 0.25 / 2.5 = 0.1mL
        XCTAssertEqual(result!.volumeMl, 0.1, accuracy: 1e-10)
        XCTAssertEqual(result!.syringeUnits, 10, accuracy: 1e-10)
    }
}
