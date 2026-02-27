import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Injection.date, order: .reverse) private var injections: [Injection]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var nutritionEntries: [NutritionEntry]
    @Query private var profiles: [UserProfile]
    @Query(sort: \SideEffect.date, order: .reverse) private var sideEffects: [SideEffect]

    @State private var showLogInjection = false
    @State private var showLogWeight = false
    @State private var showLogNutrition = false
    @State private var showLogSideEffect = false
    @State private var showQuickActions = false

    private var profile: UserProfile? { profiles.first }
    private let calculator = MedicationLevelCalculator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    shotDayBanner
                    medicationLevelCard
                    nutritionProgressCard
                    weightCard
                    recentActivityCard
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
            .navigationTitle("NewU")
            .overlay(alignment: .bottomTrailing) {
                quickActionButton
            }
        }
        .sheet(isPresented: $showLogWeight) {
            LogWeightSheet()
        }
        .sheet(isPresented: $showLogNutrition) {
            LogNutritionSheet()
        }
        .sheet(isPresented: $showLogSideEffect) {
            LogSideEffectView()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        if let profile, !profile.hasPurchasedFullAccess {
            HStack(spacing: 12) {
                Text("\(profile.freeUsesRemaining) free injections remaining")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.15), in: Capsule())
                    .foregroundStyle(.blue)

                Button {
                    // TODO: trigger paywall
                } label: {
                    Text("Upgrade")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Shot Day Banner

    @ViewBuilder
    private var shotDayBanner: some View {
        if let profile, let injectionDay = profile.injectionDayOfWeek {
            let todayWeekday = Calendar.current.component(.weekday, from: .now)
            let isToday = todayWeekday == injectionDay
            let alreadyLoggedToday = injections.first.map {
                Calendar.current.isDateInToday($0.date)
            } ?? false

            if isToday && !alreadyLoggedToday {
                Button {
                    showLogInjection = true
                } label: {
                    VStack(spacing: 8) {
                        Text("It's Shot Day! 💉")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Tap to log your injection")
                            .font(.subheadline)

                        if let dosage = profile.currentDosageMg,
                           let med = profile.selectedMedication {
                            Text("\(med.name) — \(dosage, specifier: "%.2g") mg")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                }
            } else {
                let daysUntil = daysUntilNextInjection(
                    currentWeekday: todayWeekday,
                    injectionDay: injectionDay,
                    alreadyLoggedToday: alreadyLoggedToday
                )

                CardContainer {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next shot in \(daysUntil) day\(daysUntil == 1 ? "" : "s")")
                                .font(.headline)
                            if let dosage = profile.currentDosageMg {
                                Text("\(dosage, specifier: "%.2g") mg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Medication Level

    private var medicationLevelCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(.purple)
                    Text("Medication Level")
                        .font(.headline)
                    Spacer()
                }

                let currentLevel = calculator.calculateCurrentLevel(injections: injections)
                let peakLevel = peakEstimate

                VStack(alignment: .leading, spacing: 4) {
                    if peakLevel > 0 {
                        let pct = min(currentLevel / peakLevel, 1.0)
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.purple)

                        ProgressView(value: pct)
                            .tint(.purple)
                    } else {
                        Text("No data yet")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                // Sparkline
                SparklineView(
                    data: last7DaysLevels,
                    color: .purple
                )
                .frame(height: 40)
            }
        }
    }

    // MARK: - Nutrition Progress

    private var nutritionProgressCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.green)
                    Text("Today's Nutrition")
                        .font(.headline)
                    Spacer()
                }

                let today = todayNutrition
                let goals = nutritionGoals

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    NutritionRingView(
                        label: "Protein",
                        current: today.protein,
                        goal: goals.protein,
                        unit: "g",
                        color: .blue
                    ) { showLogNutrition = true }

                    NutritionRingView(
                        label: "Fiber",
                        current: today.fiber,
                        goal: goals.fiber,
                        unit: "g",
                        color: .green
                    ) { showLogNutrition = true }

                    NutritionRingView(
                        label: "Water",
                        current: today.water,
                        goal: goals.water,
                        unit: "oz",
                        color: .cyan
                    ) { showLogNutrition = true }

                    NutritionRingView(
                        label: "Calories",
                        current: today.calories,
                        goal: goals.calories,
                        unit: "",
                        color: .orange
                    ) { showLogNutrition = true }
                }
            }
        }
    }

    // MARK: - Weight Card

    private var weightCard: some View {
        Button { showLogWeight = true } label: {
            CardContainer {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundStyle(.indigo)
                            Text("Weight")
                                .font(.headline)
                        }

                        if let latest = weightEntries.first {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(latest.weightLbs, specifier: "%.1f")")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                Text("lbs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if weightEntries.count >= 2 {
                                    let prev = weightEntries[1]
                                    let diff = latest.weightLbs - prev.weightLbs
                                    let losing = diff < 0
                                    Text("\(losing ? "↓" : "↑") \(abs(diff), specifier: "%.1f")")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(losing ? .green : .red)
                                }
                            }

                            let daysSince = Calendar.current.dateComponents(
                                [.day], from: latest.date, to: .now
                            ).day ?? 0
                            if daysSince > 1 {
                                Text("Last weighed: \(daysSince) days ago")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Tap to log weight")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Activity

    private var recentActivityCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.teal)
                    Text("Recent Activity")
                        .font(.headline)
                    Spacer()
                }

                let items = recentActivityItems.prefix(5)
                if items.isEmpty {
                    Text("No activity yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(item.color.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Image(systemName: item.icon)
                                            .font(.caption)
                                            .foregroundStyle(item.color)
                                    }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline)
                                    Text(item.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(item.date.formatted(.relative(presentation: .named)))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)

                            if idx < items.count - 1 {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions FAB

    private var quickActionButton: some View {
        VStack(spacing: 12) {
            if showQuickActions {
                VStack(spacing: 8) {
                    QuickActionButton(icon: "syringe.fill", label: "Injection", color: .blue) {
                        showQuickActions = false
                        showLogInjection = true
                    }
                    QuickActionButton(icon: "scalemass.fill", label: "Weight", color: .indigo) {
                        showQuickActions = false
                        showLogWeight = true
                    }
                    QuickActionButton(icon: "fork.knife", label: "Nutrition", color: .green) {
                        showQuickActions = false
                        showLogNutrition = true
                    }
                    QuickActionButton(icon: "heart.text.clipboard", label: "Side Effect", color: .orange) {
                        showQuickActions = false
                        showLogSideEffect = true
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.35)) {
                    showQuickActions.toggle()
                }
            } label: {
                Image(systemName: showQuickActions ? "xmark" : "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.blue, in: Circle())
                    .shadow(color: .blue.opacity(0.35), radius: 8, y: 4)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

    private func daysUntilNextInjection(
        currentWeekday: Int,
        injectionDay: Int,
        alreadyLoggedToday: Bool
    ) -> Int {
        var diff = injectionDay - currentWeekday
        if diff < 0 || (diff == 0 && alreadyLoggedToday) { diff += 7 }
        return diff == 0 ? 7 : diff
    }

    private var peakEstimate: Double {
        guard let first = injections.first else { return 0 }
        return first.dosageMg
    }

    private var last7DaysLevels: [Double] {
        let now = Date.now
        return (0..<7).reversed().map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!
            return calculator.calculateLevelAt(date: date, injections: injections)
        }
    }

    private var todayNutrition: (protein: Double, fiber: Double, water: Double, calories: Double) {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: .now)
        let todayEntries = nutritionEntries.filter { cal.isDate($0.date, inSameDayAs: startOfDay) }
        return (
            protein: todayEntries.reduce(0) { $0 + $1.proteinGrams },
            fiber: todayEntries.reduce(0) { $0 + $1.fiberGrams },
            water: todayEntries.reduce(0) { $0 + $1.waterOz },
            calories: todayEntries.reduce(0) { $0 + Double($1.calories) }
        )
    }

    private var nutritionGoals: (protein: Double, fiber: Double, water: Double, calories: Double) {
        guard let p = profile else {
            return (protein: 100, fiber: 28, water: 64, calories: 2000)
        }
        return (
            protein: p.dailyProteinGoalGrams,
            fiber: p.dailyFiberGoalGrams,
            water: p.dailyWaterGoalOz,
            calories: Double(p.dailyCalorieGoal)
        )
    }

    private var recentActivityItems: [ActivityItem] {
        var items: [ActivityItem] = []

        for inj in injections.prefix(5) {
            items.append(ActivityItem(
                title: "Injection logged",
                subtitle: String(format: "%.2g mg — %@", inj.dosageMg, inj.injectionSite.displayName),
                icon: "syringe.fill",
                color: .blue,
                date: inj.date
            ))
        }

        for w in weightEntries.prefix(5) {
            items.append(ActivityItem(
                title: "Weight logged",
                subtitle: String(format: "%.1f lbs", w.weightLbs),
                icon: "scalemass.fill",
                color: .indigo,
                date: w.date
            ))
        }

        for se in sideEffects.prefix(3) {
            items.append(ActivityItem(
                title: se.displayName,
                subtitle: "Intensity: \(se.intensity)/5",
                icon: "heart.text.clipboard",
                color: .orange,
                date: se.date
            ))
        }

        return items.sorted { $0.date > $1.date }
    }
}

// MARK: - Supporting Types

private struct ActivityItem {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let date: Date
}

// MARK: - Card Container

struct CardContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

// MARK: - Sparkline

struct SparklineView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let maxVal = data.max() ?? 1
            let minVal = data.min() ?? 0
            let range = max(maxVal - minVal, 0.001)

            Path { path in
                guard data.count > 1 else { return }
                let stepX = geo.size.width / CGFloat(data.count - 1)
                for (i, val) in data.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = geo.size.height * (1 - CGFloat((val - minVal) / range))
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Nutrition Ring

struct NutritionRingView: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    let onTap: () -> Void

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(current))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .frame(width: 52, height: 52)

                VStack(spacing: 1) {
                    Text(label)
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text("\(Int(current))/\(Int(goal))\(unit.isEmpty ? "" : unit)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(color, in: Capsule())
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
        }
    }
}

// MARK: - Log Weight Sheet

struct LogWeightSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var weight: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight (lbs)") {
                    TextField("Enter weight", text: $weight)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let val = Double(weight), val > 0 {
                            let entry = WeightEntry(weightLbs: val)
                            modelContext.insert(entry)
                            dismiss()
                        }
                    }
                    .disabled(Double(weight) == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Log Nutrition Sheet

struct LogNutritionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var protein: String = ""
    @State private var fiber: String = ""
    @State private var water: String = ""
    @State private var calories: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Protein (g)") {
                    TextField("0", text: $protein)
                        .keyboardType(.decimalPad)
                }
                Section("Fiber (g)") {
                    TextField("0", text: $fiber)
                        .keyboardType(.decimalPad)
                }
                Section("Water (oz)") {
                    TextField("0", text: $water)
                        .keyboardType(.decimalPad)
                }
                Section("Calories") {
                    TextField("0", text: $calories)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Log Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = NutritionEntry(
                            proteinGrams: Double(protein) ?? 0,
                            fiberGrams: Double(fiber) ?? 0,
                            calories: Int(calories) ?? 0,
                            waterOz: Double(water) ?? 0
                        )
                        modelContext.insert(entry)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(DataManager(inMemory: true).modelContainer)
}
