import SwiftUI
import SwiftData

struct ProgressView_: View {
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]
    @Query(sort: \Injection.date, order: .reverse) private var injections: [Injection]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if metrics.isEmpty && injections.isEmpty {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Start tracking to see your progress.")
                        )
                    } else {
                        // Summary cards
                        VStack(spacing: 16) {
                            SummaryCard(
                                title: "Total Injections",
                                value: "\(injections.count)",
                                icon: "syringe.fill",
                                color: .blue
                            )
                            SummaryCard(
                                title: "Weight Entries",
                                value: "\(metrics.count)",
                                icon: "scalemass.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Progress")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ProgressView_()
        .modelContainer(for: [Injection.self, BodyMetric.self], inMemory: true)
}
