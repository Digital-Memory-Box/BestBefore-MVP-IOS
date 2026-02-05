import SwiftUI

// Reusable option row for music
struct MusicPresetOption: View {
  let title: String
  let icon: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(isSelected ? .white : .gray)
          .frame(width: 40)

        Text(title)
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(isSelected ? .white : .gray)

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.blue)
        }
      }
      .padding()
      .background(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
      )
    }
  }
}

struct PrivacyOption: View {
  let title: String
  let subtitle: String
  let icon: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 20))
        Text(title)
          .font(.system(size: 16, weight: .bold))
        Text(subtitle)
          .font(.system(size: 10))
          .multilineTextAlignment(.leading)
      }
      .foregroundColor(isSelected ? .white : .gray)
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
      )
    }
  }
}

struct DurationButton: View {
  let label: String
  let days: Int
  @Binding var current: Int

  var body: some View {
    Button {
      current = days
    } label: {
      Text(label)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(current == days ? .white : .gray)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(current == days ? Color.blue : Color.white.opacity(0.1))
        .cornerRadius(8)
    }
  }
}
