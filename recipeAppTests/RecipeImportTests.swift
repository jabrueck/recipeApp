import XCTest

@testable import recipeApp

final class RecipeImportTests: XCTestCase {

  // Test that JSON-LD recipe data is parsed into a Recipe object correctly.
  // This uses `RecipeImportService.parseJSONRecipeData` to convert JSON data
  // (in JSON-LD format with "@type": "Recipe") into a `Recipe` instance.
  // Expectations:
  //  - The returned recipe is non-nil
  //  - The recipe name matches the JSON "name" value
  //  - The cook time is parsed from ISO duration "PT20M" -> 20 minutes
  //  - The ingredients array contains the two provided items
  func testParseJSONLDRecipe() throws {
    let json = """
      {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": "Test Pancakes",
        "recipeIngredient": ["1 cup flour","1 egg"],
        "recipeInstructions": ["Mix ingredients","Cook on skillet"],
        "totalTime": "PT20M"
      }
      """
    let data = Data(json.utf8)

    // Call the parser under test
    let recipe = try RecipeImportService.parseJSONRecipeData(data)

    // Assertions verify parsing outcomes
    XCTAssertNotNil(recipe)  // Parser should return a Recipe object
    XCTAssertEqual(recipe?.name, "Test Pancakes")  // Name should match JSON
    XCTAssertEqual(recipe?.cookTime, 20)  // ISO duration PT20M -> 20 minutes
    XCTAssertEqual(recipe?.ingredients.count, 2)  // Two ingredients provided
  }

  // Test ISO 8601 duration parsing helper.
  // This verifies `RecipeImportService.parseISODurationToMinutes` converts
  // PT1H30M -> 90, PT45M -> 45, and returns nil for non-ISO inputs.
  func testParseISODuration() {
    XCTAssertEqual(RecipeImportService.parseISODurationToMinutes("PT1H30M"), 90)
    XCTAssertEqual(RecipeImportService.parseISODurationToMinutes("PT45M"), 45)
    XCTAssertNil(RecipeImportService.parseISODurationToMinutes("1h30m"))
  }

  // Test extracting recipe data from HTML microdata.
  // This constructs a small HTML snippet with itemprop attributes:
  //  - <h1 itemprop="name"> provides the recipe title
  //  - <li class="ingredient"> elements are used as fallback ingredient selectors
  //  - <ol class="instructions"> provides ordered instruction steps
  //
  // It calls `RecipeImportService.extractRecipeFromMicrodata(html:sourceURL:)`
  // and checks that the returned Recipe has the expected name, ingredient count,
  // and instruction count.
  func testParseMicrodataHTML() throws {
    let html = """
      <html><head><title>HTML Recipe</title></head>
      <body>
        <h1 itemprop="name">HTML Pancakes</h1>
        <ul class="ingredients">
          <li class="ingredient">1 cup flour</li>
          <li class="ingredient">1 egg</li>
        </ul>
        <ol class="instructions">
          <li>Mix</li>
          <li>Cook</li>
        </ol>
      </body></html>
      """
    let url = URL(string: "https://example.com/recipe")!

    // Call the microdata/html parser
    let recipe = try RecipeImportService.extractRecipeFromMicrodata(html: html, sourceURL: url)

    // Verify parsed values
    XCTAssertNotNil(recipe)  // Should find a recipe in the provided HTML
    XCTAssertEqual(recipe?.name, "HTML Pancakes")  // Title comes from itemprop=name
    XCTAssertEqual(recipe?.ingredients.count, 2)  // Two ingredient list items
    XCTAssertEqual(recipe?.instructions.count, 2)  // Two instruction steps
  }
}
