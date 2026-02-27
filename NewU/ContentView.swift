import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home, track, calculator, progress, calendar
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            TrackView()
                .tabItem {
                    Label("Track", systemImage: "syringe.fill")
                }
                .tag(Tab.track)

            CalculatorView()
                .tabItem {
                    Label("Calculator", systemImage: "function")
                }
                .tag(Tab.calculator)

            ProgressView_()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.progress)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    ContentView()
}
