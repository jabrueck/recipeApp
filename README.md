# recipeApp

Simple SwiftUI recipe app using SwiftData for persistence.

## Overview
- UI and data model live in `recipeApp/ContentView.swift`.
  Key symbols: `Recipe`, `ContentView`, and the sample data inserter `addSampleRecipes()`.
- App entry config is in `recipeApp/recipeAppApp.swift`. It attaches the SwiftData model container used at runtime.
- Assets are in `recipeApp/Assets.xcassets`.
- Tests: unit tests in `recipeAppTests/recipeAppTests.swift` and UI tests in `recipeAppUITests/recipeAppUITests.swift`.

## Requirements
- macOS with Xcode that supports SwiftData / iOS 17+ SDK.
- Open in Xcode recommended.

## Build & Run
- Open the project in Xcode: open `recipeApp.xcodeproj` or the workspace.
- From terminal (example):
```
xcodebuild -project recipeApp.xcodeproj -scheme recipeApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'
```

## How sample recipes work
- Sample recipes are created and inserted by `addSampleRecipes()` in `ContentView`.
- The app requires a SwiftData model container to back `@Query` and `@Environment(\.modelContext)`. This is configured in `recipeAppApp` by calling `.modelContainer(for: [Recipe.self])`.

## Troubleshooting
- No recipes visible on launch?
  - Confirm `recipeAppApp` includes `.modelContainer(for: [Recipe.self])`.
  - Confirm `ContentView` calls `addSampleRecipes()` when `recipes.isEmpty`.

## Project files
- `recipeApp/ContentView.swift` — main UI and model
- `recipeApp/recipeAppApp.swift` — app entry and model container
- `recipeApp/Assets.xcassets` — colors & icons

## Notes
- The project uses SwiftData `@Model`, `@Query`, and `@Bindable`. See `ContentView.swift` for examples.

## Adding SwiftSoup (needed for URL import)

To enable the import-by-URL feature, add the `SwiftSoup` package to the Xcode project:

- In Xcode: File ▶ Add Packages... then search for `SwiftSoup` (https://github.com/scinfu/SwiftSoup) and add the latest release.
- Or via command line using Swift Package Manager for an Xcode project that uses SPM dependencies:

```bash
# In the project directory (optional):
open recipeApp.xcodeproj
# Then use Xcode UI to add: https://github.com/scinfu/SwiftSoup
```

After adding the package, import `SwiftSoup` in `AddRecipeByURLView.swift` is already included.
