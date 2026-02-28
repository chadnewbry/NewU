import SwiftUI
import SwiftData

struct LogWeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthKit = HealthKitManager()
    @Query(sort: \WeightEntry.date, order: .reverse) private var recentEntries: [WeightEntry]

    @State private var weightLbs: Double = 180.0
    @State private var date: Date = .now
    @State private var isImporting = false
    @State private var importError: String?
    @State private var didSetInitial = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Large weight display
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", weightLbs))
                        .font(.system(size: 88, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.2), value: weightLbs)
                    Text("lbs")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                // Stepper controls
                HStack(spacing: 20) {
                    Button {
                        weightLbs = max(0, (weightLbs - 1.0 * 10).rounded() / 10)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "minus.square.fill")
                                .font(.system(size: 40))
                            Text("1 lb")
                                .font(.caption2)
                        }
                        .foregroundStyle(.blue.opacity(0.8))
                    }

                    Button {
                        weightLbs = max(0, (weightLbs * 10 - 1).rounded() / 10)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 52))
                            Text("0.1 lb")
                                .font(.caption2)
                        }
                        .foregroundStyle(.blue)
                    }

                    Button {
                        weightLbs = (weightLbs * 10 + 1).rounded() / 10
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 52))
                            Text("0.1 lb")
                                .font(.caption2)
                        }
                        .foregroundStyle(.green)
                    }

                    Button {
                        weightLbs = ((weightLbs + 1.0) * 10).rounded() / 10
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "plus.square.fill")
                                .font(.system(size: 40))
                            Text("1 lb")
                                .font(.caption2)
                        }
                        .foregroundStyle(.green.opacity(0.8))
                    }
                }

                // Date picker
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                // Apple Health import
                if healthKit.isAvailable {
                    Button {
                        importFromHealthKit()
                    } label: {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "heart.fill")
                                Text("Import from Apple Health")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .disabled(isImporting)
                }

                if let error = importError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if !didSetInitial, let last = recentEntries.first {
                    weightLbs = last.weightLbs
                    didSetInitial = true
                }
            }
        }
    }

    private func save() {
        let entry = WeightEntry(date: date, weightLbs: weightLbs, source: .manual)
        modelContext.insert(entry)
        Task {
            try? await healthKit.saveWeight(weightLbs, date: date)
        }
        dismiss()
    }

    private func importFromHealthKit() {
        isImporting = true
        importError = nil

        Task {
            do {
                try await healthKit.requestAuthorization()
                let endDate = Date.now
                let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate

                let existingEntries = (try? modelContext.fetch(FetchDescriptor<WeightEntry>())) ?? []
                let manualDates = Set(existingEntries.filter { $0.source == .manual }.map { $0.date })
                let calendar = Calendar.current
                let existingDays = Set(existingEntries.map { calendar.startOfDay(for: $0.date) })

                let hkEntries = try await healthKit.fetchWeightEntries(
                    from: startDate,
                    to: endDate,
                    existingManualDates: manualDates
                )

                for entry in hkEntries {
                    let entryDay = calendar.startOfDay(for: entry.date)
                    if !existingDays.contains(entryDay) {
                        let newEntry = WeightEntry(date: entry.date, weightLbs: entry.weightLbs, source: .healthKit)
                        modelContext.insert(newEntry)
                    }
                }

                isImporting = false
                dismiss()
            } catch {
                importError = "Failed to import: \(error.localizedDescription)"
                isImporting = false
            }
        }
    }
}

#Preview {
    LogWeightView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
