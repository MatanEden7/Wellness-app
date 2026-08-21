import SwiftUI
import WellnessModels
import WellnessStores

struct FoodEditorSheet: View {
    @Environment(MealFeatureStore.self) private var mealStore
    @Environment(\.dismiss) private var dismiss

    let existingFood: FoodItem?

    @State private var name = ""
    @State private var brand = ""
    @State private var unit: FoodServingUnit = .per100g
    @State private var kcalPerUnit: Double = 0
    @State private var proteinPerUnit: Double = 0
    @State private var carbsPerUnit: Double = 0
    @State private var fatPerUnit: Double = 0
    @State private var category: FoodCategory = .other
    @State private var tags: Set<FoodTag> = []
    @State private var isSaving = false

    private var isNew: Bool { existingFood == nil }

    init(food: FoodItem?) {
        self.existingFood = food
    }

    var body: some View {
        Form {
            Section {
                TextField("Food Name", text: $name)
                TextField("Brand (optional)", text: $brand)
            }

            Section("Serving") {
                Picker("Unit", selection: $unit) {
                    ForEach(FoodServingUnit.allCases, id: \.self) { u in
                        Text(u.rawValue).tag(u)
                    }
                }
                Picker("Category", selection: $category) {
                    ForEach(FoodCategory.displayOrder, id: \.self) { cat in
                        Text(cat.rawValue.capitalized).tag(cat)
                    }
                }
            }

            Section("Nutrition per \(unit.rawValue)") {
                numberField("Calories (kcal)", value: $kcalPerUnit)
                numberField("Protein (g)", value: $proteinPerUnit)
                numberField("Carbs (g)", value: $carbsPerUnit)
                numberField("Fat (g)", value: $fatPerUnit)
            }

            Section("Allergen Tags") {
                ForEach(FoodTag.allergens, id: \.self) { tag in
                    Toggle(tag.rawValue.capitalized, isOn: Binding(
                        get: { tags.contains(tag) },
                        set: { on in
                            if on { tags.insert(tag) }
                            else { tags.remove(tag) }
                        }
                    ))
                }
            }

            if let existing = existingFood, !existing.isStarter {
                Section {
                    Button("Delete Food", role: .destructive) {
                        Task {
                            try? await mealStore.deleteFood(id: existing.id)
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New Food" : "Edit Food")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(name.isEmpty || isSaving)
            }
        }
        .onAppear {
            if let f = existingFood {
                name = f.name
                brand = f.brand ?? ""
                unit = FoodServingUnit.forKind(f.servingKind, legacy: f.unit)
                kcalPerUnit = f.kcalPerUnit
                proteinPerUnit = f.proteinPerUnit
                carbsPerUnit = f.carbsPerUnit
                fatPerUnit = f.fatPerUnit
                category = f.category
                tags = f.tags
            }
        }
    }

    @ViewBuilder
    private func numberField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let food = FoodItem(
            id: existingFood?.id ?? UUID().uuidString,
            name: name,
            brand: brand.isEmpty ? nil : brand,
            unit: unit.rawValue,
            kcalPerUnit: kcalPerUnit,
            proteinPerUnit: proteinPerUnit,
            carbsPerUnit: carbsPerUnit,
            fatPerUnit: fatPerUnit,
            isStarter: existingFood?.isStarter ?? false,
            tags: tags,
            category: category,
            createdAt: existingFood?.createdAt ?? .now,
            updatedAt: .now
        )
        if isNew {
            try? await mealStore.insertFood(food)
        } else {
            try? await mealStore.updateFood(food)
        }
        dismiss()
    }
}
