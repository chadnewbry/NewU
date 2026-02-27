import XCTest
@testable import NewU

final class MedicationLevelCalculatorTests: XCTestCase {
    let calculator = MedicationLevelCalculator()

    // MARK: - Helper

    private func makeInjection(
        date: Date,
        dosageMg: Double,
        halfLifeHours: Double = 168 // semaglutide default
    ) -> Injection {
        let med = Medication(
            name: "Test",
            type: .semaglutide,
            halfLifeHours: halfLifeHours
        )
        return Injection(
            date: date,
            time: date,
            medication: med,
            dosageMg: dosageMg
        )
    }

    // MARK: - No Injections

    func testNoInjections() {
        let level = calculator.calculateCurrentLevel(injections: [])
        XCTAssertEqual(level, 0)
    }

    // MARK: - Single Injection Decay

    func testSingleInjectionAtTimeZero() {
        let now = Date()
        let inj = makeInjection(date: now, dosageMg: 1.0)
        let level = calculator.calculateLevelAt(date: now, injections: [inj])
        XCTAssertEqual(level, 1.0, accuracy: 1e-10)
    }

    func testSingleInjectionHalfLife() {
        // After exactly one half-life, level should be 50%
        let start = Date(timeIntervalSince1970: 0)
        let halfLifeHours = 168.0
        let inj = makeInjection(date: start, dosageMg: 10.0, halfLifeHours: halfLifeHours)
        let later = start.addingTimeInterval(halfLifeHours * 3600)
        let level = calculator.calculateLevelAt(date: later, injections: [inj])
        XCTAssertEqual(level, 5.0, accuracy: 1e-10)
    }

    func testSingleInjectionTwoHalfLives() {
        let start = Date(timeIntervalSince1970: 0)
        let halfLifeHours = 120.0 // tirzepatide
        let inj = makeInjection(date: start, dosageMg: 8.0, halfLifeHours: halfLifeHours)
        let later = start.addingTimeInterval(halfLifeHours * 2 * 3600)
        let level = calculator.calculateLevelAt(date: later, injections: [inj])
        XCTAssertEqual(level, 2.0, accuracy: 1e-10)
    }

    // MARK: - Stacked Injections

    func testStackedInjections() {
        let start = Date(timeIntervalSince1970: 0)
        let halfLifeHours = 168.0
        let inj1 = makeInjection(date: start, dosageMg: 10.0, halfLifeHours: halfLifeHours)
        // Second injection at one half-life later
        let secondDate = start.addingTimeInterval(halfLifeHours * 3600)
        let inj2 = makeInjection(date: secondDate, dosageMg: 10.0, halfLifeHours: halfLifeHours)
        // At second injection time: first contributes 5.0, second contributes 10.0
        let level = calculator.calculateLevelAt(date: secondDate, injections: [inj1, inj2])
        XCTAssertEqual(level, 15.0, accuracy: 1e-10)
    }

    // MARK: - Future Injection Ignored

    func testFutureInjectionIgnored() {
        let now = Date()
        let future = now.addingTimeInterval(3600 * 24)
        let inj = makeInjection(date: future, dosageMg: 10.0)
        let level = calculator.calculateLevelAt(date: now, injections: [inj])
        XCTAssertEqual(level, 0)
    }

    // MARK: - Nil Medication

    func testInjectionWithNoMedication() {
        let inj = Injection(date: .now, time: .now, medication: nil, dosageMg: 5.0)
        let level = calculator.calculateLevelAt(date: .now, injections: [inj])
        XCTAssertEqual(level, 0)
    }

    // MARK: - Curve Generation

    func testGenerateLevelCurve() {
        let start = Date(timeIntervalSince1970: 0)
        let inj = makeInjection(date: start, dosageMg: 10.0)
        let end = start.addingTimeInterval(3600 * 24) // 24 hours
        let curve = calculator.generateLevelCurve(
            injections: [inj],
            from: start,
            to: end,
            resolution: 3600 * 12 // every 12 hours
        )
        XCTAssertEqual(curve.count, 3) // 0h, 12h, 24h
        XCTAssertEqual(curve[0].level, 10.0, accuracy: 1e-10)
        XCTAssertTrue(curve[1].level < 10.0)
        XCTAssertTrue(curve[2].level < curve[1].level)
    }

    func testCurveDefaultResolutionWeek() {
        let res = MedicationLevelCalculator.defaultResolution(for: 3600 * 168)
        XCTAssertEqual(res, 3600) // 1 hour
    }

    func testCurveDefaultResolutionMonth() {
        let res = MedicationLevelCalculator.defaultResolution(for: 3600 * 720)
        XCTAssertEqual(res, 3600 * 6) // 6 hours
    }

    func testCurveDefaultResolutionLong() {
        let res = MedicationLevelCalculator.defaultResolution(for: 3600 * 2000)
        XCTAssertEqual(res, 3600 * 24) // 1 day
    }

    // MARK: - Trough Estimation

    func testEstimateNextTroughSingleInjection() {
        let start = Date(timeIntervalSince1970: 0)
        let inj = makeInjection(date: start, dosageMg: 10.0, halfLifeHours: 168)
        let result = calculator.estimateNextTrough(injections: [inj])
        XCTAssertNotNil(result)
        // Default interval = halfLife for single injection, so trough at 168h
        let expectedDate = start.addingTimeInterval(168 * 3600)
        XCTAssertEqual(result!.date, expectedDate)
        XCTAssertEqual(result!.level, 5.0, accuracy: 1e-10)
    }

    func testEstimateNextTroughNoInjections() {
        let result = calculator.estimateNextTrough(injections: [])
        XCTAssertNil(result)
    }

    // MARK: - Steady State

    func testSteadyStateLevel() {
        // Weekly dosing of 1mg semaglutide (168h half-life)
        // At steady state trough: Dose * e^(-ke*tau) / (1 - e^(-ke*tau))
        // ke = ln(2)/168, tau = 168h → decay = 0.5
        // SS trough = 1.0 * 0.5 / (1 - 0.5) = 1.0
        let ss = calculator.estimateSteadyStateLevel(dosage: 1.0, intervalDays: 7, halfLifeHours: 168)
        XCTAssertEqual(ss, 1.0, accuracy: 1e-10)
    }

    func testSteadyStateLevelZeroHalfLife() {
        let ss = calculator.estimateSteadyStateLevel(dosage: 1.0, intervalDays: 7, halfLifeHours: 0)
        XCTAssertEqual(ss, 0)
    }

    func testSteadyStateLevelZeroInterval() {
        let ss = calculator.estimateSteadyStateLevel(dosage: 1.0, intervalDays: 0, halfLifeHours: 168)
        XCTAssertEqual(ss, 0)
    }

    // MARK: - Very Old Injection

    func testVeryOldInjection() {
        let start = Date(timeIntervalSince1970: 0)
        let inj = makeInjection(date: start, dosageMg: 10.0, halfLifeHours: 168)
        // 100 half-lives later — essentially zero
        let later = start.addingTimeInterval(168 * 100 * 3600)
        let level = calculator.calculateLevelAt(date: later, injections: [inj])
        XCTAssertEqual(level, 0, accuracy: 1e-20)
    }
}
