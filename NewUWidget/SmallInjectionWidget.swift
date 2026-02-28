import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SmallWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetEntryData
}

// MARK: - Provider

struct SmallWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallWidgetEntry {
        SmallWidgetEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmallWidgetEntry) -> Void) {
        let entry = SmallWidgetEntry(date: .now, data: .fromSharedDefaults())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallWidgetEntry>) -> Void) {
        let data = WidgetEntryData.fromSharedDefaults()
        let entry = SmallWidgetEntry(date: .now, data: data)

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - View

struct SmallInjectionWidgetView: View {
    let entry: SmallWidgetEntry

    private var levelColor: Color {
        let pct = entry.data.medicationLevelPct
        if pct >= 0.7 { return .green }
        if pct >= 0.4 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.35), Color(red: 0.2, green: 0.1, blue: 0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                // App label
                HStack(spacing: 4) {
                    Image(systemName: "syringe.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("NewU")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Next shot countdown
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Shot")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(entry.data.nextInjectionDays)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(entry.data.nextInjectionDays == 1 ? "day" : "days")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                // Medication level
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Medication Level")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(entry.data.medicationLevelPct * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(levelColor)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .frame(height: 5)
                            Capsule()
                                .fill(levelColor)
                                .frame(width: geo.size.width * entry.data.medicationLevelPct, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Widget

struct SmallInjectionWidget: Widget {
    let kind: String = "SmallInjectionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmallWidgetProvider()) { entry in
            SmallInjectionWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.35), Color(red: 0.2, green: 0.1, blue: 0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Next Shot")
        .description("Shows your next injection countdown and current medication level.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SmallInjectionWidget()
} timeline: {
    SmallWidgetEntry(date: .now, data: .placeholder)
}
