import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Injection.date) private var injections: [Injection]
    @Query(sort: \WeightEntry.date) private var weightEntries: [WeightEntry]
    @Query(sort: \NutritionEntry.date) private var nutritionEntries: [NutritionEntry]
    @Query(sort: \SideEffect.date) private var sideEffects: [SideEffect]
    @Query(sort: \DailyNote.date) private var dailyNotes: [DailyNote]

    @State private var displayedMonth: Date = .now
    @State private var selectedDate: Date? = nil
    @State private var showingDayDetail = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                weekdayHeader
                calendarGrid
                Spacer()
            }
            .navigationTitle("Calendar")
            .sheet(isPresented: $showingDayDetail) {
                if let date = selectedDate {
                    DayDetailView(
                        date: date,
                        injections: itemsForDate(injections, keyPath: \.date, date: date),
                        weightEntries: itemsForDate(weightEntries, keyPath: \.date, date: date),
                        nutritionEntries: itemsForDate(nutritionEntries, keyPath: \.date, date: date),
                        sideEffects: itemsForDate(sideEffects, keyPath: \.date, date: date),
                        dailyNote: dailyNotes.first { calendar.isDate($0.date, inSameDayAs: date) }
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        if value.translation.width < -50 {
                            withAnimation { changeMonth(by: 1) }
                        } else if value.translation.width > 50 {
                            withAnimation { changeMonth(by: -1) }
                        }
                    }
            )
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { withAnimation { changeMonth(by: -1) } } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.title2.weight(.bold))

            Spacer()

            Button { withAnimation { changeMonth(by: 1) } } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date {
                    DayCellView(
                        date: date,
                        isToday: calendar.isDateInToday(date),
                        indicators: indicatorsForDate(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                        showingDayDetail = true
                    }
                } else {
                    Color.clear
                        .frame(height: 52)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Helpers

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete last row
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func indicatorsForDate(_ date: Date) -> DayIndicators {
        DayIndicators(
            hasInjection: !itemsForDate(injections, keyPath: \.date, date: date).isEmpty,
            hasWeight: !itemsForDate(weightEntries, keyPath: \.date, date: date).isEmpty,
            hasNutrition: !itemsForDate(nutritionEntries, keyPath: \.date, date: date).isEmpty,
            hasSideEffect: !itemsForDate(sideEffects, keyPath: \.date, date: date).isEmpty
        )
    }

    private func itemsForDate<T>(_ items: [T], keyPath: KeyPath<T, Date>, date: Date) -> [T] {
        items.filter { calendar.isDate($0[keyPath: keyPath], inSameDayAs: date) }
    }
}

// MARK: - Day Indicators

struct DayIndicators {
    let hasInjection: Bool
    let hasWeight: Bool
    let hasNutrition: Bool
    let hasSideEffect: Bool

    var hasAny: Bool {
        hasInjection || hasWeight || hasNutrition || hasSideEffect
    }
}

// MARK: - Day Cell

struct DayCellView: View {
    let date: Date
    let isToday: Bool
    let indicators: DayIndicators

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.callout.weight(isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 32, height: 32)
                .background {
                    if isToday {
                        Circle().fill(.blue)
                    }
                }

            HStack(spacing: 3) {
                if indicators.hasInjection {
                    Circle().fill(.blue).frame(width: 5, height: 5)
                }
                if indicators.hasWeight {
                    Circle().fill(.green).frame(width: 5, height: 5)
                }
                if indicators.hasNutrition {
                    Circle().fill(.orange).frame(width: 5, height: 5)
                }
                if indicators.hasSideEffect {
                    Circle().fill(.red).frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Injection.self, WeightEntry.self, NutritionEntry.self, SideEffect.self, DailyNote.self], inMemory: true)
}
