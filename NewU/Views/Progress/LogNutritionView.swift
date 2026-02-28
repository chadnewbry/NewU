import SwiftUI
import SwiftData

struct LogNutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var protein: Double = 0
    @State private var fiber: Double = 0
    @State private var calories: Int = 0
    @State private var water: Double = 0
    @State private var date: Date = .now
    @State private var showBarcodeScanner = false
    @State private var isLookingUp = false
    @State private var lookupError: String?
    @State private var lookupSuccess: String?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        NutrientInputRow(
                            label: "Protein",
                            value: $protein,
                            unit: "g",
                            color: .blue,
                            icon: "bolt.fill",
                            goal: profile?.dailyProteinGoalGrams,
                            quickAmounts: [10, 20, 30, 50]
                        )

                        NutrientInputRow(
                            label: "Fiber",
                            value: $fiber,
                            unit: "g",
                            color: .green,
                            icon: "leaf.fill",
                            goal: profile?.dailyFiberGoalGrams,
                            quickAmounts: [2, 5, 8, 10]
                        )

                        CalorieInputRow(
                            calories: $calories,
                            goal: profile?.dailyCalorieGoal,
                            quickAmounts: [100, 200, 300, 500]
                        )

                        WaterInputRow(
                            water: $water,
                            goal: profile?.dailyWaterGoalOz,
                            quickAmounts: [8, 12, 16, 20]
                        )
                    }
                    .padding(.horizontal)

                    // Barcode scan
                    Button {
                        showBarcodeScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Scan Food Barcode")
                                    .fontWeight(.medium)
                                Text("Powered by Open Food Facts")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal)

                    if isLookingUp {
                        ProgressView("Looking up product...")
                            .padding()
                    }

                    if let success = lookupSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(success)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal)
                    }

                    if let error = lookupError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                .padding(.bottom, 32)
            }
            .navigationTitle("Log Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView { barcode in
                    showBarcodeScanner = false
                    lookupBarcode(barcode)
                }
            }
        }
    }

    private func save() {
        let entry = NutritionEntry(
            date: date,
            proteinGrams: protein,
            fiberGrams: fiber,
            calories: calories,
            waterOz: water
        )
        modelContext.insert(entry)
        dismiss()
    }

    private func lookupBarcode(_ barcode: String) {
        isLookingUp = true
        lookupError = nil
        lookupSuccess = nil

        Task {
            do {
                let result = try await OpenFoodFactsService.lookup(barcode: barcode)
                protein += result.proteinPer100g
                fiber += result.fiberPer100g
                calories += result.caloriesPer100g
                lookupSuccess = "Added: \(result.name)"
                isLookingUp = false
            } catch {
                lookupError = "Product not found — enter values manually."
                isLookingUp = false
            }
        }
    }
}

// MARK: - Input Rows

struct NutrientInputRow: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let color: Color
    let icon: String
    let goal: Double?
    let quickAmounts: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(label, systemImage: icon)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                Spacer()
                if let goal {
                    Text("\(value, specifier: "%.0f") / \(goal, specifier: "%.0f") \(unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(value, specifier: "%.0f") \(unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                ForEach(quickAmounts, id: \.self) { amount in
                    Button("+\(amount, specifier: "%.0f")") {
                        value += amount
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(color)
                }
                Spacer()
                Button {
                    value = max(0, value - quickAmounts[0])
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.secondary)
                }
                Button {
                    value = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CalorieInputRow: View {
    @Binding var calories: Int
    let goal: Int?
    let quickAmounts: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Calories", systemImage: "flame.fill")
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                Spacer()
                if let goal {
                    Text("\(calories) / \(goal) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(calories) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                ForEach(quickAmounts, id: \.self) { amount in
                    Button("+\(amount)") {
                        calories += amount
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.orange)
                }
                Spacer()
                Button {
                    calories = max(0, calories - quickAmounts[0])
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.secondary)
                }
                Button {
                    calories = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct WaterInputRow: View {
    @Binding var water: Double
    let goal: Double?
    let quickAmounts: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Water", systemImage: "drop.fill")
                    .fontWeight(.semibold)
                    .foregroundStyle(.cyan)
                Spacer()
                if let goal {
                    Text("\(water, specifier: "%.0f") / \(goal, specifier: "%.0f") oz")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(water, specifier: "%.0f") oz")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                ForEach(quickAmounts, id: \.self) { amount in
                    Button("+\(amount, specifier: "%.0f")") {
                        water += amount
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.cyan)
                }
                Spacer()
                Button {
                    water = max(0, water - quickAmounts[0])
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.secondary)
                }
                Button {
                    water = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Open Food Facts

struct FoodProduct {
    let name: String
    let proteinPer100g: Double
    let fiberPer100g: Double
    let caloriesPer100g: Int
}

enum OpenFoodFactsService {
    static func lookup(barcode: String) async throws -> FoodProduct {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int, status == 1,
              let product = json["product"] as? [String: Any],
              let nutriments = product["nutriments"] as? [String: Any] else {
            throw URLError(.cannotDecodeContentData)
        }

        let protein = (nutriments["proteins_100g"] as? Double) ?? 0
        let fiber = (nutriments["fiber_100g"] as? Double) ?? 0
        let calories = Int((nutriments["energy-kcal_100g"] as? Double) ?? 0)
        let name = (product["product_name"] as? String) ?? "Unknown product"

        return FoodProduct(name: name, proteinPer100g: protein, fiberPer100g: fiber, caloriesPer100g: calories)
    }
}

#Preview {
    LogNutritionView()
        .modelContainer(for: [NutritionEntry.self, UserProfile.self], inMemory: true)
}
