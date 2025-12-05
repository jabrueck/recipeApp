//
//  recipeAppApp.swift
//  recipeApp
//
//  Created by Josh Brueck on 11/20/25.
//

import SwiftData
import SwiftUI

@main
struct recipeAppApp: App {
  @State private var incomingURL: URL?
  @State private var showImportFromShare = false

  var body: some Scene {
    WindowGroup {
      ContentView(incomingURL: $incomingURL, showImportFromShare: $showImportFromShare)
        .modelContainer(for: [Recipe.self])
        .onOpenURL { url in
          handleIncomingURL(url)
        }
    }
  }

  private func handleIncomingURL(_ url: URL) {
    // Handle URLs like: recipeapp://import?url=https://www.allrecipes.com/recipe/12345
    if url.scheme == "recipeapp" {
      if url.host == "import" {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let queryItems = components.queryItems,
          let recipeURLString = queryItems.first(where: { $0.name == "url" })?.value,
          let recipeURL = URL(string: recipeURLString)
        {
          incomingURL = recipeURL
          showImportFromShare = true
        }
      }
    }
  }
}
