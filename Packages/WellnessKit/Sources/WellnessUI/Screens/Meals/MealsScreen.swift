import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

public struct MealsScreen: View {
    @Environment(MealFeatureStore.self) private var mealStore

    public init() {}

    public var body: some View {
        List {
            Section {
                NutritionSummaryRow(
                    kcal: mealStore.totalKcal,
                    protein: mealStore.totalProtein,
                    carbs: mealStore.totalCarbs,
                    fat: mealStore.totalFat
                )
            }

            if mealStore.todayMeals.isEmpty {
                ContentUnavailableView(
                    "No Meals",
                    systemImage: "fork.knife",
                    description: Text("Tap + to log a meal.")
                )
            } else {
                ForEach(mealStore.todayMeals) { meal in
                    MealRow(meal: meal)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { try? await mealStore.deleteMeal(id: meal.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Meals")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                NavigationLink(value: AppRoute.mealEdit(id: nil)) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                NavigationLink(value: AppRoute.mealFoods) {
                    Image(systemName: "list.bullet")
                }
            }
        }
        .refreshable { await mealStore.load() }
    }
}

struct MealRow: View {
    let meal: Meal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(meal.name)
                    .font(.headline)
                Spacer()
                Text("\(Int(meal.totalKcal)) kcal")
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                MacroLabel(value: meal.totalProtein, label: "P", color: .blue)
                MacroLabel(value: meal.totalCarbs, label: "C", color: .orange)
                MacroLabel(value: meal.totalFat, label: "F", color: .yellow)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct NutritionSummaryRow: View {
    let kcal: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(kcal))")
                .font(.title.bold())
            Text("kcal")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 20) {
                MacroLabel(value: protein, label: "Protein", color: .blue)
                MacroLabel(value: carbs, label: "Carbs", color: .orange)
                MacroLabel(value: fat, label: "Fat", color: .yellow)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct MacroLabel: View {
    let value: Double
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(Int(value))g \(label)")
                .foregroundStyle(.secondary)
        }
    }
}
