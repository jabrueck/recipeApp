import Foundation

/// Handles deep links and shared URLs from social media and other sources
enum URLHandlerService {
  /// Detects if a URL is likely a recipe source based on known recipe domains
  static func isLikelyRecipeURL(_ url: URL) -> Bool {
    let recipePatterns = [
      "allrecipes", "epicurious", "foodnetwork", "serious eats",
      "recipe", "cooking", "cuisine", "meal", "dish",
      "bbcgoodfood", "bonappetit", "food52", "tastingtable",
    ]

    let host = url.host?.lowercased() ?? ""
    let path = url.path.lowercased()
    let combined = "\(host) \(path)"

    return recipePatterns.contains { pattern in
      combined.contains(pattern)
    }
  }

  /// Extracts a clean URL from social media share links
  static func extractRecipeURLFromShare(_ urlString: String) -> URL? {
    // Handle common social media share URL formats
    if let url = URL(string: urlString) {
      // Direct recipe URL
      if isLikelyRecipeURL(url) {
        return url
      }

      // Pinterest pin (often redirects to recipe)
      if url.host?.contains("pinterest") == true {
        return url
      }

      // Facebook share with redirect
      if url.host?.contains("facebook") == true || url.host?.contains("fb.com") == true {
        if let redirect = url.queryParameters?["u"] {
          return URL(string: redirect)
        }
        return url
      }

      // Twitter/X link (may redirect to recipe)
      if url.host?.contains("twitter") == true || url.host?.contains("x.com") == true {
        return url
      }
    }

    return nil
  }
}

// Helper extension for URL query parameters
extension URL {
  var queryParameters: [String: String]? {
    guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
      let queryItems = components.queryItems
    else {
      return nil
    }

    var params = [String: String]()
    for item in queryItems {
      params[item.name] = item.value
    }
    return params.isEmpty ? nil : params
  }
}
