import SwiftUI
import SwiftData

struct InjectionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Injection.date, order: .reverse) private var injections: [Injection]
    @Query private var medications: [Medication]

    @State private var searchDate = ""
    @State private var selectedMedFilter: String?
    @State private var editingInjection: Injection?

    private let painEmojis = ["😊", "🙂", "😐", "😣", "😖"]

    private var filteredInjections: [Injection] {
        var result = injections
        if let filter = selectedMedFilter {
            result = result.filter { $0.medication?.name == filter }
        }
        if !searchDate.isEmpty {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            result = result.filter {
                formatter.string(from: $0.date).localizedCaseInsensitiveContains(searchDate)
            }
        }
        return result
    }

    private var uniqueMedications: [String] {
        Array(Set(injections.compactMap { $0.medication?.name })).sorted()
    }

    var body: some View {
        List {
            // Filters
            Section {
                TextField("Search by date…", text: $searchDate)
                    .textFieldStyle(.plain)

                if !uniqueMedications.isEmpty {
                    Picker("Medication", selection: $selectedMedFilter) {
                        Text("All").tag(nil as String?)
                        ForEach(uniqueMedications, id: \.self) { med in
                            Text(med).tag(med as String?)
                        }
                    }
                }
            }

            // Results
            if filteredInjections.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Injections",
                        systemImage: "syringe",
                        description: Text("No matching injections found.")
                    )
                }
            } else {
                Section("\(filteredInjections.count) injection\(filteredInjections.count == 1 ? "" : "s")") {
                    ForEach(filteredInjections) { injection in
                        InjectionHistoryRow(injection: injection, painEmojis: painEmojis)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(injection)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingInjection = injection
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .sheet(item: $editingInjection) { injection in
            EditInjectionView(injection: injection)
        }
    }
}

struct InjectionHistoryRow: View {
    let injection: Injection
    let painEmojis: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(injection.medication?.name ?? "Unknown")
                    .font(.headline)
                Spacer()
                Text(injection.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 12) {
                Label("\(injection.dosageMg, specifier: "%.2g") mg", systemImage: "syringe")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label(injection.injectionSite.displayName, systemImage: "mappin")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                let idx = max(0, min(injection.painLevel - 1, 4))
                Text(painEmojis[idx])
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EditInjectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var injection: Injection

    @State private var painLevel: Int = 1
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    Text(injection.medication?.name ?? "Unknown")
                    HStack {
                        TextField("Dosage (mg)", value: $injection.dosageMg, format: .number)
                            .keyboardType(.decimalPad)
                        Text("mg")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Details") {
                    DatePicker("Date", selection: $injection.date)
                    Picker("Site", selection: $injection.injectionSite) {
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            Text(site.displayName).tag(site)
                        }
                    }
                    PainLevelPicker(level: $painLevel)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Injection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        injection.painLevel = painLevel
                        injection.notes = notes.isEmpty ? nil : notes
                        dismiss()
                    }
                }
            }
            .onAppear {
                painLevel = injection.painLevel
                notes = injection.notes ?? ""
            }
        }
    }
}

struct PainLevelPicker: View {
    @Binding var level: Int

    private let emojis = ["😊", "🙂", "😐", "😣", "😖"]

    var body: some View {
        VStack(spacing: 8) {
            Text(emojis[max(0, min(level - 1, 4))])
                .font(.system(size: 40))

            HStack {
                Text("1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: Binding(
                    get: { Double(level) },
                    set: { level = Int($0) }
                ), in: 1...5, step: 1)
                Text("5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Level \(level) of 5")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
