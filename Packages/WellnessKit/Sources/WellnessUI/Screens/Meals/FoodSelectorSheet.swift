import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

struct FoodSelectorSheet: View {
    @Environment(MealFeatureStore.self) private var mealStore
    @Environment(\.dismiss) private var dismiss

    let onSelect: (MealItem) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @State private var selectedFood: FoodItem?
    @State private var amount: Double = 100
    @State private var mealId = ""

    var body: some View {
        Group {
            if let food = selectedFood {
                amountView(food: food)
            } else {
                foodListView
            }
        }
        .navigationTitle("Add Food")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var foodListView: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(FoodCategory.displayOrder, id: \.self) { cat in
                            FilterChip(label: categoryLabel(cat), isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            ForEach(filteredFoods) { food in
                Button {
                    amount = defaultAmount(for: food)
                    selectedFood = food
                } label: {
                    FoodRow(food: food)
                }
                .tint(.primary)
            }
        }
        .searchable(text: $searchText, prompt: "Search foods")
    }

    private func amountView(food: FoodItem) -> some View {
        let macros = FoodNutritionMath.computeMacrosFromDisplay(food, displayQuantity: amount)
        return Form {
            Section {
                HStack {
                    Text(food.name)
                        .font(.headline)
                    Spacer()
                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("Amount") {
                HStack {
                    TextField("Amount", value: $amount, format: .number)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .frame(width: 100)
                    Text(FoodNutritionMath.displayUnitLabel(food))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    ForEach(quickAmounts(for: food), id: \.self) { q in
                        Button("\(Int(q))") { amount = q }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
            Section("Nutrition") {
                LabeledContent("Calories", value: "\(Int(macros.kcal)) kcal")
                LabeledContent("Protein", value: "\(Int(macros.protein))g")
                LabeledContent("Carbs", value: "\(Int(macros.carbs))g")
                LabeledContent("Fat", value: "\(Int(macros.fat))g")
            }
            Section {
                Button("Add to Meal") {
                    let stored = FoodNutritionMath.storedQuantity(food, displayQuantity: amount)
                    let m = FoodNutritionMath.computeMacros(food, storedQuantity: stored)
                    let item = MealItem(
                        id: UUID().uuidString, mealId: mealId,
                        foodId: food.id, amount: stored,
                        kcal: m.kcal, protein: m.protein,
                        carbs: m.carbs, fat: m.fat
                    )
                    onSelect(item)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button { selectedFood = nil } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
    }

    private var filteredFoods: [FoodItem] {
        var result = mealStore.foods
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }
        return result
    }

    private func defaultAmount(for food: FoodItem) -> Double {
        switch food.servingKind {
        case .per100g: 100
        case .perGram: 100
        case .perMl:   250
        case .perOz:   4
        case .perCount: 1
        }
    }

    private func quickAmounts(for food: FoodItem) -> [Double] {
        switch food.servingKind {
        case .per100g:  [50, 100, 150, 200]
        case .perGram:  [50, 100, 150, 200]
        case .perMl:    [100, 200, 250, 500]
        case .perOz:    [1, 2, 4, 8]
        case .perCount: [1, 2, 3, 4]
        }
    }

    private func categoryLabel(_ cat: FoodCategory) -> String {
        switch cat {
        case .protein:        "Protein"
        case .dairy:          "Dairy"
        case .grains:         "Grains"
        case .legumes:        "Legumes"
        case .vegetables:     "Vegetables"
        case .fruit:          "Fruit"
        case .nutsAndSeeds:   "Nuts & Seeds"
        case .fatsAndOils:    "Fats & Oils"
        case .beverages:      "Beverages"
        case .condiments:     "Condiments"
        case .snacksAndSweets: "Sweets"
        case .preparedDishes: "Prepared"
        case .supplements:    "Supplements"
        case .fastFood:       "Fast Food"
        case .other:          "Other"
        }
    }
}

struct FoodRow: View {
    let food: FoodItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(food.name)
                    .font(.body)
                Spacer()
                Text("\(Int(food.kcalPerUnit)) kcal/\(food.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                MacroLabel(value: food.proteinPerUnit, label: "P", color: .blue)
                MacroLabel(value: food.carbsPerUnit, label: "C", color: .orange)
                MacroLabel(value: food.fatPerUnit, label: "F", color: .yellow)
            }
            .font(.caption2)
        }
        .padding(.vertical, 2)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
