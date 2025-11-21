import SwiftData
import SwiftUI

// MARK: - Add Recipe View
struct AddRecipeView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var cuisine = ""
  @State private var cookTime = 30
  @State private var difficulty = "Easy"
  @State private var ingredients = [""]
  @State private var instructions = [""]

  let difficulties = ["Easy", "Medium", "Hard"]

  var body: some View {
    NavigationView {
      Form {
        Section("Basic Info") {
          TextField("Recipe Name", text: $name)
          TextField("Cuisine", text: $cuisine)

          Stepper("Cook Time: \(cookTime) min", value: $cookTime, in: 5...300, step: 5)

          Picker("Difficulty", selection: $difficulty) {
            ForEach(difficulties, id: \.self) { difficulty in
              Text(difficulty)
            }
          }
        }

        Section("Ingredients") {
          ForEach(ingredients.indices, id: \.self) { index in
            TextField("Ingredient \(index + 1)", text: $ingredients[index])
          }

          Button("Add Ingredient") {
            ingredients.append("")
          }
        }

        Section("Instructions") {
          ForEach(instructions.indices, id: \.self) { index in
            TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
              .lineLimit(3...6)
          }

          Button("Add Step") {
            instructions.append("")
          }
        }
      }
      .navigationTitle("New Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { saveRecipe() }
            .disabled(name.isEmpty)
        }
      }
    }
  }

  private func saveRecipe() {
    let cleanIngredients = ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    let cleanInstructions = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

    let newRecipe = Recipe(
      name: name,
      cuisine: cuisine,
      cookTime: cookTime,
      difficulty: difficulty,
      ingredients: cleanIngredients,
      instructions: cleanInstructions
    )

    modelContext.insert(newRecipe)
    dismiss()
  }
}
