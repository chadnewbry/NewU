import SwiftUI
import SwiftData
import Charts

struct MedicationLevelView: View {
    let preset: PeptidePreset?

    @Query(sort: \Injection.date, order: .reverse) private var allInjections: [Injection]

    @State private var selectedPeriod: TimePeriod = .oneMonth
    @State private var selectedPoint: LevelDataPoint?

    private let calculator = MedicationLevelCalculator()

    enum TimePeriod: String, CaseIterable {
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

    struct LevelDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let level: Double
        let isProjected: Bool
    }

    private var relevantInjections: [Injection] {
        let peptideName = preset?.name ?? ""
        let filtered: [Injection]
        if peptideName.isEmpty {
            filtered = allInjections
        } else {
            filtered = allInjections.filter {
                $0.medication?.name.localizedCaseInsensitiveContains(peptideName) == true
            }
        }

        guard let days = selectedPeriod.days else { return filtered }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return filtered.filter { $0.date >= cutoff }
    }

    private var dataPoints: [LevelDataPoint] {
        let injections = relevantInjections
        guard !injections.isEmpty else { return [] }

        let sorted = injections.sorted { $0.date < $1.date }
        let earliest = sorted.first!.date
        let projectionEnd = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now

        let historicalCurve = calculator.generateLevelCurve(
            injections: injections,
            from: earliest,
            to: .now
        )

        let projectedCurve = calculator.generateLevelCurve(
            injections: injections,
            from: .now,
            to: projectionEnd
        )

        var points = historicalCurve.map {
            LevelDataPoint(date: $0.date, level: $0.level, isProjected: false)
        }
        points += projectedCurve.map {
            LevelDataPoint(date: $0.date, level: $0.level, isProjected: true)
        }

        return points
    }

    private var currentLevel: Double {
        calculator.calculateCurrentLevel(injections: relevantInjections)
    }

    private var injectionDates: Set<Date> {
        Set(relevantInjections.map { Calendar.current.startOfDay(for: $0.date) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                currentLevelCard
                periodSelector

                if dataPoints.isEmpty {
                    emptyState
                } else {
                    chartView
                }

                if let preset {
                    infoCard(preset: preset)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Current Level Card

    private var currentLevelCard: some View {
        VStack(spacing: 6) {
            Text("Current Estimated Level")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", currentLevel))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("mg")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text(preset?.name ?? "All Medications")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 4) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation { selectedPeriod = period }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color.accentColor : Color(.systemGray6))
                        .foregroundStyle(selectedPeriod == period ? .white : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        let actualPoints = dataPoints.filter { !$0.isProjected }
        let projectedPoints = dataPoints.filter { $0.isProjected }

        return Chart {
            ForEach(actualPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Level", point.level)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Level", point.level)
                )
                .foregroundStyle(.green.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }

            ForEach(projectedPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Level", point.level)
                )
                .foregroundStyle(.green.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .interpolationMethod(.catmullRom)
            }

            // Injection markers
            ForEach(relevantInjections.sorted(by: { $0.date < $1.date }), id: \.id) { injection in
                let level = calculator.calculateLevelAt(date: injection.date, injections: relevantInjections)
                PointMark(
                    x: .value("Date", injection.date),
                    y: .value("Level", level)
                )
                .foregroundStyle(.blue)
                .symbolSize(40)
            }

            if let selected = selectedPoint {
                RuleMark(x: .value("Date", selected.date))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                    .annotation(position: .top) {
                        VStack(spacing: 2) {
                            Text(String(format: "%.2f mg", selected.level))
                                .font(.caption)
                                .fontWeight(.bold)
                            Text(selected.date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let x = value.location.x - geo[plotFrame].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedPoint = dataPoints.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                }
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
        .frame(height: 280)
        .padding(.horizontal)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No injection data")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Log injections in the Track tab to see your medication levels over time.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Info Card

    private func infoCard(preset: PeptidePreset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text(preset.name)
                    .fontWeight(.semibold)
            }

            HStack {
                Label("Half-life", systemImage: "clock")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatHalfLife(preset.halfLifeHours))
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func formatHalfLife(_ hours: Double) -> String {
        if hours >= 24 {
            let days = hours / 24
            return String(format: "%.0f days", days)
        }
        return String(format: "%.0f hours", hours)
    }
}

#Preview {
    MedicationLevelView(preset: PeptidePreset.allPresets.first)
}
