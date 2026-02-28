import SwiftUI
import SwiftData

struct ActivityView: View {
    @StateObject private var healthKit = HealthKitManager()
    @Query private var profiles: [UserProfile]

    @State private var steps: Int = 0
    @State private var workouts: [WorkoutSummary] = []
    @State private var isLoading = false
    @State private var loadError: String?

    private var profile: UserProfile? { profiles.first }
    private var stepGoal: Int { profile?.dailyStepGoal ?? 10000 }

    private var stepProgress: Double {
        min(Double(steps) / Double(max(stepGoal, 1)), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Activity", systemImage: "figure.walk")
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if !healthKit.isAvailable {
                Text("HealthKit is not available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Steps card
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.teal.opacity(0.2), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: stepProgress)
                            .stroke(Color.teal, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: stepProgress)
                        Image(systemName: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(.teal)
                    }
                    .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(steps.formatted())
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("of \(stepGoal.formatted()) steps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if steps >= stepGoal {
                            Label("Goal reached!", systemImage: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.teal)
                        }
                    }

                    Spacer()

                    // Progress percentage
                    Text("\(Int(stepProgress * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.teal)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Recent workouts
                if !workouts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Workouts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(workouts.prefix(3)) { workout in
                            WorkoutRowView(workout: workout)
                        }
                    }
                } else if !isLoading {
                    HStack {
                        Image(systemName: "figure.mixed.cardio")
                            .foregroundStyle(.secondary)
                        Text("No workouts in the last 7 days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if let error = loadError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .task {
            await loadActivity()
        }
    }

    private func loadActivity() async {
        guard healthKit.isAvailable else { return }
        isLoading = true

        do {
            try await healthKit.requestAuthorization()
            steps = try await healthKit.fetchSteps(for: .now)

            let end = Date.now
            let start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
            let fetched = try await healthKit.fetchWorkouts(from: start, to: end)
            // Sort newest first
            workouts = fetched.sorted { $0.startDate > $1.startDate }
        } catch {
            loadError = "Could not load activity data."
        }

        isLoading = false
    }
}

// MARK: - Workout Row

struct WorkoutRowView: View {
    let workout: WorkoutSummary

    private var durationText: String {
        let minutes = Int(workout.duration / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes) min"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.orange.opacity(0.15), in: Circle())
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.activityType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(workout.startDate, format: .dateTime.weekday().month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(durationText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let cal = workout.totalEnergyBurned {
                    Text("\(Int(cal)) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var iconName: String {
        switch workout.activityType {
        case "Running": return "figure.run"
        case "Cycling": return "figure.outdoor.cycle"
        case "Walking": return "figure.walk"
        case "Swimming": return "figure.pool.swim"
        case "Hiking": return "figure.hiking"
        case "Yoga": return "figure.mind.and.body"
        case "Strength Training": return "dumbbell.fill"
        case "HIIT": return "bolt.heart.fill"
        case "Elliptical": return "figure.elliptical"
        case "Rowing": return "figure.rower"
        case "Pilates": return "figure.pilates"
        case "Stair Climbing": return "figure.stair.stepper"
        default: return "figure.mixed.cardio"
        }
    }
}

#Preview {
    ActivityView()
        .modelContainer(for: UserProfile.self, inMemory: true)
        .padding()
        .background(Color(.systemGroupedBackground))
}
