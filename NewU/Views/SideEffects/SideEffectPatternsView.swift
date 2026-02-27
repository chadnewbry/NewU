import SwiftUI
import SwiftData
import Charts

struct SideEffectPatternsView: View {
    @Query(sort: \SideEffect.date) private var sideEffects: [SideEffect]
    @Query(sort: \Injection.date) private var injections: [Injection]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if sideEffects.isEmpty {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.bar",
                        description: Text("Log side effects to see patterns and insights.")
                    )
                } else {
                    mostCommonChart
                    intensityOverTimeChart
                    dayRelativeToInjectionChart
                    dosageCorrelationSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Patterns")
    }

    // MARK: - Most Common

    private var mostCommonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Most Common", systemImage: "chart.bar")
                .font(.headline)

            let data = typeCounts.prefix(8)
            Chart(Array(data), id: \.type) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Type", item.type.displayName)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: CGFloat(min(data.count, 8)) * 36)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Intensity Over Time

    private var intensityOverTimeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Intensity Over Time", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)

            if weeklyIntensities.count >= 2 {
                Chart(weeklyIntensities, id: \.weekStart) { item in
                    LineMark(
                        x: .value("Week", item.weekStart),
                        y: .value("Avg Intensity", item.avgIntensity)
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Week", item.weekStart),
                        y: .value("Avg Intensity", item.avgIntensity)
                    )
                    .foregroundStyle(.orange.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(SideEffect.intensityLabels[v] ?? "\(v)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)

                trendInsight
            } else {
                Text("Need at least 2 weeks of data to show trends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var trendInsight: some View {
        if let first = weeklyIntensities.first, let last = weeklyIntensities.last {
            let diff = last.avgIntensity - first.avgIntensity
            HStack(spacing: 4) {
                Image(systemName: diff < -0.2 ? "arrow.down.circle.fill" : diff > 0.2 ? "arrow.up.circle.fill" : "equal.circle.fill")
                    .foregroundStyle(diff < -0.2 ? .green : diff > 0.2 ? .red : .secondary)
                Text(diff < -0.2 ? "Side effects are improving" : diff > 0.2 ? "Side effects are getting worse" : "Side effects are stable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Day Relative to Injection

    private var dayRelativeToInjectionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Days After Injection", systemImage: "calendar.badge.clock")
                .font(.headline)

            let data = dayRelativeCounts
            if !data.isEmpty {
                Chart(data, id: \.day) { item in
                    BarMark(
                        x: .value("Day", "Day \(item.day)"),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 160)

                if let peak = data.max(by: { $0.count < $1.count }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("Side effects are most common on day \(peak.day) after injection")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("Link side effects to injections to see timing patterns.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Dosage Correlation

    private var dosageCorrelationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dosage Correlation", systemImage: "arrow.up.arrow.down")
                .font(.headline)

            let groups = dosageGroups
            if groups.count >= 2 {
                Chart(groups, id: \.dosageLabel) { group in
                    BarMark(
                        x: .value("Dosage", group.dosageLabel),
                        y: .value("Avg Intensity", group.avgIntensity)
                    )
                    .foregroundStyle(Color.purple.gradient)
                }
                .chartYScale(domain: 0...5)
                .frame(height: 160)

                if let low = groups.min(by: { $0.avgIntensity < $1.avgIntensity }),
                   let high = groups.max(by: { $0.avgIntensity < $1.avgIntensity }),
                   low.dosageLabel != high.dosageLabel {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                        Text("Side effects were stronger at \(high.dosageLabel) (avg \(high.avgIntensity, specifier: "%.1f")/5) vs \(low.dosageLabel) (avg \(low.avgIntensity, specifier: "%.1f")/5)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("Log side effects at different dosages to see correlations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Data

    private var typeCounts: [(type: SideEffectType, count: Int)] {
        var counts: [SideEffectType: Int] = [:]
        for effect in sideEffects {
            counts[effect.type, default: 0] += 1
        }
        return counts.map { ($0.key, $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var weeklyIntensities: [(weekStart: Date, avgIntensity: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sideEffects) { effect in
            calendar.dateInterval(of: .weekOfYear, for: effect.date)?.start ?? effect.date
        }
        return grouped.map { (weekStart, effects) in
            let avg = Double(effects.map(\.intensity).reduce(0, +)) / Double(effects.count)
            return (weekStart: weekStart, avgIntensity: avg)
        }
        .sorted { $0.weekStart < $1.weekStart }
    }

    private var dayRelativeCounts: [(day: Int, count: Int)] {
        var counts: [Int: Int] = [:]
        for effect in sideEffects {
            guard let injection = effect.relatedInjection else { continue }
            let days = Calendar.current.dateComponents([.day], from: injection.date, to: effect.date).day ?? 0
            if days >= 0 && days <= 7 {
                counts[days, default: 0] += 1
            }
        }
        return counts.map { ($0.key, $0.value) }.sorted { $0.day < $1.day }
    }

    private var dosageGroups: [(dosageLabel: String, avgIntensity: Double)] {
        var groups: [String: [Int]] = [:]
        for effect in sideEffects {
            guard let injection = effect.relatedInjection else { continue }
            let label = String(format: "%.1fmg", injection.dosageMg)
            groups[label, default: []].append(effect.intensity)
        }
        return groups.map { (label, intensities) in
            let avg = Double(intensities.reduce(0, +)) / Double(intensities.count)
            return (dosageLabel: label, avgIntensity: avg)
        }
        .sorted { $0.dosageLabel < $1.dosageLabel }
    }
}

#Preview {
    NavigationStack {
        SideEffectPatternsView()
    }
    .modelContainer(for: [SideEffect.self, Injection.self], inMemory: true)
}
