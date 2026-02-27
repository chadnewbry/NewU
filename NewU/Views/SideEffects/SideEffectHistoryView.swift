import SwiftUI
import SwiftData
import Charts

struct SideEffectHistoryView: View {
    @Query(sort: \SideEffect.date, order: .reverse) private var sideEffects: [SideEffect]
    @Query(sort: \Injection.date, order: .reverse) private var injections: [Injection]

    @State private var selectedFilter: SideEffectType? = nil
    @State private var timePeriod: TimePeriod = .month

    enum TimePeriod: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case threeMonths = "90D"
        case all = "All"

        var days: Int? {
            switch self {
            case .week: 7
            case .month: 30
            case .threeMonths: 90
            case .all: nil
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                timePeriodPicker
                timelineChart
                filterSection
                sideEffectList
            }
            .padding(.vertical)
        }
        .navigationTitle("History")
    }

    // MARK: - Time Period

    private var timePeriodPicker: some View {
        Picker("Period", selection: $timePeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Timeline Chart

    private var timelineChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timeline")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(filteredInjections, id: \.id) { injection in
                    PointMark(
                        x: .value("Date", injection.date),
                        y: .value("Type", "Injections")
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(60)
                    .annotation(position: .top, spacing: 2) {
                        Text("\(injection.dosageMg, specifier: "%.1f")mg")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(filteredSideEffects, id: \.id) { effect in
                    PointMark(
                        x: .value("Date", effect.date),
                        y: .value("Type", "Side Effects")
                    )
                    .foregroundStyle(intensityColor(effect.intensity))
                    .symbolSize(CGFloat(effect.intensity) * 20)
                }
            }
            .chartYAxis {
                AxisMarks(values: ["Injections", "Side Effects"]) { _ in
                    AxisValueLabel()
                }
            }
            .frame(height: 140)
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Filter

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ChipButton(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(uniqueTypes, id: \.self) { type in
                    ChipButton(title: type.displayName, isSelected: selectedFilter == type) {
                        selectedFilter = selectedFilter == type ? nil : type
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - List

    private var sideEffectList: some View {
        LazyVStack(spacing: 12) {
            if filteredSideEffects.isEmpty {
                ContentUnavailableView(
                    "No Side Effects",
                    systemImage: "heart.text.clipboard",
                    description: Text("No side effects logged for this period.")
                )
            } else {
                ForEach(filteredSideEffects, id: \.id) { effect in
                    SideEffectRow(effect: effect)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var startDate: Date? {
        guard let days = timePeriod.days else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: .now)
    }

    private var filteredSideEffects: [SideEffect] {
        sideEffects.filter { effect in
            if let start = startDate, effect.date < start { return false }
            if let filter = selectedFilter, effect.type != filter { return false }
            return true
        }
    }

    private var filteredInjections: [Injection] {
        injections.filter { injection in
            if let start = startDate, injection.date < start { return false }
            return true
        }
    }

    private var uniqueTypes: [SideEffectType] {
        Array(Set(sideEffects.map(\.type))).sorted { $0.displayName < $1.displayName }
    }
}

// MARK: - Row

struct SideEffectRow: View {
    let effect: SideEffect

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(effect.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                IntensityBadge(intensity: effect.intensity)
            }

            HStack {
                Text(effect.date, style: .date)
                Text(effect.date, style: .time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let notes = effect.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let injection = effect.relatedInjection {
                Label {
                    HStack(spacing: 4) {
                        if let med = injection.medication {
                            Text(med.name)
                        }
                        Text("\(injection.dosageMg, specifier: "%.1f")mg")
                    }
                } icon: {
                    Image(systemName: "syringe")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct IntensityBadge: View {
    let intensity: Int

    var body: some View {
        Text("\(intensity)/5")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(intensityColor(intensity).opacity(0.2))
            .foregroundStyle(intensityColor(intensity))
            .clipShape(Capsule())
    }
}

func intensityColor(_ intensity: Int) -> Color {
    switch intensity {
    case 1: .green
    case 2: .yellow
    case 3: .orange
    case 4: .red
    case 5: .purple
    default: .orange
    }
}

#Preview {
    NavigationStack {
        SideEffectHistoryView()
    }
    .modelContainer(for: [SideEffect.self, Injection.self], inMemory: true)
}
