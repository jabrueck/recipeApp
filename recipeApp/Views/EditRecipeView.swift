import SwiftUI
import SwiftData

// MARK: - Edit Recipe View
struct EditRecipeView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var recipe: Recipe

  @State private var name: String
  @State private var cuisine: String
  @State private var cookTime: Int
  @State private var difficulty: String
  @State private var ingredients: [String]
  @State private var instructions: [String]

  let difficulties = ["Easy", "Medium", "Hard"]

  init(recipe: Recipe) {
    self.recipe = recipe
    _name = State(initialValue: recipe.name)
    _cuisine = State(initialValue: recipe.cuisine)
    _cookTime = State(initialValue: recipe.cookTime)
    _difficulty = State(initialValue: recipe.difficulty)
    _ingredients = State(initialValue: recipe.ingredients)
    _instructions = State(initialValue: recipe.instructions)
  }

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
          .onDelete { offsets in
            ingredients.remove(atOffsets: offsets)
          }

          Button("Add Ingredient") { ingredients.append("") }
        }

        Section("Instructions") {
          ForEach(instructions.indices, id: \.self) { index in
            TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
              .lineLimit(3...6)
          }
          .onDelete { offsets in
            instructions.remove(atOffsets: offsets)
          }

          Button("Add Step") { instructions.append("") }
        }
      }
      .navigationTitle("Edit Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) { Button("Save") { saveChanges() }.disabled(name.isEmpty) }
      }
    }
  }

  private func saveChanges() {
    recipe.name = name
    recipe.cuisine = cuisine
    recipe.cookTime = cookTime
    recipe.difficulty = difficulty
    recipe.ingredients = ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    recipe.instructions = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

    dismiss()
  }
}
