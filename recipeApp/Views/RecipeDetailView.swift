import SwiftData
import SwiftUI

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
  @Bindable var recipe: Recipe
  @State private var showingEditSheet = false

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
