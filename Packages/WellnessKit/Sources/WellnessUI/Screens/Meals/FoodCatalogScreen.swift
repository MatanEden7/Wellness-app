import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

public struct FoodCatalogScreen: View {
    @Environment(MealFeatureStore.self) private var mealStore

    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @State private var showStarter = true
    @State private var editingFood: FoodItem?
    @State private var showNewFood = false

    public init() {}

    public var body: some View {
        List {
            Picker("Source", selection: $showStarter) {
                Text("All").tag(true)
                Text("Custom").tag(false)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .padding(.horizontal)

            ForEach(filteredFoods) { food in
                Button {
                    editingFood = food
                } label: {
                    FoodRow(food: food)
                }
                .tint(.primary)
                .swipeActions(edge: .trailing) {
                    if !food.isStarter {
                        Button(role: .destructive) {
                            Task { try? await mealStore.deleteFood(id: food.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Foods")
        .searchable(text: $searchText, prompt: "Search foods")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showNewFood = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingFood) { food in
            NavigationStack {
                FoodEditorSheet(food: food)
            }
        }
        .sheet(isPresented: $showNewFood) {
            NavigationStack {
                FoodEditorSheet(food: nil)
            }
        }
        .task { await mealStore.loadFoods() }
    }

    private var filteredFoods: [FoodItem] {
        var result = mealStore.foods
        if !showStarter {
            result = result.filter { !$0.isStarter }
        }
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }
        return result
    }
}
