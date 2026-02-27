import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Injection.date) private var injections: [Injection]
    @State private var selectedDate: Date = .now

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.green)
                .padding(.horizontal)

                Divider()

                // Injections for selected date
                let dayInjections = injectionsForDate(selectedDate)
                if dayInjections.isEmpty {
                    ContentUnavailableView(
                        "No Injections",
                        systemImage: "calendar.badge.minus",
                        description: Text("Nothing logged for this date.")
                    )
                } else {
                    List(dayInjections) { injection in
                        InjectionRow(injection: injection)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Calendar")
        }
    }

    private func injectionsForDate(_ date: Date) -> [Injection] {
        let calendar = Calendar.current
        return injections.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: Injection.self, inMemory: true)
}
