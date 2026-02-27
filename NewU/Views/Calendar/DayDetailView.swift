import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let injections: [Injection]
    let weightEntries: [WeightEntry]
    let nutritionEntries: [NutritionEntry]
    let sideEffects: [SideEffect]
    let dailyNote: DailyNote?

    @State private var noteText: String = ""
    @State private var isEditingNote = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date header
                    Text(date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    // Injections
                    if !injections.isEmpty {
                        sectionCard(title: "Injections", icon: "syringe.fill", color: .blue) {
                            ForEach(injections) { injection in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(injection.medication?.name ?? "Unknown Medication")
                                        .font(.subheadline.weight(.medium))
                                    HStack(spacing: 12) {
                                        Label(String(format: "%.1f mg", injection.dosageMg), systemImage: "scalemass")
                                        Label(injection.injectionSite.displayName, systemImage: "mappin")
                                        Label("Pain: \(injection.painLevel)/5", systemImage: "hand.raised")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                if injection.id != injections.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    // Weight
                    if !weightEntries.isEmpty {
                        sectionCard(title: "Weight", icon: "scalemass.fill", color: .green) {
                            ForEach(weightEntries) { entry in
                                HStack {
                                    Text(String(format: "%.1f lbs", entry.weightLbs))
                                        .font(.title3.weight(.semibold))
                                    Spacer()
                                    Text(entry.source == .healthKit ? "HealthKit" : "Manual")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Nutrition
                    if !nutritionEntries.isEmpty {
                        sectionCard(title: "Nutrition", icon: "fork.knife", color: .orange) {
                            ForEach(nutritionEntries, id: \.id) { entry in
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    nutritionStat(label: "Calories", value: "\(entry.calories)")
                                    nutritionStat(label: "Protein", value: String(format: "%.0fg", entry.proteinGrams))
                                    nutritionStat(label: "Fiber", value: String(format: "%.0fg", entry.fiberGrams))
                                    nutritionStat(label: "Water", value: String(format: "%.0f oz", entry.waterOz))
                                }
                            }
                        }
                    }

                    // Side Effects
                    if !sideEffects.isEmpty {
                        sectionCard(title: "Side Effects", icon: "heart.text.clipboard", color: .red) {
                            ForEach(sideEffects) { effect in
                                HStack {
                                    Image(systemName: effect.type.icon)
                                        .foregroundStyle(.red)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(effect.displayName)
                                            .font(.subheadline.weight(.medium))
                                        Text("Intensity: \(SideEffect.intensityLabels[effect.intensity] ?? "Unknown")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                if effect.id != sideEffects.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    // Daily Notes
                    sectionCard(title: "Notes", icon: "note.text", color: .purple) {
                        if isEditingNote {
                            TextField("How are you feeling today?", text: $noteText, axis: .vertical)
                                .lineLimit(3...8)
                                .textFieldStyle(.plain)

                            HStack {
                                Spacer()
                                Button("Save") {
                                    saveNote()
                                    isEditingNote = false
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)
                            }
                        } else if let note = dailyNote, !note.content.isEmpty {
                            Text(note.content)
                                .font(.subheadline)

                            Button("Edit") {
                                noteText = note.content
                                isEditingNote = true
                            }
                            .font(.caption)
                        } else {
                            Button {
                                isEditingNote = true
                            } label: {
                                Label("Add a note", systemImage: "plus.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(.purple)
                            }
                        }
                    }

                    // Empty state
                    if injections.isEmpty && weightEntries.isEmpty && nutritionEntries.isEmpty && sideEffects.isEmpty && dailyNote == nil {
                        ContentUnavailableView(
                            "Nothing Logged",
                            systemImage: "calendar.badge.minus",
                            description: Text("No data recorded for this day.")
                        )
                        .padding(.top, 20)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                noteText = dailyNote?.content ?? ""
            }
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Nutrition Stat

    private func nutritionStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Save Note

    private func saveNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = dailyNote {
            existing.content = trimmed
        } else if !trimmed.isEmpty {
            let note = DailyNote(date: date, content: trimmed)
            modelContext.insert(note)
        }
    }
}

#Preview {
    DayDetailView(
        date: .now,
        injections: [],
        weightEntries: [],
        nutritionEntries: [],
        sideEffects: [],
        dailyNote: nil
    )
    .modelContainer(for: [DailyNote.self], inMemory: true)
}
