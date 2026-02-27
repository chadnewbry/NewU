import SwiftUI
import SwiftData

struct MedicationSelectionStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]

    @Binding var selectedMedication: Medication?
    @Binding var customMedicationName: String
    @Binding var customHalfLife: String
    let onContinue: () -> Void

    @State private var selectedOption: MedicationOption?

    private enum MedicationOption: Hashable {
        case semaglutide
        case tirzepatide
        case compoundSemaglutide
        case compoundTirzepatide
        case other
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("What medication are\nyou taking?")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("Select your current medication")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    medicationCard(
                        option: .semaglutide,
                        title: "Semaglutide",
                        brands: "Ozempic, Wegovy",
                        icon: "pill.fill"
                    )

                    medicationCard(
                        option: .tirzepatide,
                        title: "Tirzepatide",
                        brands: "Mounjaro, Zepbound",
                        icon: "pill.fill"
                    )

                    medicationCard(
                        option: .compoundSemaglutide,
                        title: "Compound\nSemaglutide",
                        brands: "Compounded",
                        icon: "cross.vial.fill"
                    )

                    medicationCard(
                        option: .compoundTirzepatide,
                        title: "Compound\nTirzepatide",
                        brands: "Compounded",
                        icon: "cross.vial.fill"
                    )
                }
                .padding(.horizontal, 24)

                medicationCard(
                    option: .other,
                    title: "Other Peptide",
                    brands: "Custom medication",
                    icon: "ellipsis.circle.fill"
                )
                .padding(.horizontal, 24)

                if selectedOption == .other {
                    VStack(spacing: 12) {
                        TextField("Medication name", text: $customMedicationName)
                            .textFieldStyle(.roundedBorder)

                        TextField("Half-life (hours)", text: $customHalfLife)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
            .disabled(selectedOption == nil || (selectedOption == .other && customMedicationName.isEmpty))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
            .background(.ultraThinMaterial)
        }
    }

    private func medicationCard(option: MedicationOption, title: String, brands: String, icon: String) -> some View {
        let isSelected = selectedOption == option

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedOption = option
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.accentColor)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(brands)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.04), radius: isSelected ? 8 : 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func selectAndContinue() {
        switch selectedOption {
        case .semaglutide:
            selectedMedication = medications.first { $0.type == .semaglutide && !$0.isCompound }
            if selectedMedication == nil {
                let med = Medication.semaglutideDefault()
                modelContext.insert(med)
                selectedMedication = med
            }

        case .tirzepatide:
            selectedMedication = medications.first { $0.type == .tirzepatide && !$0.isCompound }
            if selectedMedication == nil {
                let med = Medication.tirzepatideDefault()
                modelContext.insert(med)
                selectedMedication = med
            }

        case .compoundSemaglutide:
            let med = Medication(
                name: "Compound Semaglutide",
                brandName: "Compounded",
                type: .semaglutide,
                halfLifeHours: 168,
                defaultDosages: [],
                isCompound: true
            )
            modelContext.insert(med)
            selectedMedication = med

        case .compoundTirzepatide:
            let med = Medication(
                name: "Compound Tirzepatide",
                brandName: "Compounded",
                type: .tirzepatide,
                halfLifeHours: 120,
                defaultDosages: [],
                isCompound: true
            )
            modelContext.insert(med)
            selectedMedication = med

        case .other:
            let halfLife = Double(customHalfLife) ?? 168
            let med = Medication(
                name: customMedicationName,
                type: .custom,
                halfLifeHours: halfLife,
                defaultDosages: [],
                isCompound: false
            )
            modelContext.insert(med)
            selectedMedication = med

        case nil:
            return
        }

        onContinue()
    }
}
