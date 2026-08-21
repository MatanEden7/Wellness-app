import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

public struct MealEditorScreen: View {
    @Environment(MealFeatureStore.self) private var mealStore
    @Environment(\.dismiss) private var dismiss

    let editingMealId: String?

    @State private var name = ""
    @State private var note = ""
    @State private var date: Date = .now
    @State private var items: [MealItem] = []
    @State private var showFoodSelector = false
    @State private var isSaving = false

    private var isNew: Bool { editingMealId == nil }

    public init(mealId: String? = nil) {
        self.editingMealId = mealId
    }

    public var body: some View {
        Form {
            Section {
                TextField("Meal Name", text: $name)
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                TextField("Note", text: $note, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                NutritionSummaryRow(
                    kcal: items.reduce(0) { $0 + $1.kcal },
                    protein: items.reduce(0) { $0 + $1.protein },
                    carbs: items.reduce(0) { $0 + $1.carbs },
                    fat: items.reduce(0) { $0 + $1.fat }
                )
            }

            Section("Foods") {
                if items.isEmpty {
                    Text("No foods added yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        MealItemRow(item: item, food: mealStore.food(byId: item.foodId))
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
        }
        .navigationTitle(isNew ? "New Meal" : "Edit Meal")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(name.isEmpty || isSaving)
            }
        }
        .sheet(isPresented: $showFoodSelector) {
            NavigationStack {
                FoodSelectorSheet { item in
                    items.append(item)
                }
            }
        }
        .task {
            await mealStore.loadFoods()
            if let id = editingMealId, let meal = await mealStore.meal(byId: id) {
                name = meal.name
                note = meal.note ?? ""
                date = MealFeatureStore.date(from: meal.date)
                items = meal.items
            } else if name.isEmpty {
                name = defaultMealName()
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let dateInt = MealFeatureStore.dateInt(from: date)
        let mealId = editingMealId ?? UUID().uuidString
        let updatedItems = items.map { item in
            var copy = item
            copy.mealId = mealId
            return copy
        }
        let meal = Meal(
            id: mealId, date: dateInt, name: name,
            note: note.isEmpty ? nil : note,
            loggedAt: .now, items: updatedItems
        )
        if isNew {
            try? await mealStore.addMeal(meal)
        } else {
            try? await mealStore.updateMeal(meal)
        }
        dismiss()
    }

    private func defaultMealName() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<11:  return "Breakfast"
        case 11..<14: return "Lunch"
        case 14..<17: return "Snack"
        case 17..<22: return "Dinner"
        default:      return "Late Snack"
        }
    }
}

struct MealItemRow: View {
    let item: MealItem
    let food: FoodItem?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food?.name ?? "Unknown Food")
                    .font(.body)
                if let food {
                    Text(FoodNutritionMath.formatAmountLine(food, storedQuantity: item.amount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(Int(item.kcal)) kcal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
