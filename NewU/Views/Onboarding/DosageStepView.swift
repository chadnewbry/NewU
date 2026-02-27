import SwiftUI

struct DosageStepView: View {
    let selectedMedication: Medication?
    @Binding var currentDosageMg: Double?
    let onContinue: () -> Void

    @State private var customDosage: String = ""
    @State private var selectedPreset: Double?

    private var isCompoundOrCustom: Bool {
        guard let med = selectedMedication else { return true }
        return med.isCompound || med.type == .custom
    }

    private var presetDosages: [Double] {
        guard let med = selectedMedication, !med.defaultDosages.isEmpty else { return [] }
        return med.defaultDosages
    }

    private var lowestDose: Double? {
        presetDosages.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("What's your\ncurrent dosage?")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    if let med = selectedMedication {
                        Text(med.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 40)

                if isCompoundOrCustom {
                    freeFormEntry
                } else {
                    presetChips
                }

                Spacer(minLength: 80)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: selectAndContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!hasValidDosage)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Preset Chips

    private var presetChips: some View {
        VStack(spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPreset = lowestDose
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(selectedPreset == lowestDose && customDosage.isEmpty ? .white : Color.accentColor)
                    Text("Just starting")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedPreset == lowestDose && customDosage.isEmpty ? .white : .primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(selectedPreset == lowestDose && customDosage.isEmpty ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)

            FlowLayout(spacing: 10) {
                ForEach(presetDosages, id: \.self) { dosage in
                    dosageChip(dosage)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func dosageChip(_ dosage: Double) -> some View {
        let isSelected = selectedPreset == dosage && customDosage.isEmpty

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPreset = dosage
                customDosage = ""
            }
        } label: {
            Text(formatDosage(dosage))
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .shadow(color: .black.opacity(isSelected ? 0.1 : 0.04), radius: isSelected ? 6 : 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Free Form Entry

    private var freeFormEntry: some View {
        VStack(spacing: 12) {
            Text("Enter your dosage in milligrams")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("0.0", text: $customDosage)
                    .keyboardType(.decimalPad)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    .frame(width: 140)

                Text("mg")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private var hasValidDosage: Bool {
        if isCompoundOrCustom {
            return Double(customDosage) != nil && Double(customDosage)! > 0
        }
        return selectedPreset != nil
    }

    private func selectAndContinue() {
        if isCompoundOrCustom {
            currentDosageMg = Double(customDosage)
        } else {
            currentDosageMg = selectedPreset
        }
        onContinue()
    }

    private func formatDosage(_ value: Double) -> String {
        if value == value.rounded() && value >= 1 {
            return String(format: "%.0f mg", value)
        }
        return String(format: "%.2g mg", value)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions)
    }
}
