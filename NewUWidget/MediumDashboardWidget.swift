import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct MediumWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetEntryData
}

// MARK: - Provider

struct MediumWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MediumWidgetEntry {
        MediumWidgetEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MediumWidgetEntry) -> Void) {
        let entry = MediumWidgetEntry(date: .now, data: .fromSharedDefaults())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MediumWidgetEntry>) -> Void) {
        let data = WidgetEntryData.fromSharedDefaults()
        let entry = MediumWidgetEntry(date: .now, data: data)

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Nutrition Ring (lightweight, no dependencies)

private struct WidgetNutritionRing: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(current))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - View

struct MediumDashboardWidgetView: View {
    let entry: MediumWidgetEntry

    private var weightProgress: Double {
        let start = entry.data.currentWeightLbs
        let goal = entry.data.goalWeightLbs
        guard start > goal, start > 0 else { return 0 }
        return 0 // widgets can't read weight history, just show current
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.15, blue: 0.35), Color(red: 0.15, green: 0.05, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 0) {
                // Left column: shot countdown + medication level
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "syringe.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("NewU")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next shot")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))

                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(entry.data.nextInjectionDays)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(entry.data.nextInjectionDays == 1 ? "day" : "days")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    // Medication name pill
                    if !entry.data.medicationName.isEmpty {
                        Text(entry.data.medicationName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.1), in: Capsule())
                    }

                    Spacer()

                    // Med level bar
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Level")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                            Spacer()
                            Text("\(Int(entry.data.medicationLevelPct * 100))%")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.purple)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * entry.data.medicationLevelPct, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding(.leading, 14)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // Right column: nutrition rings + weight
                VStack(spacing: 8) {
                    Text("Today")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.6))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        WidgetNutritionRing(
                            label: "Protein",
                            current: entry.data.todayProteinG,
                            goal: entry.data.proteinGoalG,
                            unit: "g",
                            color: .blue
                        )
                        WidgetNutritionRing(
                            label: "Fiber",
                            current: entry.data.todayFiberG,
                            goal: entry.data.fiberGoalG,
                            unit: "g",
                            color: .green
                        )
                        WidgetNutritionRing(
                            label: "Water",
                            current: entry.data.todayWaterOz,
                            goal: entry.data.waterGoalOz,
                            unit: "oz",
                            color: .cyan
                        )
                        WidgetNutritionRing(
                            label: "Cal",
                            current: Double(entry.data.todayCalories),
                            goal: Double(entry.data.calorieGoal),
                            unit: "",
                            color: .orange
                        )
                    }

                    // Weight
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.indigo.opacity(0.8))
                        Text(String(format: "%.1f lbs", entry.data.currentWeightLbs))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.08), in: Capsule())
                }
                .padding(.trailing, 14)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Widget

struct MediumDashboardWidget: Widget {
    let kind: String = "MediumDashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MediumWidgetProvider()) { entry in
            MediumDashboardWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.15, blue: 0.35), Color(red: 0.15, green: 0.05, blue: 0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Dashboard")
        .description("Next injection countdown, nutrition rings, and current weight.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    MediumDashboardWidget()
} timeline: {
    MediumWidgetEntry(date: .now, data: .placeholder)
}
