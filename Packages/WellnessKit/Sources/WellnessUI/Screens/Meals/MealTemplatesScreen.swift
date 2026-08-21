import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

public struct MealTemplatesScreen: View {
    @Environment(MealFeatureStore.self) private var mealStore
    @Environment(\.dismiss) private var dismiss

    @State private var editingTemplate: MealTemplate?
    @State private var showNewTemplate = false

    public init() {}

    public var body: some View {
        List {
            if mealStore.mealTemplates.isEmpty {
                ContentUnavailableView(
                    "No Templates",
                    systemImage: "doc.text",
                    description: Text("Meal templates will appear here after setup or when you create them.")
                )
            } else {
                ForEach(mealStore.mealTemplates) { template in
                    MealTemplateRow(template: template) {
                        useTemplate(template)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { try? await mealStore.deleteMealTemplate(id: template.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingTemplate = template
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("Meal Templates")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                NavigationLink(value: AppRoute.mealTemplateEdit(id: nil)) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await mealStore.loadTemplates()
            await mealStore.loadFoods()
        }
    }

    private func useTemplate(_ template: MealTemplate) {
        let meal = mealStore.mealFromTemplate(template)
        Task {
            try? await mealStore.addMeal(meal)
            dismiss()
        }
    }
}

private struct MealTemplateRow: View {
    let template: MealTemplate
    let onUse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(template.name)
                    .font(.headline)
                Spacer()
                Button("Use Now", action: onUse)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            if let desc = template.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text("\(template.items.count) items")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
