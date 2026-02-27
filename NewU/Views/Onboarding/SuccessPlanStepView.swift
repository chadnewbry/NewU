import SwiftUI

struct SuccessPlanStepView: View {
    let startWeightLbs: Double
    let goalWeightLbs: Double?
    let selectedMedication: Medication?
    let currentDosageMg: Double?
    let injectionDayOfWeek: Int
    let onComplete: () -> Void

    private let weeklyLossRate = 1.5 // lbs per week average

    private var estimatedWeeksToGoal: Int? {
        guard let goal = goalWeightLbs, goal > 0, startWeightLbs > goal else { return nil }
        return Int(ceil((startWeightLbs - goal) / weeklyLossRate))
    }

    private var estimatedGoalDate: Date? {
        guard let weeks = estimatedWeeksToGoal else { return nil }
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: .now)
    }

    private var proteinGoal: Int {
        let reference = goalWeightLbs ?? startWeightLbs
        guard reference > 0 else { return 100 }
        return Int(round(reference * 0.8))
    }

    private var dayName: String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard injectionDayOfWeek >= 1, injectionDayOfWeek <= 7 else { return "Monday" }
        return days[injectionDayOfWeek]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)

                    Text("Your Personal Plan")
                        .font(.title.bold())

                    Text("Here's what we've set up for you")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    // Medication card
                    if let med = selectedMedication {
                        planCard(
                            icon: "syringe.fill",
                            color: .blue,
                            title: med.name,
                            value: formatDosage(currentDosageMg),
                            subtitle: "Every \(dayName)"
                        )
                    }

                    // Goal timeline
                    if let goalDate = estimatedGoalDate, let goal = goalWeightLbs, let weeks = estimatedWeeksToGoal {
                        planCard(
                            icon: "flag.fill",
                            color: .green,
                            title: "Goal Weight",
                            value: "\(Int(goal)) lbs",
                            subtitle: "~\(weeks) weeks (\(goalDate.formatted(.dateTime.month().year())))"
                        )
                    }

                    // Daily targets
                    planCard(
                        icon: "fork.knife",
                        color: .orange,
                        title: "Daily Protein",
                        value: "\(proteinGoal)g",
                        subtitle: "0.8g per lb of target weight"
                    )

                    planCard(
                        icon: "leaf.fill",
                        color: .green,
                        title: "Daily Fiber",
                        value: "28g",
                        subtitle: "Supports digestive health"
                    )

                    planCard(
                        icon: "drop.fill",
                        color: .blue,
                        title: "Daily Water",
                        value: "64 oz",
                        subtitle: "Stay hydrated for best results"
                    )
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 80)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onComplete) {
                Text("Start Tracking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
            .background(.ultraThinMaterial)
        }
    }

    private func planCard(icon: String, color: Color, title: String, value: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title3.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func formatDosage(_ mg: Double?) -> String {
        guard let mg else { return "Starting dose" }
        if mg == mg.rounded() && mg >= 1 {
            return String(format: "%.0f mg", mg)
        }
        return String(format: "%.2g mg", mg)
    }
}
