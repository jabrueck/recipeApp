import SwiftData
import SwiftUI

// MARK: - Data Model
// @Model is a SwiftData macro that makes this class persistable to disk
// SwiftData automatically creates a database and saves/loads this data
@Model
class Recipe {
  // SwiftData automatically handles the ID, we don't need to add one manually
  var name: String
  var cuisine: String
  var cookTime: Int  // in minutes
  var difficulty: String
  var ingredients: [String]  // Arrays work fine in SwiftData
  var instructions: [String]
  var imageName: String
  var isFavorite: Bool  // New property for marking favorites
  var dateCreated: Date  // Tracks when recipe was added

  // Initializer - required for creating new Recipe objects
  init(
    name: String, cuisine: String, cookTime: Int, difficulty: String,
    ingredients: [String], instructions: [String], imageName: String = "",
    isFavorite: Bool = false
  ) {
    self.name = name
    self.cuisine = cuisine
    self.cookTime = cookTime
    self.difficulty = difficulty
    self.ingredients = ingredients
    self.instructions = instructions
    self.imageName = imageName
    self.isFavorite = isFavorite
    self.dateCreated = Date()
  }
}

// MARK: - Main Content View (Recipe List)
struct ContentView: View {
  // @Environment accesses the SwiftData model context (think of it as the database connection)
  @Environment(\.modelContext) private var modelContext

  // @Query automatically fetches all recipes from the database
  // The sort parameter orders them by date (newest first)
  @Query(sort: \Recipe.dateCreated, order: .reverse) private var recipes: [Recipe]

  @State private var searchText = ""
  @State private var showingAddRecipe = false  // Controls showing the add recipe sheet

  // Computed property - filters recipes based on search text
  var filteredRecipes: [Recipe] {
    if searchText.isEmpty {
      return recipes
    } else {
      return recipes.filter { recipe in
        recipe.name.localizedCaseInsensitiveContains(searchText)
          || recipe.cuisine.localizedCaseInsensitiveContains(searchText)
      }
    }
  }

  var body: some View {
    NavigationView {
      List {
        ForEach(filteredRecipes) { recipe in
          NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
            RecipeRowView(recipe: recipe)
          }
        }
        // .onDelete enables swipe-to-delete functionality
        .onDelete(perform: deleteRecipes)
      }
      .navigationTitle("My Recipes")
      .searchable(text: $searchText, prompt: "Search recipes")
      .toolbar {
        // Add button in the top right corner
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { showingAddRecipe = true }) {
            Image(systemName: "plus")
          }
        }
      }
      // .sheet presents a modal view (slides up from bottom)
      .sheet(isPresented: $showingAddRecipe) {
        AddRecipeView()
      }
      // Show message if no recipes exist
      .overlay {
        if recipes.isEmpty {
          ContentUnavailableView(
            "No Recipes Yet",
            systemImage: "fork.knife",
            description: Text("Tap + to add your first recipe")
          )
        }
      }
    }
    // When view appears, add sample recipes if database is empty
    .onAppear {
      if recipes.isEmpty {
        addSampleRecipes()
      }
    }
  }

  // Function to delete recipes - called when user swipes to delete
  private func deleteRecipes(at offsets: IndexSet) {
    for index in offsets {
      let recipe = filteredRecipes[index]
      modelContext.delete(recipe)  // Delete from database
    }
  }

  // Function to add sample recipes on first launch
  private func addSampleRecipes() {
    let pizza = Recipe(
      name: "Classic Margherita Pizza",
      cuisine: "Italian",
      cookTime: 25,
      difficulty: "Easy",
      ingredients: [
        "Pizza dough",
        "2 cups tomato sauce",
        "2 cups mozzarella cheese",
        "Fresh basil leaves",
        "2 tbsp olive oil",
        "Salt to taste",
      ],
      instructions: [
        "Preheat oven to 475°F (245°C)",
        "Roll out pizza dough on floured surface",
        "Spread tomato sauce evenly over dough",
        "Sprinkle mozzarella cheese on top",
        "Bake for 12-15 minutes until crust is golden",
        "Remove from oven and add fresh basil",
        "Drizzle with olive oil and serve",
      ]
    )

    let stirfry = Recipe(
      name: "Chicken Stir Fry",
      cuisine: "Asian",
      cookTime: 20,
      difficulty: "Easy",
      ingredients: [
        "1 lb chicken breast, sliced",
        "2 cups mixed vegetables",
        "3 tbsp soy sauce",
        "2 cloves garlic, minced",
        "1 tbsp ginger, grated",
        "2 tbsp vegetable oil",
      ],
      instructions: [
        "Heat oil in a large wok or pan over high heat",
        "Add chicken and cook until browned (5 mins)",
        "Add garlic and ginger, stir for 30 seconds",
        "Add vegetables and stir fry for 3-4 minutes",
        "Pour in soy sauce and toss everything together",
        "Serve hot over rice",
      ]
    )

    let cookies = Recipe(
      name: "Chocolate Chip Cookies",
      cuisine: "American",
      cookTime: 30,
      difficulty: "Easy",
      ingredients: [
        "2 1/4 cups all-purpose flour",
        "1 cup butter, softened",
        "3/4 cup sugar",
        "2 eggs",
        "2 cups chocolate chips",
        "1 tsp vanilla extract",
        "1 tsp baking soda",
      ],
      instructions: [
        "Preheat oven to 375°F (190°C)",
        "Mix butter and sugar until creamy",
        "Beat in eggs and vanilla",
        "Combine flour and baking soda, then mix into butter mixture",
        "Stir in chocolate chips",
        "Drop spoonfuls onto baking sheet",
        "Bake 9-11 minutes until golden brown",
      ]
    )

    // Insert all sample recipes into the database
    modelContext.insert(pizza)
    modelContext.insert(stirfry)
    modelContext.insert(cookies)
  }
}

// MARK: - Recipe Row View
struct RecipeRowView: View {
  let recipe: Recipe

  var body: some View {
    HStack(spacing: 12) {
      // Placeholder image
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.blue.opacity(0.3))
        .frame(width: 60, height: 60)
        .overlay(
          Image(systemName: "fork.knife")
            .foregroundColor(.blue)
        )

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(recipe.name)
            .font(.headline)

          // Show star icon if recipe is favorited
          if recipe.isFavorite {
            Image(systemName: "star.fill")
              .font(.caption)
              .foregroundColor(.yellow)
          }
        }

        HStack {
          Text(recipe.cuisine)
            .font(.subheadline)
            .foregroundColor(.secondary)

          Text("•")
            .foregroundColor(.secondary)

          HStack(spacing: 2) {
            Image(systemName: "clock")
              .font(.caption)
            Text("\(recipe.cookTime) min")
              .font(.subheadline)
          }
          .foregroundColor(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
  // @Bindable allows us to modify the recipe and have changes save automatically
  @Bindable var recipe: Recipe
  @State private var showingEditSheet = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // Header Image
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.blue.opacity(0.3))
          .frame(height: 200)
          .overlay(
            Image(systemName: "fork.knife.circle.fill")
              .font(.system(size: 60))
              .foregroundColor(.blue)
          )

        // Recipe Info
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(recipe.name)
              .font(.title)
              .bold()

            Spacer()

            // Favorite button - tapping toggles isFavorite
            Button(action: {
              recipe.isFavorite.toggle()
              // SwiftData automatically saves changes!
            }) {
              Image(systemName: recipe.isFavorite ? "star.fill" : "star")
                .font(.title2)
                .foregroundColor(recipe.isFavorite ? .yellow : .gray)
            }
          }

          HStack(spacing: 20) {
            InfoBadge(icon: "globe", text: recipe.cuisine)
            InfoBadge(icon: "clock", text: "\(recipe.cookTime) min")
            InfoBadge(icon: "chart.bar", text: recipe.difficulty)
          }
        }
        .padding(.horizontal)

        Divider()

        // Ingredients Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Ingredients")
            .font(.title2)
            .bold()

          ForEach(recipe.ingredients, id: \.self) { ingredient in
            HStack {
              Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.blue)
              Text(ingredient)
            }
          }
        }
        .padding(.horizontal)

        Divider()

        // Instructions Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Instructions")
            .font(.title2)
            .bold()

          ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
            HStack(alignment: .top, spacing: 12) {
              Text("\(index + 1)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

              Text(instruction)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      // Edit button in navigation bar
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Edit") {
          showingEditSheet = true
        }
      }
    }
    .sheet(isPresented: $showingEditSheet) {
      EditRecipeView(recipe: recipe)
    }
  }
}

// MARK: - Add Recipe View
struct AddRecipeView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss  // Used to close the sheet

  // @State variables hold the form input values
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
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveRecipe()
          }
          .disabled(name.isEmpty)  // Disable if name is empty
        }
      }
    }
  }

  private func saveRecipe() {
    // Filter out empty ingredients and instructions
    let cleanIngredients = ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    let cleanInstructions = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

    // Create new recipe object
    let newRecipe = Recipe(
      name: name,
      cuisine: cuisine,
      cookTime: cookTime,
      difficulty: difficulty,
      ingredients: cleanIngredients,
      instructions: cleanInstructions
    )

    // Insert into database
    modelContext.insert(newRecipe)

    // Close the sheet
    dismiss()
  }
}

// MARK: - Edit Recipe View
struct EditRecipeView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var recipe: Recipe

  // Create local copies for editing
  @State private var name: String
  @State private var cuisine: String
  @State private var cookTime: Int
  @State private var difficulty: String
  @State private var ingredients: [String]
  @State private var instructions: [String]

  let difficulties = ["Easy", "Medium", "Hard"]

  // Custom initializer to set initial state from recipe
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

          Button("Add Ingredient") {
            ingredients.append("")
          }
        }

        Section("Instructions") {
          ForEach(instructions.indices, id: \.self) { index in
            TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
              .lineLimit(3...6)
          }
          .onDelete { offsets in
            instructions.remove(atOffsets: offsets)
          }

          Button("Add Step") {
            instructions.append("")
          }
        }
      }
      .navigationTitle("Edit Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveChanges()
          }
          .disabled(name.isEmpty)
        }
      }
    }
  }

  private func saveChanges() {
    // Update recipe with new values
    recipe.name = name
    recipe.cuisine = cuisine
    recipe.cookTime = cookTime
    recipe.difficulty = difficulty
    recipe.ingredients = ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    recipe.instructions = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

    // SwiftData automatically saves changes!
    dismiss()
  }
}

// MARK: - Info Badge Component
struct InfoBadge: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.caption)
      Text(text)
        .font(.subheadline)
    }
    .foregroundColor(.secondary)
  }
}

// MARK: - Preview
#Preview {
  ContentView()
    // Preview needs a model container to work with SwiftData
    .modelContainer(for: Recipe.self, inMemory: true)
}
