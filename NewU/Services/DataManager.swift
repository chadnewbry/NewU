import Foundation
import SwiftData
import SwiftUI

@MainActor
final class DataManager: ObservableObject {
    static let shared = DataManager()

    let modelContainer: ModelContainer
    let modelContext: ModelContext

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
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            modelContext.autosaveEnabled = true
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // For testing/previews
    init(inMemory: Bool) {
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
            isStoredInMemoryOnly: inMemory
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Generic CRUD

    func insert<T: PersistentModel>(_ model: T) {
        modelContext.insert(model)
        save()
    }

    func delete<T: PersistentModel>(_ model: T) {
        modelContext.delete(model)
        save()
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("DataManager save error: \(error)")
        }
    }

    // MARK: - Medication

    func allMedications() -> [Medication] {
        let descriptor = FetchDescriptor<Medication>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func seedDefaultMedications() {
        guard allMedications().isEmpty else { return }
        insert(Medication.semaglutideDefault())
        insert(Medication.tirzepatideDefault())
    }

    // MARK: - Injection Queries

    func getInjections(from startDate: Date, to endDate: Date) -> [Injection] {
        let descriptor = FetchDescriptor<Injection>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func allInjections() -> [Injection] {
        let descriptor = FetchDescriptor<Injection>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func lastInjection() -> Injection? {
        var descriptor = FetchDescriptor<Injection>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    // MARK: - Weight Queries

    func getWeightHistory(limit: Int? = nil) -> [WeightEntry] {
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit { descriptor.fetchLimit = limit }
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func latestWeight() -> WeightEntry? {
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    // MARK: - Nutrition Queries

    func getTodayNutrition() -> NutritionEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }

    func getOrCreateTodayNutrition() -> NutritionEntry {
        if let existing = getTodayNutrition() { return existing }
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
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Daily Notes

    func getDailyNote(for date: Date) -> DailyNote? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<DailyNote>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }

    func getOrCreateDailyNote(for date: Date) -> DailyNote {
        if let existing = getDailyNote(for: date) { return existing }
        let note = DailyNote(date: Calendar.current.startOfDay(for: date))
        insert(note)
        return note
    }

    // MARK: - User Profile

    func getUserProfile() -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? modelContext.fetch(descriptor))?.first
    }

    func getOrCreateUserProfile() -> UserProfile {
        if let existing = getUserProfile() { return existing }
        let profile = UserProfile()
        insert(profile)
        return profile
    }

    // MARK: - Computed Properties

    func currentBMI() -> Double? {
        guard let weight = latestWeight(),
              let profile = getUserProfile(),
              profile.heightInches > 0 else { return nil }
        return (weight.weightLbs * 703) / (profile.heightInches * profile.heightInches)
    }

    func totalWeightLost() -> Double? {
        guard let profile = getUserProfile(),
              let current = latestWeight() else { return nil }
        return profile.startWeightLbs - current.weightLbs
    }

    func averageWeeklyLoss() -> Double? {
        guard let profile = getUserProfile(),
              let current = latestWeight() else { return nil }
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: profile.startDate, to: Date()).weekOfYear ?? 1
        guard weeks > 0 else { return nil }
        return (profile.startWeightLbs - current.weightLbs) / Double(weeks)
    }
}
