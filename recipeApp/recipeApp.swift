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
  // Provide a SwiftData model container for the Recipe model so
  // @Query and @Environment(\.modelContext) in ContentView work at runtime.
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    // Attach the SwiftData model container for the Recipe model
    .modelContainer(for: [Recipe.self])
  }
}
