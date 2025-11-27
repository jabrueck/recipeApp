import SwiftData
import SwiftUI

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
  @Bindable var recipe: Recipe
  @State private var showingEditSheet = false
  @State private var selectedTab: Tab = .ingredients
  @State private var completedIngredients: Set<String> = []
  @State private var selectedInstruction: Int? = nil

  enum Tab {
    case ingredients
    case instructions
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.blue.opacity(0.3))
          .frame(height: 200)
          .overlay(
            Image(systemName: "fork.knife.circle.fill")
              .font(.system(size: 60))
              .foregroundColor(.blue)
          )

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(recipe.name)
              .font(.title)
              .bold()

            Spacer()

            Button(action: {
              recipe.isFavorite.toggle()
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

        Picker("", selection: $selectedTab) {
          Text("Ingredients").tag(Tab.ingredients)
          Text("Instructions").tag(Tab.instructions)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)

        if selectedTab == .ingredients {
          VStack(alignment: .leading, spacing: 12) {
            ForEach(recipe.ingredients, id: \.self) { ingredient in
              HStack {
                Image(systemName: "circle.fill")
                  .font(.system(size: 6))
                  .foregroundColor(.blue)
                Text(ingredient)
                  .strikethrough(completedIngredients.contains(ingredient))
                  .foregroundColor(
                    completedIngredients.contains(ingredient) ? .secondary : .primary)
              }
              .contentShape(Rectangle())
              .onTapGesture {
                if completedIngredients.contains(ingredient) {
                  completedIngredients.remove(ingredient)
                } else {
                  completedIngredients.insert(ingredient)
                }
              }
            }
          }
          .padding(.horizontal)
        } else {
          VStack(alignment: .leading, spacing: 12) {
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
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(12)
              .background(selectedInstruction == index ? Color.blue.opacity(0.2) : Color.clear)
              .cornerRadius(8)
              .contentShape(Rectangle())
              .onTapGesture {
                selectedInstruction = selectedInstruction == index ? nil : index
              }
            }
          }
          .padding(.horizontal)
        }

        Spacer()
      }
      .padding(.bottom, 20)
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
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
