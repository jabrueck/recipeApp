import Foundation
import SwiftData

// MARK: - Data Model
// @Model is a SwiftData macro that makes this class persistable to disk
// SwiftData automatically creates a database and saves/loads this data
@Model
class Recipe {
  // SwiftData automatically handles the ID, we don't need to add one manually
  var name: String
  var cuisine: String
  var cookTime: Int  // in minutes
  var difficulty: String
  var ingredients: [String]  // Arrays work fine in SwiftData
  var instructions: [String]
  var imageName: String
  var isFavorite: Bool  // New property for marking favorites
  var dateCreated: Date  // Tracks when recipe was added

  // Initializer - required for creating new Recipe objects
  init(
    name: String, cuisine: String, cookTime: Int, difficulty: String,
    ingredients: [String], instructions: [String], imageName: String = "",
    isFavorite: Bool = false
  ) {
    self.name = name
    self.cuisine = cuisine
    self.cookTime = cookTime
    self.difficulty = difficulty
    self.ingredients = ingredients
    self.instructions = instructions
    self.imageName = imageName
    self.isFavorite = isFavorite
    self.dateCreated = Date()
  }
}
