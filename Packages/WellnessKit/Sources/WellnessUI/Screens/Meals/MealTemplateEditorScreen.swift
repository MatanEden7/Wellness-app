import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

public struct MealTemplateEditorScreen: View {
    @Environment(MealFeatureStore.self) private var mealStore
    @Environment(\.dismiss) private var dismiss

    let editingTemplateId: String?

    @State private var name = ""
    @State private var descriptionText = ""
    @State private var items: [MealTemplateItem] = []
    @State private var showFoodSelector = false
    @State private var isSaving = false

    private var isNew: Bool { editingTemplateId == nil }

    public init(templateId: String? = nil) {
        self.editingTemplateId = templateId
    }

    public var body: some View {
        Form {
            Section {
                TextField("Template Name", text: $name)
                TextField("Description (optional)", text: $descriptionText, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Foods") {
                if items.isEmpty {
                    Text("No foods added yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        templateItemRow(item)
                    }
                    .onDelete { indices in
                        items.remove(atOffsets: indices)
                    }
                }
                Button {
                    showFoodSelector = true
                } label: {
                    Label("Add Food", systemImage: "plus.circle")
                }
            }

            let macros = computeTotals()
            Section("Total Nutrition") {
                LabeledContent("Calories", value: "\(Int(macros.kcal)) kcal")
                LabeledContent("Protein", value: "\(Int(macros.protein))g")
                LabeledContent("Carbs", value: "\(Int(macros.carbs))g")
                LabeledContent("Fat", value: "\(Int(macros.fat))g")
            }
        }
        .navigationTitle(isNew ? "New Template" : "Edit Template")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(name.isEmpty || isSaving)
            }
        }
        .sheet(isPresented: $showFoodSelector) {
            NavigationStack {
                FoodSelectorSheet { mealItem in
                    let tItem = MealTemplateItem(
                        id: UUID().uuidString,
                        templateId: editingTemplateId ?? "",
                        foodId: mealItem.foodId,
                        amount: mealItem.amount
                    )
                    items.append(tItem)
                }
            }
        }
        .task {
            await mealStore.loadFoods()
            if let id = editingTemplateId,
               let template = mealStore.mealTemplates.first(where: { $0.id == id }) {
                name = template.name
                descriptionText = template.description ?? ""
                items = template.items
            }
        }
    }

    @ViewBuilder
    private func templateItemRow(_ item: MealTemplateItem) -> some View {
        let food = mealStore.food(byId: item.foodId)
        HStack {
            Text(food?.name ?? "Unknown")
            Spacer()
            if let food {
                Text(FoodNutritionMath.formatAmountLine(food, storedQuantity: item.amount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func computeTotals() -> NutritionMacros {
        var total = NutritionMacros.zero
        for item in items {
            if let food = mealStore.food(byId: item.foodId) {
                let m = FoodNutritionMath.computeMacros(food, storedQuantity: item.amount)
                total.kcal += m.kcal
                total.protein += m.protein
                total.carbs += m.carbs
                total.fat += m.fat
            }
        }
        return total
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let templateId = editingTemplateId ?? UUID().uuidString
        let updatedItems = items.map { item in
            var copy = item
            copy.templateId = templateId
            return copy
        }
        let template = MealTemplate(
            id: templateId,
            name: name,
            description: descriptionText.isEmpty ? nil : descriptionText,
            origin: .user,
            items: updatedItems
        )
        if isNew {
            try? await mealStore.insertMealTemplate(template)
        } else {
            try? await mealStore.updateMealTemplate(template)
        }
        dismiss()
    }
}
