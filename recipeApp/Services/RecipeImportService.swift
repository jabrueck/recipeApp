import Foundation
import SwiftData
import SwiftSoup

/// Provides parsing helpers to extract `Recipe` instances from JSON-LD, JSON, or HTML.
enum RecipeImportService {
  static func parseJSONRecipeData(_ data: Data) throws -> Recipe? {
    let obj = try JSONSerialization.jsonObject(with: data, options: [])
    return try parseJSONRecipeAny(obj)
  }

  static func parseJSONRecipeAny(_ any: Any) throws -> Recipe? {
    if let dict = any as? [String: Any] {
      if let atType = dict["@type"] as? String, atType.localizedCaseInsensitiveContains("recipe") {
        return recipeFromDictionary(dict)
      }
      if let atTypeArr = dict["@type"] as? [Any] {
        for t in atTypeArr {
          if String(describing: t).localizedCaseInsensitiveContains("recipe") {
            return recipeFromDictionary(dict)
          }
        }
      }

      if let graph = dict["@graph"] as? [Any] {
        for item in graph {
          if let itemDict = item as? [String: Any] {
            if let t = itemDict["@type"] as? String, t.localizedCaseInsensitiveContains("recipe") {
              return recipeFromDictionary(itemDict)
            }
          }
        }
      }

      if dict["recipeIngredient"] != nil || dict["recipeInstructions"] != nil || dict["name"] != nil
      {
        return recipeFromDictionary(dict)
      }
    }
    return nil
  }

  static func recipeFromDictionary(_ dict: [String: Any]) -> Recipe? {
    let name = (dict["name"] as? String) ?? (dict["headline"] as? String) ?? "Imported Recipe"
    let cuisine = (dict["recipeCuisine"] as? String) ?? ""
    var cookTime = 30
    if let total = dict["totalTime"] as? String, let minutes = parseISODurationToMinutes(total) {
      cookTime = minutes
    }
    let difficulty = (dict["difficulty"] as? String) ?? (dict["level"] as? String) ?? "Medium"

    var ingredients: [String] = []
    if let ingr = dict["recipeIngredient"] as? [String] {
      ingredients = ingr
    } else if let ingr = dict["ingredients"] as? [String] {
      ingredients = ingr
    }

    var instructions: [String] = []
    if let instr = dict["recipeInstructions"] {
      if let s = instr as? String {
        instructions = [s]
      } else if let arr = instr as? [Any] {
        for item in arr {
          if let str = item as? String {
            instructions.append(str)
          } else if let d = item as? [String: Any], let text = d["text"] as? String {
            instructions.append(text)
          }
        }
      }
    }

    if ingredients.isEmpty { ingredients = ["Imported from web"] }
    if instructions.isEmpty { instructions = ["See original page for steps"] }

    return Recipe(
      name: name,
      cuisine: cuisine,
      cookTime: cookTime,
      difficulty: difficulty,
      ingredients: ingredients,
      instructions: instructions,
      imageName: ""
    )
  }

  static func parseISODurationToMinutes(_ iso: String) -> Int? {
    guard iso.hasPrefix("PT") else { return nil }
    var minutes = 0
    let pattern = "PT(?:(\\d+)H)?(?:(\\d+)M)?"
    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
      let ns = iso as NSString
      let full = NSRange(location: 0, length: ns.length)
      if let m = regex.firstMatch(in: iso, options: [], range: full) {
        if m.range(at: 1).location != NSNotFound {
          let h = Int(ns.substring(with: m.range(at: 1))) ?? 0
          minutes += h * 60
        }
        if m.range(at: 2).location != NSNotFound {
          let mm = Int(ns.substring(with: m.range(at: 2))) ?? 0
          minutes += mm
        }
        return minutes
      }
    }
    return nil
  }

  static func extractRecipeFromJSONLDScripts(html: String) throws -> Recipe? {
    let doc = try SwiftSoup.parse(html)
    let scripts = try doc.select("script[type=\"application/ld+json\"]")
    for element in scripts.array() {
      let jsonText = try element.html()
      if let data = jsonText.data(using: .utf8) {
        if let recipe = try parseJSONRecipeData(data) { return recipe }
        if let any = try? JSONSerialization.jsonObject(with: data, options: []) {
          if let arr = any as? [Any] {
            for item in arr {
              if let recipe = try parseJSONRecipeAny(item) { return recipe }
            }
          }
        }
      }
    }
    return nil
  }

  static func extractRecipeFromMicrodata(html: String, sourceURL: URL) throws -> Recipe? {
    let doc = try SwiftSoup.parse(html)

    let name = (try? doc.select("[itemprop=name]").first()?.text()) ?? (try? doc.title())
    var ingredients: [String] = []
    for el in try doc.select("[itemprop=recipeIngredient]").array() {
      ingredients.append(try el.text())
    }
    if ingredients.isEmpty {
      for el in try doc.select(".ingredient, .ingredients li, li.ingredient").array() {
        let text = try el.text()
        if !text.isEmpty { ingredients.append(text) }
      }
    }

    var instructions: [String] = []
    for el in try doc.select("[itemprop=recipeInstructions]").array() {
      instructions.append(try el.text())
    }
    if instructions.isEmpty {
      for el in try doc.select(".instructions li, .directions li, .method li").array() {
        let text = try el.text()
        if !text.isEmpty { instructions.append(text) }
      }
    }

    if name == nil && ingredients.isEmpty && instructions.isEmpty { return nil }

    let finalName = name ?? sourceURL.host ?? "Imported Recipe"
    return Recipe(
      name: finalName,
      cuisine: "",
      cookTime: 30,
      difficulty: "Medium",
      ingredients: ingredients.isEmpty
        ? ["Imported from \(sourceURL.host ?? "source")"] : ingredients,
      instructions: instructions.isEmpty
        ? ["See original page: \(sourceURL.absoluteString)"] : instructions,
      imageName: ""
    )
  }

  static func extractTitleFromHTML(html: String) -> String? {
    if let doc = try? SwiftSoup.parse(html) {
      return try? doc.title()
    }
    return nil
  }
}
