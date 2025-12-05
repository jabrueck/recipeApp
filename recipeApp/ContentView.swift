import SwiftData
import SwiftUI

struct ContentView: View {
  @Binding var incomingURL: URL?
  @Binding var showImportFromShare: Bool

  var body: some View {
    RecipeListView()
      .sheet(isPresented: $showImportFromShare) {
        if let url = incomingURL {
          ImportFromShareViewWithURL(initialURL: url)
        }
      }
  }
}

#Preview {
  ContentView(incomingURL: .constant(nil), showImportFromShare: .constant(false))
    .modelContainer(for: Recipe.self, inMemory: true)
}
