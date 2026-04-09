import SwiftUI

// Reusable option row for music
struct MusicPresetOption: View {
  let title: String
  let icon: String
  let isSelected: Bool
  let tintColor: Color  // Dynamic tint
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
            .foregroundColor(tintColor)
        }
      }
      .padding()
      .background(isSelected ? tintColor.opacity(0.2) : Color.white.opacity(0.05))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? tintColor : Color.clear, lineWidth: 2)
      )
    }
  }
}

struct PrivacyOption: View {
  let title: String
  let subtitle: String
  let icon: String
  let isSelected: Bool
  let tintColor: Color  // Dynamic tint
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
      .background(isSelected ? tintColor.opacity(0.2) : Color.white.opacity(0.05))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? tintColor : Color.clear, lineWidth: 2)
      )
    }
  }
}

struct DurationButton: View {
  let label: String
  let days: Int
  @Binding var current: Int
  let tintColor: Color  // Dynamic tint

  var body: some View {
    Button {
      current = days
    } label: {
      Text(label)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(current == days ? .white : .gray)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(current == days ? tintColor : Color.white.opacity(0.1))
        .cornerRadius(8)
    }
  }
}

struct ThemeOption: View {
  let title: String
  let color: Color
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 12) {
        Circle()
          .fill(
            LinearGradient(
              colors: [color.opacity(0.5), color],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 60, height: 60)
          .overlay(
            Circle()
              .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
          )
          .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 10)

        Text(title)
          .font(.system(size: 14, weight: isSelected ? .bold : .medium))
          .foregroundColor(isSelected ? .white : .gray)
      }
    }
  }
}
