# Share Extension Setup Guide

This document explains how to complete the Share Extension setup in Xcode.

## Files Created

1. **recipeApp/Info.plist** - Main app configuration with URL scheme support
2. **recipeApp/Views/ImportFromShareViewWithURL.swift** - View for handling incoming shared URLs
3. **recipeApp/recipeApp.swift** - Updated app delegate to handle URL schemes
4. **recipeApp/ContentView.swift** - Updated to support incoming URLs
5. **RecipeShareExtension/ShareViewController.swift** - Share extension logic
6. **RecipeShareExtension/Info.plist** - Share extension configuration
7. **RecipeShareExtension/MainInterface.storyboard** - Share extension UI

## Manual Xcode Steps Required

Since Xcode doesn't allow creating targets via command line, you need to:

### 1. Create Share Extension Target
- In Xcode: File → New → Target
- Search for "Share Extension"
- Name it: `RecipeShareExtension`
- Set Product Name to: `RecipeShareExtension`
- Choose Team and Bundle Identifier appropriately

### 2. Add Target Membership
- Select the created files in RecipeShareExtension folder
- In File Inspector (right panel), check `RecipeShareExtension` under Target Membership

### 3. Update Share Extension Info.plist
- In Project Navigator, select `RecipeShareExtension` → Info.plist
- Replace its contents with the contents of `RecipeShareExtension/Info.plist` from this repository
- Or manually add:
  ```
  NSExtension > NSExtensionPointIdentifier = com.apple.share-services
  CFBundleURLTypes > CFBundleURLSchemes = recipeapp
  ```

### 4. Update Main App Info.plist
- In Project Navigator, select the main app target
- Add to Info.plist:
  ```
  CFBundleURLTypes
    - CFBundleURLSchemes: recipeapp
  ```

### 5. Configure App Groups (Optional - for shared data)
- Select main app target → Signing & Capabilities
- Click "+ Capability"
- Add "App Groups"
- Use identifier like: `group.com.yourcompany.recipeapp`
- Repeat for RecipeShareExtension target

## How It Works

### URL Scheme Flow
1. User shares a recipe URL from Safari, Pinterest, etc.
2. If they have the Share Extension installed, they can select "Share to Recipe App"
3. The extension constructs a URL: `recipeapp://import?url=<encoded_url>`
4. The main app receives this via `onOpenURL` in `recipeAppApp.swift`
5. The URL is passed to `ImportFromShareViewWithURL` which imports the recipe

### App Usage
- **Direct Link**: Users can open URLs like `recipeapp://import?url=https://www.allrecipes.com/recipe/12345`
- **Share Sheet**: Users can share from Safari/Pinterest/etc using the Share Extension
- **Clipboard**: App automatically detects recipe URLs in clipboard on launch

## Testing

### Test URL Scheme
1. In Safari, type: `recipeapp://import?url=https://www.allrecipes.com/recipe/12345/`
2. The app should open and show the import view with that URL

### Test Share Extension
1. In Safari, tap Share button
2. You should see "Share to Recipe App" option
3. Tap it to trigger the extension

## Troubleshooting

**Share Extension not appearing?**
- Ensure target is set to "Any iOS Device" in schemes
- Verify Info.plist has correct extension configuration
- Check that target membership is set correctly

**URL Scheme not working?**
- Make sure URL is properly encoded
- Verify `CFBundleURLSchemes` contains `recipeapp` in both Info.plist files
- Check that app is fully deployed (not just Xcode build)

**Can't import recipes from Share Extension?**
- Verify both targets have matching App Groups (if using shared data)
- Check that the main app can handle incoming URLs (test with manual URL)
