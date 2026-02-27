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
            Text(injection.medication.isEmpty ? "Untitled" : injection.medication)
                .font(.headline)
            HStack {
                Text("\(injection.dosage, specifier: "%.2f") \(injection.unit)")
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

    @State private var medication = ""
    @State private var dosage: Double = 0
    @State private var unit = "mg"
    @State private var site = ""
    @State private var notes = ""
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name", text: $medication)
                    HStack {
                        TextField("Dosage", value: $dosage, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $unit) {
                            Text("mg").tag("mg")
                            Text("mcg").tag("mcg")
                            Text("units").tag("units")
                            Text("mL").tag("mL")
                        }
                    }
                }
                Section("Details") {
                    TextField("Injection Site", text: $site)
                    DatePicker("Date", selection: $date)
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
                        let injection = Injection(date: date, medication: medication, dosage: dosage, unit: unit, site: site, notes: notes)
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
        .modelContainer(for: Injection.self, inMemory: true)
}
