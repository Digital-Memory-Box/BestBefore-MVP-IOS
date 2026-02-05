import SwiftUI

struct OrbMenuPremium: View {
  @State private var isExpanded = true  // Match the screenshot state

  var onAdd: () -> Void = {}
  var onChat: () -> Void = {}
  var onProfile: () -> Void = {}
  var onSearch: () -> Void = {}

  private let orbGradient = LinearGradient(
    colors: [
      Color(red: 0.12, green: 0.38, blue: 0.94),
      Color(red: 0.05, green: 0.75, blue: 0.95),
    ],
    startPoint: .leading,
    endPoint: .trailing
  )

  var body: some View {
    ZStack(alignment: .trailing) {
      if isExpanded {
        // Smaller Orb Background (340pt)
        Circle()
          .fill(orbGradient)
          .frame(width: 340, height: 340)
          .offset(x: 170)  // Perfect semi-circle on target edge
          .shadow(color: .black.opacity(0.3), radius: 15, x: -5, y: 0)

        // Icons - Aligned vertically on the right, Plus pushed inward
        ZStack {
          // 1. Plus Icon (Pushed further into the semi-circle)
          Button(action: onAdd) {
            Image(systemName: "plus")
              .font(.system(size: 22, weight: .bold))
              .foregroundColor(.white)
          }
          .offset(x: -135, y: 0)

          // Arc of three icons on the right (Vertically Aligned)
          VStack(spacing: 55) {
            // Envelope (Top)
            Button(action: onChat) {
              Image(systemName: "envelope.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            }
            .offset(x: -95)

            // Person (Center)
            Button(action: onProfile) {
              Image(systemName: "person.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            }
            .offset(x: -95)

            // Search (Bottom)
            Button(action: onSearch) {
              Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            }
            .offset(x: -95)
          }
        }
        .transition(.opacity)
      } else {
        // Collapsed State
        Circle()
          .fill(orbGradient)
          .frame(width: 60, height: 60)
          .offset(x: 30)
          .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              isExpanded = true
            }
          }
      }
    }
    .frame(width: 170, height: 400)  // Compact static container
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        isExpanded.toggle()
      }
    }
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    OrbMenuPremium()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
  }
}
