import Foundation

/// A read-only value type representing a workout from HealthKit.
struct WorkoutSummary: Identifiable {
    let id: UUID
    let activityType: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalEnergyBurned: Double?
    let totalDistance: Double?

    init(
        id: UUID = UUID(),
        activityType: String,
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        totalEnergyBurned: Double? = nil,
        totalDistance: Double? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
    }
}
