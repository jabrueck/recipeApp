import SwiftUI

// MARK: - Info Badge Component
struct InfoBadge: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.caption)
      Text(text)
        .font(.subheadline)
    }
    .foregroundColor(.secondary)
  }
}
