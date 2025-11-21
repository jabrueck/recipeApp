import SwiftData
import SwiftUI

// Thin wrapper - forwards to the modular `RecipeListView`.
struct ContentView: View {
  var body: some View {
    RecipeListView()
  }
}

// Preview with an in-memory model container for SwiftData
#Preview {
  ContentView()
    .modelContainer(for: Recipe.self, inMemory: true)
}
