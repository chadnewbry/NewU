import SwiftUI

struct CalculatorView: View {
    @State private var selectedSegment: CalculatorSegment = .reconstitution

    enum CalculatorSegment: String, CaseIterable {
        case reconstitution = "Calculator"
        case levels = "Levels"
    }

    @State private var selectedPreset: PeptidePreset?
    @State private var peptideAmountText: String = "5"
    @State private var waterVolumeText: String = "2"
    @State private var desiredDoseText: String = "250"
    @State private var doseUnitIsMcg: Bool = true

    private let calculator = ReconstitutionCalculator()

    // MARK: - Computed

    private var peptideAmountMg: Double {
        Double(peptideAmountText) ?? 0
    }

    private var waterVolumeMl: Double {
        Double(waterVolumeText) ?? 0
    }

    private var desiredDoseValue: Double {
        Double(desiredDoseText) ?? 0
    }

    private var desiredDoseMg: Double {
        doseUnitIsMcg ? desiredDoseValue / 1000.0 : desiredDoseValue
    }

    private var result: ReconstitutionCalculator.Result? {
        calculator.calculate(peptideAmountMg: peptideAmountMg, waterVolumeMl: waterVolumeMl, desiredDoseMg: desiredDoseMg)
    }

    private var concentrationMgPerMl: Double {
        result?.concentrationMgPerMl ?? 0
    }

    private var volumeToDrawMl: Double {
        result?.volumeMl ?? 0
    }

    private var syringeUnits: Double {
        result?.syringeUnits ?? 0
    }

    private var dosesPerVial: Int {
        guard desiredDoseMg > 0 else { return 0 }
        return Int(peptideAmountMg / desiredDoseMg)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedSegment) {
                    ForEach(CalculatorSegment.allCases, id: \.self) { seg in
                        Text(seg.rawValue).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch selectedSegment {
                case .reconstitution:
                    reconstitutionView
                case .levels:
                    MedicationLevelView(preset: selectedPreset)
                }
            }
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Reconstitution View

    private var reconstitutionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                presetSection
                peptideAmountSection
                waterVolumeSection
                desiredDoseSection
                resultsCard

                SyringeView(fillFraction: min(volumeToDrawMl, 1.0), units: syringeUnits)
                    .frame(height: 200)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Preset Section

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Peptide")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PeptidePreset.allPresets) { preset in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectPreset(preset)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: preset.icon)
                                    .font(.caption)
                                Text(preset.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedPreset?.name == preset.name
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(.systemGray6)
                            )
                            .foregroundStyle(
                                selectedPreset?.name == preset.name
                                    ? Color.accentColor
                                    : .primary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        selectedPreset?.name == preset.name
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Input Sections

    private var peptideAmountSection: some View {
        inputSection(title: "Peptide Amount", unit: "mg") {
            VStack(spacing: 8) {
                presetButtons(values: [5, 10, 15, 20, 30], selected: peptideAmountMg, suffix: "mg") { val in
                    peptideAmountText = formatNumber(val)
                    selectedPreset = nil
                }
                customTextField(text: $peptideAmountText, placeholder: "Custom mg")
            }
        }
    }

    private var waterVolumeSection: some View {
        inputSection(title: "Bacteriostatic Water", unit: "mL") {
            VStack(spacing: 8) {
                presetButtons(values: [1, 2, 3, 5], selected: waterVolumeMl, suffix: "mL") { val in
                    waterVolumeText = formatNumber(val)
                    selectedPreset = nil
                }
                customTextField(text: $waterVolumeText, placeholder: "Custom mL")
            }
        }
    }

    private var desiredDoseSection: some View {
        inputSection(title: "Desired Dose", unit: doseUnitIsMcg ? "mcg" : "mg") {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    doseUnitToggle
                    Spacer()
                }
                if let preset = selectedPreset {
                    dosePresetsForPeptide(preset)
                }
                customTextField(text: $desiredDoseText, placeholder: "Custom \(doseUnitIsMcg ? "mcg" : "mg")")
            }
        }
    }

    private var doseUnitToggle: some View {
        HStack(spacing: 0) {
            Button {
                if !doseUnitIsMcg {
                    if let val = Double(desiredDoseText) {
                        desiredDoseText = formatNumber(val * 1000)
                    }
                    doseUnitIsMcg = true
                }
            } label: {
                Text("mcg")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(doseUnitIsMcg ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(doseUnitIsMcg ? .white : .secondary)
            }

            Button {
                if doseUnitIsMcg {
                    if let val = Double(desiredDoseText) {
                        desiredDoseText = formatNumber(val / 1000)
                    }
                    doseUnitIsMcg = false
                }
            } label: {
                Text("mg")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(!doseUnitIsMcg ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(!doseUnitIsMcg ? .white : .secondary)
            }
        }
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func dosePresetsForPeptide(_ preset: PeptidePreset) -> some View {
        let doses: [Double] = {
            switch preset.name {
            case "Semaglutide": return [250, 500, 1000, 1700, 2400]
            case "Tirzepatide": return [2500, 5000, 7500, 10000, 12500, 15000]
            case "BPC-157": return [250, 500, 750]
            case "TB-500": return [2000, 2500, 5000]
            case "PT-141": return [500, 1000, 1750]
            case "Ipamorelin": return [100, 200, 300]
            case "CJC-1295": return [100, 200, 300]
            case "GHK-Cu": return [100, 200, 500]
            default: return []
            }
        }()

        if !doses.isEmpty {
            presetButtons(values: doses, selected: doseUnitIsMcg ? desiredDoseValue : desiredDoseValue * 1000, suffix: "mcg") { val in
                if doseUnitIsMcg {
                    desiredDoseText = formatNumber(val)
                } else {
                    desiredDoseText = formatNumber(val / 1000)
                }
            }
        }
    }

    // MARK: - Results Card

    private var resultsCard: some View {
        VStack(spacing: 16) {
            Text("Results")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 14) {
                resultRow(icon: "eyedropper.halffull", iconColor: .blue, label: "Concentration",
                          value: "\(formatResult(concentrationMgPerMl)) mg/mL")

                Divider()

                resultRow(icon: "syringe.fill", iconColor: .green, label: "Volume to Draw",
                          value: "\(formatResult(volumeToDrawMl, decimals: 3)) mL", isHighlighted: true)

                Divider()

                resultRow(icon: "gauge.with.needle.fill", iconColor: .orange, label: "Syringe Units",
                          value: "\(formatResult(syringeUnits, decimals: 1)) units")

                Divider()

                resultRow(icon: "rectangle.stack.fill", iconColor: .purple, label: "Doses per Vial",
                          value: "\(dosesPerVial)")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }

    private func resultRow(icon: String, iconColor: Color, label: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(isHighlighted ? .title3 : .body)
                .fontWeight(.bold)
                .foregroundStyle(isHighlighted ? .green : .primary)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Reusable Components

    private func inputSection<Content: View>(title: String, unit: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)

            content()
        }
    }

    private func presetButtons(values: [Double], selected: Double, suffix: String, action: @escaping (Double) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { val in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            action(val)
                        }
                    } label: {
                        Text("\(formatNumber(val))\(suffix)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                abs(selected - val) < 0.001
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(.systemGray6)
                            )
                            .foregroundStyle(
                                abs(selected - val) < 0.001
                                    ? Color.accentColor
                                    : .primary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func customTextField(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
    }

    // MARK: - Helpers

    private func selectPreset(_ preset: PeptidePreset) {
        selectedPreset = preset
        peptideAmountText = formatNumber(preset.commonVialSizeMg)
        waterVolumeText = formatNumber(preset.suggestedWaterMl)
        doseUnitIsMcg = true
        desiredDoseText = formatNumber(preset.typicalDoseMcg)
    }

    private func formatNumber(_ value: Double) -> String {
        if value == value.rounded() && value < 100000 {
            return String(format: "%.0f", value)
        }
        return String(format: "%g", value)
    }

    private func formatResult(_ value: Double, decimals: Int = 2) -> String {
        String(format: "%.\(decimals)f", value)
    }
}

#Preview {
    CalculatorView()
}
