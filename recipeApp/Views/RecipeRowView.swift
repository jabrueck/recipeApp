import SwiftUI

// MARK: - Recipe Row View
// Compact row used inside the recipe list.
struct RecipeRowView: View {
  let recipe: Recipe

  var body: some View {
    HStack(spacing: 12) {
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
