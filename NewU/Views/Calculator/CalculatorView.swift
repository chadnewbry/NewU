import SwiftUI

struct CalculatorView: View {
    @State private var peptideAmount: Double = 5
    @State private var peptideUnit = "mg"
    @State private var waterVolume: Double = 2
    @State private var desiredDose: Double = 250
    @State private var desiredDoseUnit = "mcg"

    var concentrationPerML: Double {
        guard waterVolume > 0 else { return 0 }
        let peptideMcg = peptideUnit == "mg" ? peptideAmount * 1000 : peptideAmount
        return peptideMcg / waterVolume
    }

    var volumeToInject: Double {
        guard concentrationPerML > 0 else { return 0 }
        let doseMcg = desiredDoseUnit == "mg" ? desiredDose * 1000 : desiredDose
        return doseMcg / concentrationPerML
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Peptide Vial") {
                    HStack {
                        TextField("Amount", value: $peptideAmount, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $peptideUnit) {
                            Text("mg").tag("mg")
                            Text("mcg").tag("mcg")
                        }
                    }
                }

                Section("Bacteriostatic Water") {
                    HStack {
                        TextField("Volume", value: $waterVolume, format: .number)
                            .keyboardType(.decimalPad)
                        Text("mL")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Desired Dose") {
                    HStack {
                        TextField("Dose", value: $desiredDose, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $desiredDoseUnit) {
                            Text("mcg").tag("mcg")
                            Text("mg").tag("mg")
                        }
                    }
                }

                Section("Result") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "eyedropper.halffull")
                                .foregroundStyle(.blue)
                            Text("Concentration")
                            Spacer()
                            Text("\(concentrationPerML, specifier: "%.1f") mcg/mL")
                                .fontWeight(.semibold)
                        }
                        Divider()
                        HStack {
                            Image(systemName: "syringe.fill")
                                .foregroundStyle(.green)
                            Text("Inject")
                            Spacer()
                            Text("\(volumeToInject, specifier: "%.3f") mL")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Calculator")
        }
    }
}

#Preview {
    CalculatorView()
}
