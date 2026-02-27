import SwiftUI
import SwiftData

struct TrackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Injection.date, order: .reverse) private var injections: [Injection]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if injections.isEmpty {
                    ContentUnavailableView(
                        "No Injections Logged",
                        systemImage: "syringe",
                        description: Text("Tap + to log your first injection.")
                    )
                } else {
                    List {
                        ForEach(injections) { injection in
                            InjectionRow(injection: injection)
                        }
                        .onDelete(perform: deleteInjections)
                    }
                }
            }
            .navigationTitle("Track")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddInjectionView()
            }
        }
    }

    private func deleteInjections(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(injections[index])
        }
    }
}

struct InjectionRow: View {
    let injection: Injection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(injection.medication?.name ?? "Unknown Medication")
                .font(.headline)
            HStack {
                Text("\(injection.dosageMg, specifier: "%.2f") mg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("• \(injection.injectionSite.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(injection.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddInjectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var medications: [Medication]

    @State private var selectedMedication: Medication?
    @State private var dosageMg: Double = 0
    @State private var dosageUnits: String = ""
    @State private var injectionSite: InjectionSite = .leftAbdomen
    @State private var painLevel: Int = 1
    @State private var notes = ""
    @State private var date = Date.now
    @State private var prepChecklistCompleted = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    Picker("Medication", selection: $selectedMedication) {
                        Text("Select...").tag(nil as Medication?)
                        ForEach(medications) { med in
                            Text(med.brandName ?? med.name).tag(med as Medication?)
                        }
                    }
                    TextField("Dosage (mg)", value: $dosageMg, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Units (optional)", text: $dosageUnits)
                        .keyboardType(.numberPad)
                }
                Section("Details") {
                    Picker("Injection Site", selection: $injectionSite) {
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            Text(site.displayName).tag(site)
                        }
                    }
                    Picker("Pain Level", selection: $painLevel) {
                        ForEach(1...5, id: \.self) { level in
                            Text("\(level)").tag(level)
                        }
                    }
                    DatePicker("Date", selection: $date)
                    Toggle("Prep Checklist Completed", isOn: $prepChecklistCompleted)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Injection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let injection = Injection(
                            date: date,
                            time: date,
                            medication: selectedMedication,
                            dosageMg: dosageMg,
                            dosageUnits: Int(dosageUnits),
                            injectionSite: injectionSite,
                            painLevel: painLevel,
                            notes: notes.isEmpty ? nil : notes,
                            prepChecklistCompleted: prepChecklistCompleted
                        )
                        modelContext.insert(injection)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TrackView()
        .modelContainer(for: [Injection.self, Medication.self], inMemory: true)
}
