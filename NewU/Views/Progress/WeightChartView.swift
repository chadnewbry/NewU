import SwiftUI
import SwiftData
import Charts

struct WeightChartView: View {
    @Query(sort: \WeightEntry.date) private var allEntries: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @State private var selectedPeriod: ChartPeriod = .oneMonth

    enum ChartPeriod: String, CaseIterable {
        case oneWeek = "1W"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case all = "All"

        var days: Int? {
            switch self {
            case .oneWeek: return 7
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .all: return nil
            }
        }
    }

    private var profile: UserProfile? { profiles.first }

    private var filteredEntries: [WeightEntry] {
        guard let days = selectedPeriod.days else { return allEntries }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return allEntries.filter { $0.date >= cutoff }
    }

    private var totalLost: Double? {
        guard let first = filteredEntries.first?.weightLbs,
              let last = filteredEntries.last?.weightLbs,
              filteredEntries.count >= 2 else { return nil }
        return first - last
    }

    private var avgWeeklyLoss: Double? {
        guard filteredEntries.count >= 2,
              let first = filteredEntries.first,
              let last = filteredEntries.last else { return nil }
        let days = last.date.timeIntervalSince(first.date) / 86400
        guard days > 6 else { return nil }
        return (first.weightLbs - last.weightLbs) / (days / 7)
    }

    private var bmi: Double? {
        guard let profile = profile,
              let weightLbs = filteredEntries.last?.weightLbs,
              profile.heightInches > 0 else { return nil }
        let heightM = profile.heightInches * 0.0254
        return weightLbs * 0.453592 / (heightM * heightM)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Weight", systemImage: "scalemass.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            Picker("Period", selection: $selectedPeriod) {
                ForEach(ChartPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    "No Weight Data",
                    systemImage: "scalemass",
                    description: Text("Log your weight to see trends.")
                )
                .frame(height: 180)
            } else {
                Chart {
                    ForEach(filteredEntries) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weightLbs)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weightLbs)
                        )
                        .foregroundStyle(entry.source == .healthKit ? Color.pink : Color.blue)
                        .symbolSize(30)
                    }

                    if let goal = profile?.goalWeightLbs {
                        RuleMark(y: .value("Goal", goal))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundStyle(.green)
                            .annotation(position: .top, alignment: .leading) {
                                Text("Goal \(goal, specifier: "%.0f") lbs")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 4)
                            }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))

                // Stats row
                HStack(spacing: 10) {
                    if let lost = totalLost {
                        WeightStatChip(
                            title: "Total",
                            value: String(format: "%+.1f lbs", -lost),
                            color: lost > 0 ? .green : .red
                        )
                    }
                    if let avg = avgWeeklyLoss {
                        WeightStatChip(
                            title: "Per week",
                            value: String(format: "%+.1f lbs", -avg),
                            color: avg > 0 ? .green : .red
                        )
                    }
                    if let bmi = bmi {
                        WeightStatChip(
                            title: "BMI",
                            value: String(format: "%.1f", bmi),
                            color: bmiColor(bmi)
                        )
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func bmiColor(_ bmi: Double) -> Color {
        switch bmi {
        case ..<18.5: return .blue
        case 18.5..<25: return .green
        case 25..<30: return .orange
        default: return .red
        }
    }
}

struct WeightStatChip: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    WeightChartView()
        .modelContainer(for: [WeightEntry.self, UserProfile.self], inMemory: true)
        .padding()
}
