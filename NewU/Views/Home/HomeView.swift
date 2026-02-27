import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Injection.date, order: .reverse) private var recentInjections: [Injection]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Your Daily Overview")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    // Quick stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Next Dose", value: "—", icon: "clock.fill", color: .blue)
                        StatCard(title: "Streak", value: "0 days", icon: "flame.fill", color: .orange)
                        StatCard(title: "This Week", value: "\(weeklyCount)", icon: "syringe.fill", color: .green)
                        StatCard(title: "Weight", value: "—", icon: "scalemass.fill", color: .purple)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("NewU")
        }
    }

    private var weeklyCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return recentInjections.filter { $0.date >= weekAgo }.count
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Injection.self, inMemory: true)
}
