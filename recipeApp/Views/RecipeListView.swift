import SwiftData
import SwiftUI

// MARK: - Recipe List View
// Root view presenting a searchable list of recipes.
struct RecipeListView: View {
  @Environment(\.modelContext) private var modelContext

  // @Query automatically fetches all recipes from the database
  @Query(sort: \Recipe.dateCreated, order: .reverse) private var recipes: [Recipe]

  @State private var searchText = ""
  @State private var showingAddRecipe = false
  @State private var showingImportByURL = false
  @State private var showingImportFromShare = false
  @State private var selectedLetter: String? = nil
  @State private var isEditingList = false
  @State private var isEditingTitle = false
  @State private var listTitle = "My Recipes"

  let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) })

  var availableLetters: Set<String> {
    Set(
      recipes.compactMap { recipe in
        recipe.name.uppercased().first.map { String($0) }
      })
  }

  var filteredRecipes: [Recipe] {
    var filtered = recipes

    if let letter = selectedLetter {
      filtered = filtered.filter { recipe in
        recipe.name.uppercased().first == Character(letter)
      }
    }

    if !searchText.isEmpty {
      filtered = filtered.filter { recipe in
        recipe.name.localizedCaseInsensitiveContains(searchText)
          || recipe.cuisine.localizedCaseInsensitiveContains(searchText)
      }
    }

    return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  var body: some View {
    NavigationView {
      ZStack(alignment: .trailing) {
        List {
          ForEach(filteredRecipes) { recipe in
            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
              RecipeRowView(recipe: recipe)
            }
          }
          .onDelete(perform: deleteRecipes)
        }
        .navigationTitle(isEditingTitle ? "" : listTitle)
        .searchable(text: $searchText, prompt: "Search recipes")
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            if isEditingTitle {
              Button("Done") {
                isEditingTitle = false
              }
            } else if isEditingList {
              Button("Done") {
                isEditingList = false
              }
            } else {
              Button("Edit") {
                isEditingList = true
              }
            }
            Button(action: { showingImportFromShare = true }) {
              Image(systemName: "square.and.arrow.up")
            }
            Button(action: { showingImportByURL = true }) {
              Image(systemName: "link")
            }
            Button(action: { showingAddRecipe = true }) {
              Image(systemName: "plus")
            }
          }

          ToolbarItem(placement: .principal) {
            if isEditingTitle {
              TextField("List Title", text: $listTitle)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)
            }
          }
        }
        .environment(\.editMode, isEditingList ? .constant(.active) : .constant(.inactive))
        .sheet(isPresented: $showingAddRecipe) {
          AddRecipeView()
        }
        .sheet(isPresented: $showingImportByURL) {
          AddRecipeByURLView()
        }
        .sheet(isPresented: $showingImportFromShare) {
          ImportFromShareView()
        }
        .overlay {
          if recipes.isEmpty {
            ContentUnavailableView(
              "No Recipes Yet",
              systemImage: "fork.knife",
              description: Text("Tap + to add your first recipe")
            )
          }
        }

        // Alphabet Index on the right - only show letters with recipes
        if !isEditingList && !isEditingTitle {
          VStack(spacing: 2) {
            ForEach(alphabet, id: \.self) { letter in
              if availableLetters.contains(letter) {
                Text(letter)
                  .font(.system(size: 10, weight: .semibold))
                  .foregroundColor(selectedLetter == letter ? .blue : .gray)
                  .frame(width: 20, height: 16)
                  .contentShape(Rectangle())
                  .onTapGesture {
                    selectedLetter = selectedLetter == letter ? nil : letter
                  }
              }
            }
          }
          .padding(.trailing, 8)
          .padding(.vertical, 8)
        }
      }
    }
    .onAppear {
      if recipes.isEmpty {
        addSampleRecipes()
      }
    }
  }

  private func deleteRecipes(at offsets: IndexSet) {
    for index in offsets {
      let recipe = filteredRecipes[index]
      modelContext.delete(recipe)
    }
  }

  // Sample data inserter copied from original ContentView
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

    modelContext.insert(pizza)
    modelContext.insert(stirfry)
    modelContext.insert(cookies)
  }
}

// Preview
#Preview {
  RecipeListView()
    .modelContainer(for: Recipe.self, inMemory: true)
}
