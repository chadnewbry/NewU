import SwiftUI
import SwiftData

struct SideEffectsView: View {
    @State private var showingLogSheet = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    SideEffectHistoryView()
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

                NavigationLink {
                    SideEffectPatternsView()
                } label: {
                    Label("Patterns & Insights", systemImage: "chart.bar.xaxis")
                }
            }
            .navigationTitle("Side Effects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingLogSheet) {
                LogSideEffectView()
            }
        }
    }
}

#Preview {
    SideEffectsView()
        .modelContainer(for: [SideEffect.self, Injection.self], inMemory: true)
}
