import Foundation
import HealthKit
import SwiftData
import os

/// Manages all HealthKit interactions for NewU.
///
/// - Reads: weight, steps, workouts, dietary data
/// - Writes: weight, nutrition
/// - Background delivery for weight changes
@MainActor
final class HealthKitManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isAuthorized = false
    @Published private(set) var isAvailable: Bool

    // MARK: - Private

    private let healthStore: HKHealthStore?
    private let logger = Logger(subsystem: "com.newu.glp-calculator", category: "HealthKit")

    private var readTypes: Set<HKObjectType> {
        let types: [HKObjectType?] = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass),
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber),
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKQuantityType.quantityType(forIdentifier: .dietaryWater),
            HKQuantityType.quantityType(forIdentifier: .stepCount),
            HKObjectType.workoutType(),
        ]
        return Set(types.compactMap { $0 })
    }

    private var writeTypes: Set<HKSampleType> {
        let types: [HKSampleType?] = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass),
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber),
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKQuantityType.quantityType(forIdentifier: .dietaryWater),
        ]
        return Set(types.compactMap { $0 })
    }

    // MARK: - Init

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            self.isAvailable = true
        } else {
            self.healthStore = nil
            self.isAvailable = false
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard let store = healthStore else {
            logger.warning("HealthKit not available on this device")
            return
        }

        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
        logger.info("HealthKit authorization granted")
    }

    // MARK: - Weight (Read)

    /// Fetch weight entries from HealthKit, de-duplicating against existing manual entries.
    /// Returns only entries that don't already exist in the provided manual entries (by date proximity).
    func fetchWeightEntries(
        from startDate: Date,
        to endDate: Date,
        existingManualDates: Set<Date> = []
    ) async throws -> [(weightLbs: Double, date: Date)] {
        guard let store = healthStore,
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (results as? [HKQuantitySample]) ?? [])
            }
            store.execute(query)
        }

        let calendar = Calendar.current

        return samples.compactMap { sample in
            let weightLbs = sample.quantity.doubleValue(for: .pound())
            let date = sample.startDate

            // De-duplicate: skip if there's a manual entry on the same day
            let sampleDay = calendar.startOfDay(for: date)
            let isDuplicate = existingManualDates.contains { manualDate in
                calendar.startOfDay(for: manualDate) == sampleDay
            }

            return isDuplicate ? nil : (weightLbs: weightLbs, date: date)
        }
    }

    // MARK: - Weight (Write)

    func saveWeight(_ weightLbs: Double, date: Date) async throws {
        guard let store = healthStore,
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }

        let quantity = HKQuantity(unit: .pound(), doubleValue: weightLbs)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)
        try await store.save(sample)
        logger.info("Saved weight \(weightLbs) lbs to HealthKit")
    }

    // MARK: - Steps

    func fetchSteps(for date: Date) async throws -> Int {
        guard let store = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }

    // MARK: - Workouts

    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [WorkoutSummary] {
        guard let store = healthStore else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                    WorkoutSummary(
                        activityType: workout.workoutActivityType.displayName,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter())
                    )
                }
                continuation.resume(returning: workouts)
            }
            store.execute(query)
        }
    }

    // MARK: - Nutrition (Write)

    func saveNutrition(
        proteinGrams: Double? = nil,
        fiberGrams: Double? = nil,
        calories: Double? = nil,
        waterOz: Double? = nil,
        date: Date
    ) async throws {
        guard let store = healthStore else { return }

        var samples: [HKQuantitySample] = []

        if let proteinGrams, let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let qty = HKQuantity(unit: .gram(), doubleValue: proteinGrams)
            samples.append(HKQuantitySample(type: type, quantity: qty, start: date, end: date))
        }
        if let fiberGrams, let type = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
            let qty = HKQuantity(unit: .gram(), doubleValue: fiberGrams)
            samples.append(HKQuantitySample(type: type, quantity: qty, start: date, end: date))
        }
        if let calories, let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let qty = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            samples.append(HKQuantitySample(type: type, quantity: qty, start: date, end: date))
        }
        if let waterOz, let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            // Convert oz to liters for HealthKit
            let waterLiters = waterOz * 0.0295735
            let qty = HKQuantity(unit: .liter(), doubleValue: waterLiters)
            samples.append(HKQuantitySample(type: type, quantity: qty, start: date, end: date))
        }

        guard !samples.isEmpty else { return }
        try await store.save(samples)
        logger.info("Saved \(samples.count) nutrition samples to HealthKit")
    }

    // MARK: - Background Delivery

    /// Enable background delivery for weight changes.
    /// Call once during app launch.
    func enableBackgroundWeightDelivery(handler: @escaping @Sendable () -> Void) {
        guard let store = healthStore,
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }

        store.enableBackgroundDelivery(for: weightType, frequency: .immediate) { success, error in
            if let error {
                self.logger.error("Failed to enable background delivery: \(error.localizedDescription)")
            } else if success {
                self.logger.info("Background delivery enabled for weight")
            }
        }

        let query = HKObserverQuery(sampleType: weightType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                handler()
            }
            completionHandler()
        }
        store.execute(query)
    }
}

// MARK: - HKWorkoutActivityType Extension

private extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength Training"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .highIntensityIntervalTraining: return "HIIT"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        default: return "Workout"
        }
    }
}
