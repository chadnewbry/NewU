import SwiftUI
import SwiftData
import Charts

struct NutritionDashboardView: View {
    @Query(sort: \NutritionEntry.date, order: .reverse) private var entries: [NutritionEntry]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    private var todayEntries: [NutritionEntry] {
        let today = Calendar.current.startOfDay(for: .now)
        return entries.filter { Calendar.current.startOfDay(for: $0.date) == today }
    }

    private var todayProtein: Double { todayEntries.reduce(0) { $0 + $1.proteinGrams } }
    private var todayFiber: Double { todayEntries.reduce(0) { $0 + $1.fiberGrams } }
    private var todayCalories: Int { todayEntries.reduce(0) { $0 + $1.calories } }
    private var todayWater: Double { todayEntries.reduce(0) { $0 + $1.waterOz } }

    private var streak: Int {
        let calendar = Calendar.current
        var count = 0
        var date = calendar.startOfDay(for: .now)
        while true {
            let hasEntry = entries.contains { calendar.startOfDay(for: $0.date) == date }
            guard hasEntry else { break }
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }

    private var weeklyProtein: [DayNutrition] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset -> DayNutrition? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dayEntries = entries.filter { calendar.startOfDay(for: $0.date) == date }
            let protein = dayEntries.reduce(0.0) { $0 + $1.proteinGrams }
            return DayNutrition(date: date, value: protein)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Nutrition", systemImage: "fork.knife")
                    .font(.headline)
                Spacer()
                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(streak)d streak")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Activity rings — today's progress
            HStack(spacing: 16) {
                ProgressRingView(
                    label: "Protein",
                    value: todayProtein,
                    goal: profile?.dailyProteinGoalGrams ?? 100,
                    unit: "g",
                    color: .blue
                )
                ProgressRingView(
                    label: "Fiber",
                    value: todayFiber,
                    goal: profile?.dailyFiberGoalGrams ?? 28,
                    unit: "g",
                    color: .green
                )
                ProgressRingView(
                    label: "Calories",
                    value: Double(todayCalories),
                    goal: Double(profile?.dailyCalorieGoal ?? 2000),
                    unit: "kcal",
                    color: .orange
                )
                ProgressRingView(
                    label: "Water",
                    value: todayWater,
                    goal: profile?.dailyWaterGoalOz ?? 64,
                    unit: "oz",
                    color: .cyan
                )
            }

            // Weekly protein bar chart
            if !weeklyProtein.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Protein — Last 7 Days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Chart(weeklyProtein) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Protein (g)", day.value)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(4)

                        if let goal = profile?.dailyProteinGoalGrams {
                            RuleMark(y: .value("Goal", goal))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                .foregroundStyle(.blue.opacity(0.45))
                        }
                    }
                    .frame(height: 110)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 3)) { value in
                            AxisValueLabel()
                            AxisGridLine()
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Supporting Types

private struct DayNutrition: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct ProgressRingView: View {
    let label: String
    let value: Double
    let goal: Double
    let unit: String
    let color: Color

    private var progress: Double {
        min(value / max(goal, 1), 1.0)
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.18), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                Text(shortValue)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 62, height: 62)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var shortValue: String {
        if value >= 1000 {
            return String(format: "%.0fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}

#Preview {
    NutritionDashboardView()
        .modelContainer(for: [NutritionEntry.self, UserProfile.self], inMemory: true)
        .padding()
        .background(Color(.systemGroupedBackground))
}
