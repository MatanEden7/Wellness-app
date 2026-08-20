import Testing
import WellnessCatalog
import WellnessModels

@Test func foodCatalogLoads() {
    let foods = Catalog.foods
    #expect(foods.count == 235)
    #expect(foods.first?.id == "1")
    #expect(foods.first?.name == "Chicken Breast")
}

@Test func exerciseCatalogLoads() {
    let exercises = Catalog.exercises
    #expect(exercises.count == 115)
    #expect(exercises.first?.id == "1")
    #expect(exercises.first?.name == "Push-ups")
}

@Test func foodToFoodItemEnglish() {
    let food = Catalog.foods.first!
    let item = food.toFoodItem(language: .english)
    #expect(item.name == "Chicken Breast")
    #expect(item.isStarter == true)
    #expect(item.category == .protein)
}

@Test func exerciseToExerciseHebrew() {
    let exercise = Catalog.exercises.first!
    let ex = exercise.toExercise(language: .hebrew)
    #expect(ex.name == "שכיבות סמיכה")
    #expect(ex.primaryMuscle == "חזה")
}
