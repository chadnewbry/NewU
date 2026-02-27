import SwiftUI

struct BodyStatsStepView: View {
    @Binding var heightFeet: Int
    @Binding var heightInches: Int
    @Binding var startWeightLbs: String
    @Binding var goalWeightLbs: String
    let onContinue: () -> Void

    @State private var useMetric = false

    private var heightCm: Int {
        Int(round(Double(heightFeet * 12 + heightInches) * 2.54))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Tell us about you")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("This helps calculate your targets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Unit toggle
                Picker("Units", selection: $useMetric) {
                    Text("Imperial").tag(false)
                    Text("Metric").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                // Height
                VStack(spacing: 12) {
                    Label("Height", systemImage: "ruler")
                        .font(.headline)

                    if useMetric {
                        HStack(spacing: 8) {
                            Picker("cm", selection: Binding(
                                get: { heightCm },
                                set: { cm in
                                    let totalInches = Double(cm) / 2.54
                                    heightFeet = Int(totalInches) / 12
                                    heightInches = Int(totalInches) % 12
                                }
                            )) {
                                ForEach(120...220, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                    } else {
                        HStack(spacing: 16) {
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(3...7, id: \.self) { ft in
                                    Text("\(ft) ft").tag(ft)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 120)

                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inches in
                                    Text("\(inches) in").tag(inches)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 120)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Current Weight
                VStack(spacing: 12) {
                    Label("Current Weight", systemImage: "scalemass")
                        .font(.headline)

                    HStack(spacing: 8) {
                        TextField("0", text: $startWeightLbs)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                            .frame(width: 140)

                        Text(useMetric ? "kg" : "lbs")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)

                // Goal Weight
                VStack(spacing: 12) {
                    Label("Goal Weight", systemImage: "target")
                        .font(.headline)

                    HStack(spacing: 8) {
                        TextField("Optional", text: $goalWeightLbs)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                            .frame(width: 140)

                        Text(useMetric ? "kg" : "lbs")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Text("You can set this later")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 80)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(startWeightLbs.isEmpty || Double(startWeightLbs) == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
            .background(.ultraThinMaterial)
        }
    }
}
