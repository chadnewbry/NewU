import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var currentStep = 0
    @State private var selectedMedication: Medication?
    @State private var currentDosageMg: Double?
    @State private var injectionDayOfWeek: Int = 2 // Monday
    @State private var reminderHour: Int = 9
    @State private var reminderMinute: Int = 0
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 10
    @State private var startWeightLbs: String = ""
    @State private var goalWeightLbs: String = ""
    @State private var notificationsEnabled: Bool = false
    @State private var healthKitConnected: Bool = false
    @State private var customMedicationName: String = ""
    @State private var customHalfLife: String = ""

    let onComplete: () -> Void
    private let totalSteps = 8

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if currentStep > 0 {
                    progressHeader
                }

                TabView(selection: $currentStep) {
                    WelcomeStepView(onContinue: nextStep)
                        .tag(0)

                    MedicationSelectionStepView(
                        selectedMedication: $selectedMedication,
                        customMedicationName: $customMedicationName,
                        customHalfLife: $customHalfLife,
                        onContinue: nextStep
                    )
                    .tag(1)

                    DosageStepView(
                        selectedMedication: selectedMedication,
                        currentDosageMg: $currentDosageMg,
                        onContinue: nextStep
                    )
                    .tag(2)

                    ScheduleStepView(
                        injectionDayOfWeek: $injectionDayOfWeek,
                        reminderHour: $reminderHour,
                        reminderMinute: $reminderMinute,
                        onContinue: nextStep
                    )
                    .tag(3)

                    BodyStatsStepView(
                        heightFeet: $heightFeet,
                        heightInches: $heightInches,
                        startWeightLbs: $startWeightLbs,
                        goalWeightLbs: $goalWeightLbs,
                        onContinue: nextStep
                    )
                    .tag(4)

                    NotificationStepView(
                        notificationsEnabled: $notificationsEnabled,
                        onContinue: nextStep
                    )
                    .tag(5)

                    HealthIntegrationStepView(
                        healthKitConnected: $healthKitConnected,
                        onContinue: nextStep
                    )
                    .tag(6)

                    SuccessPlanStepView(
                        startWeightLbs: Double(startWeightLbs) ?? 0,
                        goalWeightLbs: Double(goalWeightLbs),
                        selectedMedication: selectedMedication,
                        currentDosageMg: currentDosageMg,
                        injectionDayOfWeek: injectionDayOfWeek,
                        onComplete: completeOnboarding
                    )
                    .tag(7)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }

            if currentStep > 0 {
                backButton
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        HStack(spacing: 6) {
            ForEach(1..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.accentColor : Color(.systemGray4))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Back Button

    private var backButton: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = max(0, currentStep - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
        }
        .padding(.leading, 16)
        .padding(.top, 20)
    }

    // MARK: - Actions

    private func nextStep() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = min(totalSteps - 1, currentStep + 1)
        }
    }

    private func completeOnboarding() {
        profile.selectedMedication = selectedMedication
        profile.currentDosageMg = currentDosageMg
        profile.injectionDayOfWeek = injectionDayOfWeek
        profile.reminderHour = reminderHour
        profile.reminderMinute = reminderMinute
        profile.heightInches = Double(heightFeet * 12 + heightInches)
        profile.notificationsEnabled = notificationsEnabled

        if let weight = Double(startWeightLbs), weight > 0 {
            profile.startWeightLbs = weight
        }

        if let goal = Double(goalWeightLbs), goal > 0 {
            profile.goalWeightLbs = goal
        } else {
            profile.goalWeightLbs = Double(startWeightLbs) ?? 150
        }

        let referenceWeight = Double(goalWeightLbs) ?? Double(startWeightLbs) ?? 150
        profile.dailyProteinGoalGrams = round(referenceWeight * 0.8)
        profile.dailyFiberGoalGrams = 28
        profile.dailyWaterGoalOz = 64
        profile.startDate = .now

        profile.hasCompletedOnboarding = true

        if notificationsEnabled {
            NotificationManager.shared.updateReminders(for: profile)
        }

        onComplete()
    }
}
