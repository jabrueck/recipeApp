import XCTest

@testable import recipeApp

final class URLHandlerServiceTests: XCTestCase {

  // Test that recipe URLs are correctly identified
  func testIsLikelyRecipeURL() {
    let recipeURL = URL(string: "https://www.allrecipes.com/recipe/12345/chocolate-cake/")!
    let nonRecipeURL = URL(string: "https://www.example.com/")!

    XCTAssertTrue(URLHandlerService.isLikelyRecipeURL(recipeURL))
    XCTAssertFalse(URLHandlerService.isLikelyRecipeURL(nonRecipeURL))
  }

  // Test extraction of URLs from Facebook share links
  func testExtractRecipeURLFromFacebookShare() {
    let facebookShareURL =
      "https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fwww.allrecipes.com%2Frecipe%2F12345%2F"
    let extracted = URLHandlerService.extractRecipeURLFromShare(facebookShareURL)

    XCTAssertNotNil(extracted)
    XCTAssertEqual(extracted?.host, "www.allrecipes.com")
  }

  // Test extraction of direct recipe URLs
  func testExtractRecipeURLDirect() {
    let directURL = "https://www.epicurious.com/recipes/food/views/pasta-carbonara"
    let extracted = URLHandlerService.extractRecipeURLFromShare(directURL)

    XCTAssertNotNil(extracted)
    XCTAssertEqual(extracted?.host, "www.epicurious.com")
  }

  // Test Pinterest URL passthrough
  func testExtractRecipeURLFromPinterest() {
    let pinterestURL = "https://www.pinterest.com/pin/123456789/"
    let extracted = URLHandlerService.extractRecipeURLFromShare(pinterestURL)

    XCTAssertNotNil(extracted)
    XCTAssertEqual(extracted?.host, "www.pinterest.com")
  }

  // Test URL query parameter extraction
  func testURLQueryParameters() {
    let url = URL(string: "https://example.com?param1=value1&param2=value2")!
    let params = url.queryParameters

    XCTAssertNotNil(params)
    XCTAssertEqual(params?["param1"], "value1")
    XCTAssertEqual(params?["param2"], "value2")
  }

  // Test invalid URL handling
  func testExtractRecipeURLInvalid() {
    let invalidURL = "not a valid url"
    let extracted = URLHandlerService.extractRecipeURLFromShare(invalidURL)

    XCTAssertNil(extracted)
  }
}
