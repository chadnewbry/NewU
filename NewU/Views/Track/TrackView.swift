import SwiftUI
import SwiftData

struct TrackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Injection.date, order: .reverse) private var injections: [Injection]
    @State private var showingAddSheet = false
    @State private var showPaywall = false
    @State private var selectedSegment = 0

    private enum Segment: Int { case log = 0, history = 1, calculator = 2 }

    private var canLog: Bool {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return true }
        return profile.hasPurchasedFullAccess || profile.freeUsesRemaining > 0
    }

    private var freeUsesRemaining: Int? {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first,
              !profile.hasPurchasedFullAccess else { return nil }
        return profile.freeUsesRemaining
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedSegment) {
                    Text("Log").tag(0)
                    Text("History").tag(1)
                    Text("Calculator").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

                switch Segment(rawValue: selectedSegment) {
                case .log:
                    if canLog { logPromptView } else { lockedView }
                case .history:
                    InjectionHistoryView()
                case .calculator:
                    CalculatorView()
                case .none:
                    EmptyView()
                }
            }
            .navigationTitle("Track")
            .toolbar {
                if selectedSegment == Segment.log.rawValue {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            if canLog {
                                showingAddSheet = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddInjectionView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var lockedView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.15), .purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
                Text("Free Logs Used Up")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Upgrade to NewU Pro to continue logging injections and tracking your progress.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showPaywall = true
            } label: {
                Text("Unlock for $6.99")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    @ViewBuilder
    private var logPromptView: some View {
        if injections.isEmpty {
            ContentUnavailableView(
                "No Injections Logged",
                systemImage: "syringe",
                description: Text("Tap + to log your first injection.")
            )
        } else {
            List {
                Section("Recent") {
                    ForEach(injections.prefix(5)) { injection in
                        InjectionRow(injection: injection)
                    }
                    .onDelete(perform: deleteInjections)
                }
                if let usesLeft = freeUsesRemaining {
                    Section {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(.orange)
                            Text("\(usesLeft) free logs remaining")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func deleteInjections(offsets: IndexSet) {
        let recentFive = Array(injections.prefix(5))
        for index in offsets {
            modelContext.delete(recentFive[index])
        }
    }
}

// MARK: - Injection Row

struct InjectionRow: View {
    let injection: Injection
    private let painEmojis = ["😊", "🙂", "😐", "😣", "😖"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(injection.medication?.name ?? "Unknown Medication")
                    .font(.headline)
                Spacer()
                let idx = max(0, min(injection.painLevel - 1, 4))
                Text(painEmojis[idx])
            }
            HStack {
                Text("\(injection.dosageMg, specifier: "%.2g") mg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(injection.injectionSite.displayName)
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

// MARK: - Add Injection View

struct AddInjectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var medications: [Medication]
    @Query(sort: \Injection.date, order: .reverse) private var injections: [Injection]

    @State private var date = Date.now
    @State private var selectedMedication: Medication?
    @State private var dosageMg: Double = 0
    @State private var dosageUnits: Int?
    @State private var injectionSite: InjectionSite = .leftAbdomen
    @State private var painLevel: Int = 1
    @State private var notes = ""
    @State private var showingChecklist = true
    @State private var checklistCompleted = false

    private var isCompound: Bool {
        selectedMedication?.isCompound ?? false
    }

    var body: some View {
        NavigationStack {
            Form {
                // Date & Time
                Section("Date & Time") {
                    DatePicker("When", selection: $date)
                }

                // Medication
                Section("Medication") {
                    if medications.isEmpty {
                        Text("No medications configured yet.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        Picker("Medication", selection: $selectedMedication) {
                            Text("Select…").tag(nil as Medication?)
                            ForEach(medications) { med in
                                Text(med.name).tag(med as Medication?)
                            }
                        }
                    }
                }

                // Dosage
                if let med = selectedMedication {
                    Section("Dosage") {
                        if med.isCompound {
                            HStack {
                                TextField("Amount (mg)", value: $dosageMg, format: .number)
                                    .keyboardType(.decimalPad)
                                Text("mg")
                                    .foregroundStyle(.secondary)
                            }
                            // Show calculated syringe units if we have reconstitution info
                            if dosageMg > 0 {
                                HStack {
                                    Image(systemName: "syringe")
                                        .foregroundStyle(.blue)
                                    Text("See Calculator tab for syringe units")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else if !med.defaultDosages.isEmpty {
                            Picker("Dose (mg)", selection: $dosageMg) {
                                Text("Select…").tag(0.0)
                                ForEach(med.defaultDosages, id: \.self) { dose in
                                    Text("\(dose, specifier: "%.2g") mg").tag(dose)
                                }
                            }
                        } else {
                            HStack {
                                TextField("Dosage (mg)", value: $dosageMg, format: .number)
                                    .keyboardType(.decimalPad)
                                Text("mg")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Injection Site (body map)
                Section("Injection Site") {
                    BodyMapView(selectedSite: $injectionSite, injections: injections)
                }

                // Pain Level
                Section("Pain Level") {
                    PainLevelPicker(level: $painLevel)
                }

                // Notes
                Section("Notes") {
                    TextField("Optional notes…", text: $notes, axis: .vertical)
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
                    Button("Log Injection") {
                        saveInjection()
                    }
                    .disabled(selectedMedication == nil)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingChecklist) {
                PrepChecklistView(
                    isCompound: isCompound,
                    onDismiss: { showingChecklist = false },
                    onComplete: {
                        checklistCompleted = true
                        showingChecklist = false
                    }
                )
                .interactiveDismissDisabled()
            }
            .onChange(of: selectedMedication) {
                if let med = selectedMedication {
                    if !med.isCompound, let first = med.defaultDosages.first, dosageMg == 0 {
                        dosageMg = first
                    }
                }
            }
        }
    }

    private func saveInjection() {
        let injection = Injection(
            date: date,
            time: date,
            medication: selectedMedication,
            dosageMg: dosageMg,
            dosageUnits: dosageUnits,
            injectionSite: injectionSite,
            painLevel: painLevel,
            notes: notes.isEmpty ? nil : notes,
            prepChecklistCompleted: checklistCompleted
        )
        modelContext.insert(injection)

        // Decrement free uses if applicable
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(profileDescriptor).first,
           !profile.hasPurchasedFullAccess {
            profile.freeUsesRemaining = max(0, profile.freeUsesRemaining - 1)
        }

        dismiss()
    }
}

#Preview {
    TrackView()
        .modelContainer(for: [Injection.self, Medication.self, UserProfile.self], inMemory: true)
}
