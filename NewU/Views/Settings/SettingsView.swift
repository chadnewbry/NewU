import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var profiles: [UserProfile]
    @Query private var medications: [Medication]

    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = "system"
    @AppStorage("accentColorTheme") private var accentColorTheme: String = "blue"

    @StateObject private var healthKitManager = HealthKitManager()
    @ObservedObject private var purchaseManager = PurchaseManager.shared

    @State private var showClearDataAlert = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var healthKitStatusMessage = ""
    @State private var isRequestingHealthKit = false
    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    // Profile edit state
    @State private var heightFeet: Int = 5
    @State private var heightInchesRemainder: Int = 10
    @State private var currentWeightText: String = ""
    @State private var goalWeightText: String = ""
    @State private var proteinGoalText: String = ""
    @State private var fiberGoalText: String = ""
    @State private var calorieGoalText: String = ""
    @State private var waterGoalText: String = ""
    @State private var stepGoalText: String = ""

    private var profile: UserProfile? { profiles.first }

    private let weekdays = [
        (1, "Sunday"), (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"),
        (5, "Thursday"), (6, "Friday"), (7, "Saturday")
    ]

    private let accentThemes: [(key: String, color: Color, label: String)] = [
        ("blue", .blue, "Ocean Blue"),
        ("purple", .purple, "Violet"),
        ("green", .green, "Mint Green"),
    ]

    var body: some View {
        Form {
            profileSection
            notificationsSection
            healthSection
            appearanceSection
            dataSection
            purchaseSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadProfileState()
            updateHealthKitStatus()
        }
        .alert("Clear All Data", isPresented: $showClearDataAlert) {
            Button("Delete Everything", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your injection logs, weight entries, nutrition data, and side effect records. This cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareLink(item: url, subject: Text("NewU Health Summary")) {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section("Profile") {
            if let profile {
                profileBindable(profile: profile)
            } else {
                Text("No profile found")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func profileBindable(profile: UserProfile) -> some View {
        // Medication picker
        if !medications.isEmpty {
            Picker("Medication", selection: Binding(
                get: { profile.selectedMedication?.id },
                set: { id in
                    profile.selectedMedication = medications.first { $0.id == id }
                }
            )) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(medications) { med in
                    Text(med.name).tag(Optional(med.id))
                }
            }
        }

        // Dosage
        HStack {
            Text("Dosage (mg)")
            Spacer()
            TextField("0.0", value: Binding(
                get: { profile.currentDosageMg ?? 0 },
                set: { profile.currentDosageMg = $0 > 0 ? $0 : nil }
            ), format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 80)
        }

        // Injection day
        Picker("Injection Day", selection: Binding(
            get: { profile.injectionDayOfWeek ?? 2 },
            set: { profile.injectionDayOfWeek = $0 }
        )) {
            ForEach(weekdays, id: \.0) { day in
                Text(day.1).tag(day.0)
            }
        }

        // Height
        HStack(spacing: 0) {
            Text("Height")
            Spacer()
            Picker("", selection: $heightFeet) {
                ForEach(3...7, id: \.self) { ft in
                    Text("\(ft) ft").tag(ft)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .onChange(of: heightFeet) { _, _ in saveHeight(profile: profile) }

            Picker("", selection: $heightInchesRemainder) {
                ForEach(0...11, id: \.self) { inch in
                    Text("\(inch) in").tag(inch)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .onChange(of: heightInchesRemainder) { _, _ in saveHeight(profile: profile) }
        }

        // Current weight (uses startWeightLbs as editable starting point)
        HStack {
            Text("Starting Weight (lbs)")
            Spacer()
            TextField("0", text: $currentWeightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .onChange(of: currentWeightText) { _, val in
                    if let d = Double(val), d > 0 { profile.startWeightLbs = d }
                }
        }

        HStack {
            Text("Goal Weight (lbs)")
            Spacer()
            TextField("0", text: $goalWeightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .onChange(of: goalWeightText) { _, val in
                    if let d = Double(val), d > 0 { profile.goalWeightLbs = d }
                }
        }

        Section("Daily Goals") {
            labeledNumberField(label: "Protein (g)", text: $proteinGoalText) {
                if let d = Double(proteinGoalText) { profile.dailyProteinGoalGrams = d }
            }
            labeledNumberField(label: "Fiber (g)", text: $fiberGoalText) {
                if let d = Double(fiberGoalText) { profile.dailyFiberGoalGrams = d }
            }
            labeledNumberField(label: "Calories", text: $calorieGoalText) {
                if let i = Int(calorieGoalText) { profile.dailyCalorieGoal = i }
            }
            labeledNumberField(label: "Water (oz)", text: $waterGoalText) {
                if let d = Double(waterGoalText) { profile.dailyWaterGoalOz = d }
            }
            labeledNumberField(label: "Steps", text: $stepGoalText) {
                if let i = Int(stepGoalText) { profile.dailyStepGoal = i }
            }
        }
    }

    private func labeledNumberField(
        label: String,
        text: Binding<String>,
        onChange: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .onChange(of: text.wrappedValue) { _, _ in onChange() }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section("Notifications") {
            if let profile {
                NavigationLink("Notification Settings") {
                    NotificationSettingsView(profile: profile)
                }
            }
        }
    }

    // MARK: - Health Integration Section

    private var healthSection: some View {
        Section("Health Integration") {
            if let profile {
                Toggle("Sync with Apple Health", isOn: Binding(
                    get: { profile.healthKitEnabled },
                    set: { profile.healthKitEnabled = $0 }
                ))

                if healthKitManager.isAvailable {
                    Button {
                        requestHealthKitPermissions()
                    } label: {
                        HStack {
                            Label("Re-request Permissions", systemImage: "heart.fill")
                            Spacer()
                            if isRequestingHealthKit {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isRequestingHealthKit)

                    if !healthKitStatusMessage.isEmpty {
                        Text(healthKitStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("HealthKit is not available on this device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Color Scheme", selection: $appColorSchemeRaw) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Accent Color")
                    .font(.subheadline)

                HStack(spacing: 12) {
                    ForEach(accentThemes, id: \.key) { theme in
                        Button {
                            accentColorTheme = theme.key
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if accentColorTheme == theme.key {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .shadow(color: theme.color.opacity(0.4), radius: 4)
                                Text(theme.label)
                                    .font(.caption2)
                                    .foregroundStyle(accentColorTheme == theme.key ? theme.color : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section("Data") {
            HStack {
                Label("iCloud Sync", systemImage: "icloud.fill")
                Spacer()
                Text("Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.15), in: Capsule())
                    .foregroundStyle(.green)
            }

            Button {
                generateAndExportPDF()
            } label: {
                Label("Export Summary PDF", systemImage: "doc.richtext")
            }

            Button(role: .destructive) {
                showClearDataAlert = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        Section("Full Access") {
            if purchaseManager.isPurchased || profile?.hasPurchasedFullAccess == true {
                HStack {
                    Label("Full Access Active", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Spacer()
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Full Access")
                                .fontWeight(.semibold)
                            Text("Unlimited injections, all features — $6.99 forever")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }
                .foregroundStyle(.primary)

                if let profile {
                    Text("\(profile.freeUsesRemaining) free injection logs remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                restorePurchase()
            } label: {
                HStack(spacing: 8) {
                    Text("Restore Purchase")
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.75)
                    }
                }
            }
            .foregroundStyle(.blue)
            .disabled(isRestoring)

            if let restoreMessage {
                Text(restoreMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func restorePurchase() {
        isRestoring = true
        restoreMessage = nil
        Task {
            do {
                let restored = try await purchaseManager.restorePurchases()
                restoreMessage = restored
                    ? "Purchase restored successfully."
                    : "No previous purchase found."
            } catch {
                restoreMessage = error.localizedDescription
            }
            isRestoring = false
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            Link(destination: URL(string: "https://newu-app.com/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Link(destination: URL(string: "https://newu-app.com/terms")!) {
                Label("Terms of Use", systemImage: "doc.text.fill")
            }

            Link(destination: URL(string: "mailto:chad.newbry@gmail.com")!) {
                Label("Customer Support", systemImage: "envelope.fill")
            }

            Button {
                requestAppReview()
            } label: {
                Label("Rate NewU", systemImage: "star.fill")
            }

            ShareLink(
                item: URL(string: "https://apps.apple.com/app/id0000000000")!,
                subject: Text("Check out NewU"),
                message: Text("I've been using NewU to track my GLP-1 journey — it's great!")
            ) {
                Label("Share NewU", systemImage: "square.and.arrow.up")
            }

            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func loadProfileState() {
        guard let profile else { return }
        let totalInches = Int(profile.heightInches)
        heightFeet = totalInches / 12
        heightInchesRemainder = totalInches % 12
        currentWeightText = String(format: "%.1f", profile.startWeightLbs)
        goalWeightText = String(format: "%.1f", profile.goalWeightLbs)
        proteinGoalText = String(format: "%.0f", profile.dailyProteinGoalGrams)
        fiberGoalText = String(format: "%.0f", profile.dailyFiberGoalGrams)
        calorieGoalText = "\(profile.dailyCalorieGoal)"
        waterGoalText = String(format: "%.0f", profile.dailyWaterGoalOz)
        stepGoalText = "\(profile.dailyStepGoal)"
    }

    private func saveHeight(profile: UserProfile) {
        profile.heightInches = Double(heightFeet * 12 + heightInchesRemainder)
    }

    private func updateHealthKitStatus() {
        if healthKitManager.isAvailable {
            healthKitStatusMessage = healthKitManager.isAuthorized
                ? "Connected to Apple Health"
                : "Permissions not yet granted"
        }
    }

    private func requestHealthKitPermissions() {
        isRequestingHealthKit = true
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                healthKitStatusMessage = "Apple Health permissions granted"
                if let profile { profile.healthKitEnabled = true }
            } catch {
                healthKitStatusMessage = "Could not connect: \(error.localizedDescription)"
            }
            isRequestingHealthKit = false
        }
    }

    private func generateAndExportPDF() {
        guard let profile else { return }
        let url = PDFExporter.generateSummary(profile: profile, modelContext: modelContext)
        exportURL = url
        showExportSheet = true
    }

    private func clearAllData() {
        do {
            try modelContext.delete(model: Injection.self)
            try modelContext.delete(model: WeightEntry.self)
            try modelContext.delete(model: NutritionEntry.self)
            try modelContext.delete(model: SideEffect.self)
            try modelContext.delete(model: DailyNote.self)
        } catch {
            print("Error clearing data: \(error)")
        }
    }

    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - PDF Exporter

enum PDFExporter {
    static func generateSummary(profile: UserProfile, modelContext: ModelContext) -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("NewU_Summary_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).pdf")

        do {
            try renderer.writePDF(to: tempURL) { ctx in
                ctx.beginPage()
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold)
                ]
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14)
                ]

                "NewU Health Summary".draw(at: CGPoint(x: 40, y: 40), withAttributes: attrs)

                let date = Date().formatted(date: .long, time: .omitted)
                "Generated: \(date)".draw(at: CGPoint(x: 40, y: 76), withAttributes: titleAttrs)

                var y: CGFloat = 120
                let lineHeight: CGFloat = 22

                func drawLine(_ text: String) {
                    text.draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
                    y += lineHeight
                }

                drawLine("PROFILE")
                if let med = profile.selectedMedication {
                    drawLine("  Medication: \(med.name)")
                }
                if let dose = profile.currentDosageMg {
                    drawLine("  Current Dose: \(String(format: "%.2g", dose)) mg")
                }
                let feet = Int(profile.heightInches) / 12
                let inches = Int(profile.heightInches) % 12
                drawLine("  Height: \(feet)'\(inches)\"")
                drawLine("  Start Weight: \(String(format: "%.1f", profile.startWeightLbs)) lbs")
                drawLine("  Goal Weight: \(String(format: "%.1f", profile.goalWeightLbs)) lbs")

                y += lineHeight
                drawLine("DAILY GOALS")
                drawLine("  Protein: \(Int(profile.dailyProteinGoalGrams))g")
                drawLine("  Fiber: \(Int(profile.dailyFiberGoalGrams))g")
                drawLine("  Calories: \(profile.dailyCalorieGoal) kcal")
                drawLine("  Water: \(Int(profile.dailyWaterGoalOz)) oz")
                drawLine("  Steps: \(profile.dailyStepGoal)")
            }
        } catch {
            print("PDF generation error: \(error)")
        }

        return tempURL
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(DataManager(inMemory: true).modelContainer)
}
