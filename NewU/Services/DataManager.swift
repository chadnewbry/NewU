import Foundation
import SwiftData
import SwiftUI

@MainActor
final class DataManager: ObservableObject {
    static let shared = DataManager()

    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    private init() {
        let schema = Schema([
            Medication.self,
            Injection.self,
            WeightEntry.self,
            NutritionEntry.self,
            SideEffect.self,
            DailyNote.self,
            UserProfile.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Generic CRUD

    func insert<T: PersistentModel>(_ model: T) {
        context.insert(model)
        save()
    }

    func delete<T: PersistentModel>(_ model: T) {
        context.delete(model)
        save()
    }

    func save() {
        do {
            try context.save()
        } catch {
            print("DataManager save error: \(error)")
        }
    }

    // MARK: - Fetch Helpers

    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - User Profile

    func getUserProfile() -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = fetch(descriptor).first {
            return profile
        }
        let profile = UserProfile()
        insert(profile)
        return profile
    }

    // MARK: - Medications

    func getAllMedications() -> [Medication] {
        fetch(FetchDescriptor<Medication>(sortBy: [SortDescriptor(\.name)]))
    }

    func seedDefaultMedications() {
        let existing = getAllMedications()
        guard existing.isEmpty else { return }

        let semaglutide = Medication(
            name: "Semaglutide",
            brandName: "Ozempic",
            type: .semaglutide,
            halfLifeHours: 168,
            defaultDosages: [0.25, 0.5, 1.0, 1.7, 2.4]
        )
        let tirzepatide = Medication(
            name: "Tirzepatide",
            brandName: "Mounjaro",
            type: .tirzepatide,
            halfLifeHours: 120,
            defaultDosages: [2.5, 5.0, 7.5, 10.0, 12.5, 15.0]
        )
        insert(semaglutide)
        insert(tirzepatide)
    }

    // MARK: - Injections

    func getInjections(from startDate: Date, to endDate: Date) -> [Injection] {
        let descriptor = FetchDescriptor<Injection>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return fetch(descriptor)
    }

    func getLastInjection() -> Injection? {
        var descriptor = FetchDescriptor<Injection>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return fetch(descriptor).first
    }

    // MARK: - Weight

    func getWeightHistory(limit: Int? = nil) -> [WeightEntry] {
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit { descriptor.fetchLimit = limit }
        return fetch(descriptor)
    }

    func getLatestWeight() -> WeightEntry? {
        getWeightHistory(limit: 1).first
    }

    // MARK: - Nutrition

    func getTodayNutrition() -> NutritionEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        return fetch(descriptor).first
    }

    func getOrCreateTodayNutrition() -> NutritionEntry {
        if let existing = getTodayNutrition() {
            return existing
        }
        let entry = NutritionEntry(date: Calendar.current.startOfDay(for: Date()))
        insert(entry)
        return entry
    }

    // MARK: - Side Effects

    func getSideEffects(from startDate: Date, to endDate: Date) -> [SideEffect] {
        let descriptor = FetchDescriptor<SideEffect>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return fetch(descriptor)
    }

    // MARK: - Daily Notes

    func getDailyNote(for date: Date) -> DailyNote? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<DailyNote>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        return fetch(descriptor).first
    }

    // MARK: - Computed Properties

    func currentBMI() -> Double? {
        let profile = getUserProfile()
        guard profile.heightInches > 0,
              let weight = getLatestWeight() else { return nil }
        return (weight.weightLbs * 703) / (profile.heightInches * profile.heightInches)
    }

    func totalWeightLost() -> Double? {
        let profile = getUserProfile()
        guard profile.startWeightLbs > 0,
              let current = getLatestWeight() else { return nil }
        return profile.startWeightLbs - current.weightLbs
    }

    func averageWeeklyLoss() -> Double? {
        let profile = getUserProfile()
        guard profile.startWeightLbs > 0,
              let current = getLatestWeight() else { return nil }
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: profile.startDate, to: Date()).weekOfYear ?? 1)
        return (profile.startWeightLbs - current.weightLbs) / Double(weeks)
    }
}
