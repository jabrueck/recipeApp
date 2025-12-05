import Foundation
import SwiftData
import SwiftSoup
import SwiftUI
import UIKit

struct ImportFromShareViewWithURL: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let initialURL: URL

  @State private var detectedURL: String
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var successMessage: String?
  @State private var detectedSource: String?

  init(initialURL: URL) {
    self.initialURL = initialURL
    _detectedURL = State(initialValue: initialURL.absoluteString)
  }

  var body: some View {
    NavigationView {
      Form {
        Section("Recipe URL") {
          HStack {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 4) {
              Text(detectedSource ?? "Recipe Link")
                .font(.headline)
              Text(detectedURL)
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.secondary)
            }
            Spacer()
          }
          .padding(.vertical, 8)
        }

        Section {
          Button(action: { Task { await importFromShare() } }) {
            HStack {
              if isLoading { ProgressView().controlSize(.small) }
              Text("Import Recipe")
                .fontWeight(.semibold)
            }
          }
          .disabled(isLoading)
        }

        if let err = errorMessage {
          Section("Error") {
            HStack {
              Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
              Text(err)
                .foregroundColor(.red)
            }
          }
        }

        if let success = successMessage {
          Section("Success") {
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
              Text(success)
                .foregroundColor(.green)
            }
          }
        }
      }
      .navigationTitle("Import Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .onAppear {
        updateSourceDetection()
      }
    }
  }

  private func updateSourceDetection() {
    if let url = URL(string: detectedURL) {
      detectedSource = url.host
      errorMessage = nil
    }
  }

  private func importFromShare() async {
    errorMessage = nil
    successMessage = nil

    guard var url = URL(string: detectedURL) else {
      errorMessage = "Invalid URL format"
      return
    }

    isLoading = true
    defer { isLoading = false }

    do {
      let config = URLSessionConfiguration.default
      config.timeoutIntervalForRequest = 15
      config.timeoutIntervalForResource = 60
      let session = URLSession(configuration: config)

      let (data, response) = try await session.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        errorMessage = "Failed to load URL"
        return
      }

      if let html = String(data: data, encoding: .utf8) {
        // Try JSON-LD first
        if let recipe = try RecipeImportService.extractRecipeFromJSONLDScripts(html: html) {
          modelContext.insert(recipe)
          successMessage = "Recipe imported: \(recipe.name)"
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
          }
          return
        }

        // Try microdata
        if let recipe = try RecipeImportService.extractRecipeFromMicrodata(
          html: html, sourceURL: url)
        {
          modelContext.insert(recipe)
          successMessage = "Recipe imported: \(recipe.name)"
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
          }
          return
        }

        // Try Jina API
        if let recipe = await fetchRecipeViaJina(url: url) {
          modelContext.insert(recipe)
          successMessage = "Recipe imported: \(recipe.name)"
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
          }
          return
        }

        errorMessage = "Could not extract recipe data"
      }
    } catch {
      errorMessage = "Error: \(error.localizedDescription)"
    }
  }

  private func fetchRecipeViaJina(url: URL) async -> Recipe? {
    guard let jinaURL = URL(string: "https://r.jina.ai/\(url.absoluteString)") else {
      return nil
    }

    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 15
    config.timeoutIntervalForResource = 60
    let session = URLSession(configuration: config)

    do {
      let (data, response) = try await session.data(from: jinaURL)

      guard let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        return nil
      }

      guard let markdown = String(data: data, encoding: .utf8) else {
        return nil
      }

      return parseRecipeFromMarkdown(markdown: markdown, sourceURL: url)
    } catch {
      return nil
    }
  }

  private func parseRecipeFromMarkdown(markdown: String, sourceURL: URL) -> Recipe? {
    let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

    let title: String = {
      for line in lines.prefix(10) {
        if line.starts(with: "# ") {
          return String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }
      }
      return sourceURL.host ?? "Imported Recipe"
    }()

    var ingredients: [String] = []
    var instructionLines: [String] = []
    var currentSection = ""

    for line in lines {
      let lowerLine = line.lowercased()

      if lowerLine.contains("ingredient") && (lowerLine.contains("##") || lowerLine.contains("**"))
      {
        currentSection = "ingredients"
        continue
      }

      if (lowerLine.contains("instruction") || lowerLine.contains("direction")
        || lowerLine.contains("step"))
        && (lowerLine.contains("##") || lowerLine.contains("**"))
      {
        currentSection = "instructions"
        continue
      }

      if currentSection == "ingredients" {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty
          && (trimmed.starts(with: "-") || trimmed.starts(with: "*")
            || trimmed.first?.isNumber == true)
        {
          let cleaned = trimmed.replacingOccurrences(
            of: "^[-*\\d.]+\\s*", with: "", options: .regularExpression)
          if !cleaned.isEmpty && cleaned.count > 2 {
            ingredients.append(cleaned)
          }
        }
      }

      if currentSection == "instructions" {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !trimmed.starts(with: "##") && !trimmed.starts(with: "**")
          && !trimmed.starts(with: "[") && trimmed.count > 10
        {
          let cleaned =
            trimmed
            .replacingOccurrences(of: "^[-*\\d.]+\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\*\\*", with: "")
            .trimmingCharacters(in: .whitespaces)

          if !cleaned.isEmpty && cleaned.count > 10 {
            instructionLines.append(cleaned)
          }
        }
      }
    }

    if ingredients.isEmpty && instructionLines.isEmpty {
      return nil
    }

    return Recipe(
      name: title,
      cuisine: "",
      cookTime: 30,
      difficulty: "Medium",
      ingredients: ingredients.isEmpty ? ["See recipe at source"] : Array(ingredients.prefix(50)),
      instructions: instructionLines.isEmpty
        ? ["See recipe at source"] : Array(instructionLines.prefix(50)),
      imageName: ""
    )
  }
}
