import Foundation
import SwiftData
import SwiftUI

/// A view that lets the user paste a recipe URL and attempts to import it.
struct AddRecipeByURLView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var urlString: String = ""
  @State private var isLoading = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationView {
      Form {
        Section("Recipe URL") {
          TextField("https://example.com/recipe", text: $urlString)
            .keyboardType(.URL)
            .textContentType(.URL)
            .autocapitalization(.none)
        }

        Section {
          Button(action: { Task { await importFromURL() } }) {
            HStack {
              if isLoading { ProgressView().controlSize(.small) }
              Text("Import")
            }
          }
          .disabled(isLoading || urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }

        if let err = errorMessage {
          Section("Error") {
            Text(err)
              .foregroundColor(.red)
          }
        }
      }
      .navigationTitle("Import Recipe")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
  }

  // MARK: - Import Flow

  private func setError(_ text: String) {
    DispatchQueue.main.async { errorMessage = text }
  }

  private func importFromURL() async {
    errorMessage = nil
    guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
      setError("Invalid URL")
      return
    }

    isLoading = true
    defer { isLoading = false }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      let contentType =
        (response as? HTTPURLResponse)?
        .value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""

      if contentType.contains("application/json") {
        if let recipe = try RecipeImportService.parseJSONRecipeData(data) {
          modelContext.insert(recipe)
          dismiss()
          return
        }
      }

      // Try HTML parsing via the parsing service (which uses SwiftSoup)
      if let html = String(data: data, encoding: .utf8) {
        if let jsonLDRecipe = try RecipeImportService.extractRecipeFromJSONLDScripts(html: html) {
          modelContext.insert(jsonLDRecipe)
          dismiss()
          return
        }

        if let microRecipe = try RecipeImportService.extractRecipeFromMicrodata(
          html: html, sourceURL: url)
        {
          modelContext.insert(microRecipe)
          dismiss()
          return
        }

        // Fallback: title + URL
        let title =
          RecipeImportService.extractTitleFromHTML(html: html) ?? url.host ?? "Imported Recipe"
        let recipe = Recipe(
          name: title,
          cuisine: "",
          cookTime: 30,
          difficulty: "Medium",
          ingredients: ["Imported from \(url.host ?? "source")"],
          instructions: ["Open the URL to view instructions: \(url.absoluteString)"],
          imageName: ""
        )
        modelContext.insert(recipe)
        dismiss()
        return
      }

      setError("Unable to load content from URL")
    } catch {
      setError(error.localizedDescription)
    }
  }

  // Parsers delegated to `RecipeImportService` in Services/RecipeImportService.swift
}

// Preview helper
#Preview {
  AddRecipeByURLView()
}
