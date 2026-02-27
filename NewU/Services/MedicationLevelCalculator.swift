import Foundation

/// One-compartment pharmacokinetic model for estimating medication blood levels over time.
/// Concentration after a single injection: C(t) = Dose * e^(-ke * t)
/// where ke = ln(2) / half_life and Vd is normalized to 1.
struct MedicationLevelCalculator {

    // MARK: - Single Point Calculations

    /// Calculate the current estimated medication level from all injections.
    func calculateCurrentLevel(injections: [Injection]) -> Double {
        calculateLevelAt(date: .now, injections: injections)
    }

    /// Calculate the estimated medication level at a specific date.
    func calculateLevelAt(date: Date, injections: [Injection]) -> Double {
        injections.reduce(0.0) { total, injection in
            total + contributionOf(injection: injection, at: date)
        }
    }

    // MARK: - Curve Generation

    /// Generate a level curve for charting. Returns an array of (date, level) tuples.
    func generateLevelCurve(
        injections: [Injection],
        from startDate: Date,
        to endDate: Date,
        resolution: TimeInterval? = nil
    ) -> [(date: Date, level: Double)] {
        let interval = endDate.timeIntervalSince(startDate)
        let step = resolution ?? Self.defaultResolution(for: interval)

        guard step > 0, interval > 0 else { return [] }

        var results: [(date: Date, level: Double)] = []
        var current = startDate
        while current <= endDate {
            let level = calculateLevelAt(date: current, injections: injections)
            results.append((current, level))
            current = current.addingTimeInterval(step)
        }
        return results
    }

    // MARK: - Trough Estimation

    /// Estimate the next trough (minimum level before next expected dose).
    /// Assumes the most recent injection interval will repeat.
    func estimateNextTrough(injections: [Injection]) -> (date: Date, level: Double)? {
        let sorted = injections
            .filter { $0.medication != nil }
            .sorted { $0.date < $1.date }

        guard let last = sorted.last else { return nil }

        // Infer interval from last two injections, or use half-life * 1 as default
        let intervalSeconds: TimeInterval
        if sorted.count >= 2 {
            let prev = sorted[sorted.count - 2]
            intervalSeconds = last.date.timeIntervalSince(prev.date)
        } else {
            // Default: assume weekly dosing
            intervalSeconds = (last.medication?.halfLifeHours ?? 168) * 3600
        }

        let troughDate = last.date.addingTimeInterval(intervalSeconds)
        let troughLevel = calculateLevelAt(date: troughDate, injections: injections)
        return (troughDate, troughLevel)
    }

    // MARK: - Steady State

    /// Estimate the trough level at steady state for a repeated dosing regimen.
    /// Uses geometric series: C_trough_ss = Dose * e^(-ke * tau) / (1 - e^(-ke * tau))
    func estimateSteadyStateLevel(dosage: Double, intervalDays: Int, halfLifeHours: Double) -> Double {
        guard halfLifeHours > 0, intervalDays > 0 else { return 0 }
        let ke = log(2) / halfLifeHours
        let tau = Double(intervalDays) * 24.0 // convert days to hours
        let decay = exp(-ke * tau)
        guard decay < 1 else { return 0 }
        return dosage * decay / (1 - decay)
    }

    // MARK: - Private Helpers

    /// Contribution of a single injection at a given date.
    private func contributionOf(injection: Injection, at date: Date) -> Double {
        guard let medication = injection.medication else { return 0 }
        let hoursElapsed = date.timeIntervalSince(injection.date) / 3600.0
        guard hoursElapsed >= 0 else { return 0 } // injection is in the future
        let ke = log(2) / medication.halfLifeHours
        return injection.dosageMg * exp(-ke * hoursElapsed)
    }

    /// Default time resolution based on the span of the curve.
    static func defaultResolution(for interval: TimeInterval) -> TimeInterval {
        let hours = interval / 3600
        if hours <= 168 { // week
            return 3600 // 1 hour
        } else if hours <= 744 { // ~month
            return 3600 * 6 // 6 hours
        } else {
            return 3600 * 24 // 1 day
        }
    }
}
