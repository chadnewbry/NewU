import SwiftUI
import SwiftData

struct ProgressView_: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query(sort: \NutritionEntry.date, order: .reverse) private var nutritionEntries: [NutritionEntry]

    @State private var showLogWeight = false
    @State private var showLogNutrition = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick log buttons
                    HStack(spacing: 12) {
                        Button {
                            showLogWeight = true
                        } label: {
                            Label("Log Weight", systemImage: "scalemass.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }

                        Button {
                            showLogNutrition = true
                        } label: {
                            Label("Log Food", systemImage: "fork.knife")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.green, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal)

                    // Weight chart
                    WeightChartView()
                        .padding(.horizontal)

                    // Nutrition dashboard with rings + weekly chart
                    NutritionDashboardView()
                        .padding(.horizontal)

                    // Activity (steps + workouts from HealthKit)
                    ActivityView()
                        .padding(.horizontal)
                }
                .padding(.top)
                .padding(.bottom, 32)
            }
            .navigationTitle("Progress")
            .sheet(isPresented: $showLogWeight) {
                LogWeightView()
            }
            .sheet(isPresented: $showLogNutrition) {
                LogNutritionView()
            }
        }
    }
}

#Preview {
    ProgressView_()
        .modelContainer(
            for: [WeightEntry.self, NutritionEntry.self, UserProfile.self, Injection.self],
            inMemory: true
        )
}
