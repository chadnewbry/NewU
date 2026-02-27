import SwiftUI
import SwiftData

struct LogSideEffectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Injection.date, order: .reverse) private var injections: [Injection]

    @State private var selectedTypes: Set<SideEffectType> = []
    @State private var customName = ""
    @State private var intensity: Double = 3
    @State private var date = Date.now
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sideEffectChips
                    customSection
                    intensitySection
                    dateSection
                    notesSection
                    linkedInjectionInfo
                }
                .padding()
            }
            .navigationTitle("Log Side Effect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(selectedTypes.isEmpty)
                }
            }
        }
    }

    // MARK: - Subviews

    private var sideEffectChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you experiencing?")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(SideEffectType.commonTypes, id: \.self) { type in
                    ChipButton(
                        title: type.displayName,
                        isSelected: selectedTypes.contains(type)
                    ) {
                        toggleType(type)
                    }
                }
            }
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ChipButton(
                title: "Other",
                isSelected: selectedTypes.contains(.custom)
            ) {
                toggleType(.custom)
            }

            if selectedTypes.contains(.custom) {
                TextField("Describe...", text: $customName)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intensity")
                .font(.headline)

            VStack(spacing: 4) {
                Slider(value: $intensity, in: 1...5, step: 1)
                    .tint(intensityColor(Int(intensity)))

                HStack {
                    Text("Mild")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(SideEffect.intensityLabels[Int(intensity)] ?? "")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(intensityColor(Int(intensity)))
                    Spacer()
                    Text("Severe")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When")
                .font(.headline)
            DatePicker("Date & Time", selection: $date)
                .labelsHidden()
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            TextField("Any additional details...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    @ViewBuilder
    private var linkedInjectionInfo: some View {
        if let injection = mostRecentInjection {
            VStack(alignment: .leading, spacing: 4) {
                Label("Will be linked to most recent injection", systemImage: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    if let med = injection.medication {
                        Text(med.name)
                    }
                    Text("\(injection.dosageMg, specifier: "%.2f") mg")
                    Text("—")
                    Text(injection.date, style: .date)
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private var mostRecentInjection: Injection? {
        injections.first { $0.date <= date }
    }

    private func toggleType(_ type: SideEffectType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }

    private func save() {
        let injection = mostRecentInjection
        for type in selectedTypes {
            let effect = SideEffect(
                date: date,
                type: type,
                customName: type == .custom ? customName : nil,
                intensity: Int(intensity),
                notes: notes.isEmpty ? nil : notes,
                relatedInjection: injection
            )
            modelContext.insert(effect)
        }
        dismiss()
    }
}

// MARK: - Chip Button

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(in: proposal.width ?? 0, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

#Preview {
    LogSideEffectView()
        .modelContainer(for: [SideEffect.self, Injection.self], inMemory: true)
}
