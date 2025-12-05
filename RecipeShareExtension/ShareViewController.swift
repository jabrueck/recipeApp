import Social
import UIKit

class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    // Get the shared URL
    if let item = extensionContext?.inputItems.first as? NSExtensionItem {
      if let attachments = item.attachments {
        for provider in attachments {
          if provider.hasItemConformingToTypeIdentifier("public.url") {
            provider.loadItem(forTypeIdentifier: "public.url", options: nil) {
              [weak self] url, error in
              if let url = url as? URL {
                self?.openRecipeApp(with: url)
              }
            }
          }
        }
      }
    }
  }

  private func openRecipeApp(with url: URL) {
    // Construct the URL scheme call
    if let encodedURL = url.absoluteString.addingPercentEncoding(
      withAllowedCharacters: .urlQueryAllowed)
    {
      let recipeAppURL = URL(string: "recipeapp://import?url=\(encodedURL)")!

      // Try to open the main app
      self.openURL(recipeAppURL) { [weak self] success in
        if !success {
          // If it fails, show an alert
          DispatchQueue.main.async {
            let alert = UIAlertController(
              title: "Recipe App Not Installed",
              message: "Please install Recipe App to import recipes.",
              preferredStyle: .alert
            )
            alert.addAction(
              UIAlertAction(title: "OK", style: .default) { _ in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
              })
            self?.present(alert, animated: true)
          }
        } else {
          // Close the extension
          self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
      }
    }
  }

  private func openURL(_ url: URL, completion: @escaping (Bool) -> Void) {
    var responder: UIResponder? = self
    while responder != nil {
      if let application = responder as? UIApplication {
        var result = false
        application.open(url, options: [:]) { success in
          result = success
          completion(success)
        }
        return
      }
      responder = responder?.next
    }
    completion(false)
  }
}
