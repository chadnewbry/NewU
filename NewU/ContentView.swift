import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var selectedTab: Tab = .home
    @State private var showOnboarding = false

    private var profile: UserProfile? { profiles.first }

    enum Tab: String, CaseIterable {
        case home, track, sideEffects, calculator, progress, calendar
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

            SideEffectsView()
                .tabItem {
                    Label("Side Effects", systemImage: "heart.text.clipboard")
                }
                .tag(Tab.sideEffects)

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
        .onAppear {
            if let profile, !profile.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            if let profile {
                OnboardingContainerView(profile: profile) {
                    showOnboarding = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
