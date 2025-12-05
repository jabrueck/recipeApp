import Foundation
import SwiftData
import SwiftSoup
import SwiftUI
import UIKit

struct ImportFromShareView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var detectedURL: String = ""
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var successMessage: String?
  @State private var detectedSource: String?
  @State private var showManualInput = false

  var body: some View {
    NavigationView {
      ZStack {
        Form {
          if !detectedURL.isEmpty {
            Section("Clipboard URL Detected") {
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
                  Text("Import This Recipe")
                    .fontWeight(.semibold)
                }
              }
              .disabled(isLoading)

              Button(action: { showManualInput = true }) {
                Text("Cancel & Paste Different URL")
              }
              .buttonStyle(.bordered)
            }
          } else {
            Section {
              VStack(spacing: 16) {
                Image(systemName: "clipboard.fill")
                  .font(.system(size: 48))
                  .foregroundColor(.blue)

                VStack(spacing: 8) {
                  Text("No Recipe URL Found")
                    .font(.headline)
                  Text("Copy a recipe link to your clipboard and come back, or paste one manually.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                }

                Button(action: { showManualInput = true }) {
                  Text("Paste URL Manually")
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 32)
            }
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

        if showManualInput {
          ManualURLInputView(
            isPresented: $showManualInput,
            onSubmit: { url in
              detectedURL = url
              updateSourceDetection()
              showManualInput = false
            }
          )
        }
      }
      .navigationTitle("Import from Share")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .onAppear {
        checkClipboard()
      }
    }
  }

  private func checkClipboard() {
    let pasteboard = UIPasteboard.general

    if let string = pasteboard.string {
      let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
      if isValidURLString(trimmed) {
        detectedURL = trimmed
        updateSourceDetection()
        return
      }
    }

    if let url = pasteboard.url?.absoluteString {
      let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
      if isValidURLString(trimmed) {
        detectedURL = trimmed
        updateSourceDetection()
        return
      }
    }
  }

  private func isValidURLString(_ urlString: String) -> Bool {
    guard urlString.hasPrefix("http://") || urlString.hasPrefix("https://") else {
      return false
    }

    guard let url = URL(string: urlString) else {
      return false
    }

    return isRecipeOrSocialMediaURL(url)
  }

  private func isRecipeOrSocialMediaURL(_ url: URL) -> Bool {
    let host = url.host?.lowercased() ?? ""

    let socialMediaPatterns = [
      "pinterest", "facebook", "fb", "twitter", "x.com", "instagram", "tiktok", "tik",
    ]
    if socialMediaPatterns.contains(where: { host.contains($0) }) {
      return true
    }

    let recipeSites = [
      "allrecipes", "epicurious", "foodnetwork", "seriouseats",
      "bbcgoodfood", "bonappetit", "food52", "tastingtable",
      "cooks.com", "recipe", "cooking", "chef",
    ]

    let combined = "\(host) \(url.path.lowercased())"
    return recipeSites.contains { pattern in
      combined.contains(pattern)
    }
  }

  private func updateSourceDetection() {
    let trimmed = detectedURL.trimmingCharacters(in: .whitespacesAndNewlines)
    if let url = URL(string: trimmed) {
      detectedSource = url.host
      errorMessage = nil
    } else {
      detectedSource = nil
    }
  }

  private func importFromShare() async {
    errorMessage = nil
    successMessage = nil

    let trimmed = detectedURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard var url = URL(string: trimmed) else {
      errorMessage = "Invalid URL format"
      return
    }

    isLoading = true
    defer { isLoading = false }

    do {
      let config = URLSessionConfiguration.default
      config.timeoutIntervalForRequest = 15
      config.timeoutIntervalForResource = 60
      config.waitsForConnectivity = true
      let session = URLSession(configuration: config)

      // Step 1: Follow redirects for social media shares
      if isSocialMediaURL(url) {
        if let redirectedURL = await followRedirect(url: url, session: session) {
          url = redirectedURL
          updateSourceDetection()
        }
      }

      // Step 2: Load the page
      let (data, response) = try await session.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        errorMessage =
          "Failed to load URL (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0))"
        return
      }

      if let html = String(data: data, encoding: .utf8) {
        // Step 3: Check for recipe link in the HTML and follow it if from social media
        if isSocialMediaURL(URL(string: trimmed)!) {
          if let recipeLink = try extractRecipeLink(from: html, baseDomain: url.host ?? "") {
            let (recipeData, recipeResponse) = try await session.data(from: recipeLink)
            if let recipeHTML = String(data: recipeData, encoding: .utf8),
              let httpRecipeResponse = recipeResponse as? HTTPURLResponse,
              (200...299).contains(httpRecipeResponse.statusCode)
            {
              if let recipe = try await processRecipePage(html: recipeHTML, sourceURL: recipeLink) {
                modelContext.insert(recipe)
                successMessage = "Recipe imported: \(recipe.name)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                  dismiss()
                }
                return
              }
            }
          }
        }

        // Step 4: Process recipe directly
        if let recipe = try await processRecipePage(html: html, sourceURL: url) {
          modelContext.insert(recipe)
          successMessage = "Recipe imported: \(recipe.name)"
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
          }
          return
        }

        errorMessage = "No recipe data found on this page"
        return
      }

      errorMessage = "Unable to load content from this URL"
    } catch {
      errorMessage = "Error: \(error.localizedDescription)"
    }
  }

  private func isSocialMediaURL(_ url: URL) -> Bool {
    let host = url.host?.lowercased() ?? ""
    let socialMediaPatterns = [
      "pinterest", "facebook", "fb", "twitter", "x.com", "instagram", "tiktok", "tik",
    ]
    return socialMediaPatterns.contains { host.contains($0) }
  }

  private func followRedirect(url: URL, session: URLSession) async -> URL? {
    var request = URLRequest(url: url)
    request.httpShouldHandleCookies = true
    request.timeoutInterval = 10

    do {
      let (_, response) = try await session.data(for: request)

      if let httpResponse = response as? HTTPURLResponse {
        if let locationString = httpResponse.allHeaderFields["Location"] as? String,
          let redirectURL = URL(string: locationString)
        {
          return redirectURL
        }

        let html = try? await session.data(from: url).0
        if let htmlData = html, let htmlString = String(data: htmlData, encoding: .utf8) {
          if let refreshURL = extractRefreshURL(from: htmlString) {
            return refreshURL
          }
        }
      }
    } catch {
      return nil
    }

    return nil
  }

  private func extractRefreshURL(from html: String) -> URL? {
    guard let doc = try? SwiftSoup.parse(html) else { return nil }

    if let metaRefresh = try? doc.select("meta[http-equiv=refresh]").first() {
      if let content = try? metaRefresh.attr("content") {
        let parts = content.split(separator: ";")
        for part in parts {
          let trimmed = String(part).trimmingCharacters(in: .whitespaces)
          if trimmed.lowercased().starts(with: "url=") {
            let urlString = String(trimmed.dropFirst(4)).trimmingCharacters(
              in: CharacterSet(charactersIn: "\"'"))
            if let url = URL(string: urlString) {
              return url
            }
          }
        }
      }
    }

    return nil
  }

  private func extractRecipeLink(from html: String, baseDomain: String) throws -> URL? {
    let doc = try SwiftSoup.parse(html)

    // Look for og:url
    if let ogURL = try? doc.select("meta[property=og:url]").first()?.attr("content"),
      let url = URL(string: ogURL), !isSocialMediaDomain(ogURL)
    {
      return url
    }

    // Look for canonical link
    if let canonical = try? doc.select("link[rel=canonical]").first()?.attr("href"),
      let url = URL(string: canonical), !isSocialMediaDomain(canonical)
    {
      return url
    }

    // Look for recipe links
    if let links = try? doc.select("a[href*=recipe]").array() {
      for link in links {
        if let href = try? link.attr("href"), let url = URL(string: href) {
          if !isSocialMediaDomain(href) {
            return url
          }
        }
      }
    }

    // Pinterest/TikTok/Instagram: look for external links
    if baseDomain.contains("pinterest") || baseDomain.contains("tiktok")
      || baseDomain.contains("tik") || baseDomain.contains("instagram")
    {
      if let links = try? doc.select("a[href]").array() {
        for link in links {
          if let href = try? link.attr("href"),
            !isSocialMediaDomain(href) && (href.starts(with: "http") || href.starts(with: "//"))
          {
            if let url = URL(string: href) {
              return url
            }
          }
        }
      }
    }

    // Facebook/Instagram: look for link attributes in data attributes
    if let dataLinks = try? doc.select("[data-href]").array() {
      for element in dataLinks {
        if let dataHref = try? element.attr("data-href"),
          !isSocialMediaDomain(dataHref)
            && (dataHref.starts(with: "http") || dataHref.starts(with: "//"))
        {
          if let url = URL(string: dataHref) {
            return url
          }
        }
      }
    }

    return nil
  }

  private func isSocialMediaDomain(_ urlString: String) -> Bool {
    let socialMediaPatterns = [
      "pinterest", "facebook", "fb", "twitter", "x.com", "instagram", "tiktok", "tik",
    ]
    return socialMediaPatterns.contains { urlString.lowercased().contains($0) }
  }

  private func processRecipePage(html: String, sourceURL: URL) async throws -> Recipe? {
    // Try JSON-LD first
    if let recipe = try RecipeImportService.extractRecipeFromJSONLDScripts(html: html) {
      return recipe
    }

    // Try microdata
    if let recipe = try RecipeImportService.extractRecipeFromMicrodata(
      html: html, sourceURL: sourceURL)
    {
      return recipe
    }

    // Try Jina Reader API for better extraction
    if let recipe = await fetchRecipeViaJina(url: sourceURL) {
      return recipe
    }

    // Aggressive HTML scraping as fallback
    if let recipe = try aggressiveScrapeRecipe(html: html, sourceURL: sourceURL) {
      return recipe
    }

    return nil
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

  private func aggressiveScrapeRecipe(html: String, sourceURL: URL) throws -> Recipe? {
    let doc = try SwiftSoup.parse(html)

    let title: String = {
      if let h1 = try? doc.select("h1").first()?.text(), !h1.isEmpty { return h1 }
      if let ogTitle = try? doc.select("meta[property=og:title]").first()?.attr("content"),
        !ogTitle.isEmpty
      {
        return ogTitle
      }
      if let titleTag = try? doc.title(), !titleTag.isEmpty { return titleTag }
      return sourceURL.host ?? "Imported Recipe"
    }()

    var ingredients: [String] = []

    // Method 1: itemprop
    if let elements = try? doc.select("[itemprop=recipeIngredient]").array() {
      for el in elements {
        if let text = try? el.text(), !text.isEmpty {
          ingredients.append(text)
        }
      }
    }

    // Method 2: Common ingredient classes
    if ingredients.isEmpty {
      let selectors = [
        ".ingredient", ".ingredient-item", ".ingredients li", ".recipe-ingredient",
        ".ingredient-list li", "li.ingredient", "[class*=ingredientLine]",
        ".ingredient-line", ".ingredient__item", "[class*=ingredient]",
      ]
      for selector in selectors {
        if let elements = try? doc.select(selector).array() {
          for el in elements {
            if let text = try? el.text(), !text.isEmpty && text.count > 3 {
              let trimmed = text.trimmingCharacters(in: .whitespaces)
              if !trimmed.contains("Add to") && !trimmed.contains("Save")
                && !trimmed.lowercased().contains("print")
              {
                ingredients.append(trimmed)
              }
            }
          }
          if !ingredients.isEmpty { break }
        }
      }
    }

    // Method 3: Look for lists
    if ingredients.isEmpty {
      if let lists = try? doc.select("ul, ol").array() {
        for ul in lists {
          var tempIngredients: [String] = []
          if let listItems = try? ul.select("li").array() {
            for li in listItems {
              if let text = try? li.text(), !text.isEmpty && text.count > 3 {
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                if !trimmed.contains("Add to") && !trimmed.contains("Save") {
                  tempIngredients.append(trimmed)
                }
              }
            }
          }
          if tempIngredients.count > 2 {
            ingredients = tempIngredients
            break
          }
        }
      }
    }

    var instructions: [String] = []

    // Method 1: itemprop
    if let elements = try? doc.select("[itemprop=recipeInstructions]").array() {
      for el in elements {
        if let text = try? el.text(), !text.isEmpty && text.count > 10 {
          instructions.append(text)
        }
      }
    }

    // Method 2: Common instruction classes
    if instructions.isEmpty {
      let selectors = [
        ".instruction", ".instructions li", ".directions li", ".steps li", ".instruction-step",
        ".instruction-list li", "[class*=instructionLine]",
        ".instruction-line", ".step", "[class*=directions]", "[class*=method]",
      ]
      for selector in selectors {
        if let elements = try? doc.select(selector).array() {
          for el in elements {
            if let text = try? el.text(), !text.isEmpty && text.count > 10 {
              let trimmed = text.trimmingCharacters(in: .whitespaces)
              if !trimmed.contains("Add to") && !trimmed.contains("Print") {
                instructions.append(trimmed)
              }
            }
          }
          if !instructions.isEmpty { break }
        }
      }
    }

    // Method 3: Look for numbered items
    if instructions.isEmpty {
      let mainContent =
        (try? doc.select("main, article, [role=main], .recipe, .recipe-content").first())
        ?? (try? doc.select("body").first())

      if let content = mainContent {
        if let elements = try? content.select("p, div").array() {
          for el in elements {
            if let text = try? el.text(), text.count > 20 && text.count < 500 {
              let trimmed = text.trimmingCharacters(in: .whitespaces)
              if trimmed.first?.isNumber == true || trimmed.starts(with: "Step")
                || trimmed.starts(with: "1.") || trimmed.starts(with: "-")
              {
                if !trimmed.contains("Add to") {
                  instructions.append(trimmed)
                }
              }
            }
          }
        }
      }
    }

    // Fallback: always return something
    if ingredients.isEmpty {
      ingredients = ["See full recipe at: \(sourceURL.absoluteString)"]
    }
    if instructions.isEmpty {
      instructions = ["See full recipe at: \(sourceURL.absoluteString)"]
    }

    return Recipe(
      name: title,
      cuisine: "",
      cookTime: 30,
      difficulty: "Medium",
      ingredients: Array(ingredients.prefix(50)),
      instructions: Array(instructions.prefix(50)),
      imageName: ""
    )
  }
}

struct ManualURLInputView: View {
  @Binding var isPresented: Bool
  var onSubmit: (String) -> Void

  @State private var urlInput: String = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      VStack(spacing: 20) {
        Text("Paste Recipe URL")
          .font(.headline)

        VStack(spacing: 12) {
          TextField("https://example.com/recipe", text: $urlInput, axis: .vertical)
            .lineLimit(3...6)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .border(Color.gray.opacity(0.3))
            .focused($isFocused)
            .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
              }
            }

          Text("Paste a recipe URL from sites like AllRecipes, Epicurious, or BBC Good Food")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        HStack(spacing: 12) {
          Button("Cancel") {
            isPresented = false
          }
          .buttonStyle(.bordered)

          Button("Import") {
            let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
              onSubmit(trimmed)
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }

        Spacer()
      }
      .padding(20)
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .padding(20)
    }
  }
}

#Preview {
  ImportFromShareView()
}
