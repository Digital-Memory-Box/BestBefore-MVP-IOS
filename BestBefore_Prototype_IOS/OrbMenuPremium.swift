import SwiftUI

struct OrbMenuPremium: View {
  @State private var isExpanded = true  // Match the screenshot state
  @Binding var isHidden: Bool
  @State private var dragOffsetX: CGFloat = 0
  @State private var applyAccentToAll: Bool = UserDefaults.standard.bool(forKey: "applyAccentToAll")

  var accentColor: Color = .blue  // Passed from HallwayView
  var selectedTheme: String = "Default" // Passed from HallwayView
  var onAdd: () -> Void = {}
  var onChat: () -> Void = {}
  var onScan: () -> Void = {}
  var onProfile: () -> Void = {}
  var onSearch: () -> Void = {}

  private var iconColor: Color {
    if applyAccentToAll && selectedTheme != "Default" {
      return accentColor
    }
    return selectedTheme == "Midnight" ? accentColor : (selectedTheme == "Glass" ? accentColor : .white)
  }

  var body: some View {
    ZStack(alignment: .trailing) {
      if !isHidden {
        ZStack(alignment: .trailing) {
          if isExpanded {
            // Smaller Orb Background (340pt)
            Group {
              if selectedTheme == "Glass" {
                Circle()
                  .fill(accentColor.opacity(0.12))
                  .background(Circle().fill(.thickMaterial)) // Frostier material (thick)
                  .overlay(
                    Circle()
                      .stroke(Color.white.opacity(0.7), lineWidth: 1.5) // Stronger shiny edge
                  )
                  .overlay(
                    Circle()
                      .fill(Color.white.opacity(0.18)) // Higher brightness
                  )
                  .shadow(color: accentColor.opacity(0.25), radius: 12, x: -6, y: 0)
              } else if selectedTheme == "Midnight" {
                Circle()
                  .fill(Color.black)
                  .overlay(
                    Circle()
                      .stroke(accentColor, lineWidth: 2) // Sharp accent border
                  )
                  .shadow(color: accentColor.opacity(0.3), radius: 10, x: -5, y: 0)
              } else {
                Circle()
                  .fill(accentColor)
                  .shadow(color: accentColor.opacity(0.4), radius: 15, x: -5, y: 0)
              }
            }
            .frame(width: 340, height: 340)
            .offset(x: 170)  // Perfect semi-circle on target edge

            // Icons - Aligned vertically on the right, Plus pushed inward
            ZStack {
              // 1. Plus Icon (Pushed further into the semi-circle)
              Button(action: onAdd) {
                Image(systemName: "plus")
                  .font(.system(size: 22, weight: .bold))
                  .foregroundColor(iconColor)
              }
              .offset(x: -135, y: 0)

              // Arc of three icons on the right (Vertically Aligned)
              VStack(spacing: 40) {
                // Envelope (Top)
                Button(action: onChat) {
                  Image(systemName: "envelope.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                }
                .offset(x: -95)


                // Person (Center)
                Button(action: onProfile) {
                  Image(systemName: "person.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(iconColor)
                }
                .offset(x: -95)

                // Search (Bottom)
                Button(action: onSearch) {
                  Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(iconColor)
                }
                .offset(x: -95)
              }
            }
            .transition(.opacity)
          } else {
            // Collapsed State
            Circle()
              .fill(selectedTheme == "Midnight" ? Color.black : (selectedTheme == "Glass" ? accentColor.opacity(0.12) : accentColor))
              .background(selectedTheme == "Glass" ? Circle().fill(.thickMaterial) : nil)
              .overlay(
                Circle()
                  .stroke(selectedTheme == "Midnight" ? accentColor : (selectedTheme == "Glass" ? Color.white.opacity(0.7) : Color.clear), lineWidth: selectedTheme == "Midnight" ? 2 : 1.5)
              )
              .frame(width: 60, height: 60)
              .offset(x: 30)
              .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  isExpanded = true
                }
              }
          }
        }
        .offset(x: dragOffsetX > 0 ? dragOffsetX : 0)
        .opacity(isHidden ? 0 : 1)
        .gesture(
          DragGesture()
            .onChanged { gesture in
              if gesture.translation.width > 0 {
                dragOffsetX = gesture.translation.width
              }
            }
            .onEnded { gesture in
              if gesture.translation.width > 40 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  isHidden = true
                  dragOffsetX = 0
                }
              } else {
                withAnimation(.spring()) {
                  dragOffsetX = 0
                }
              }
            }
        )
      }
    }
    .frame(width: 170, height: 400)  // Compact static container
    .contentShape(Rectangle())
    .allowsHitTesting(!isHidden) // --- FIX: Gizliyken dokunmatik engelleme ---
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AccentColorChanged"))) { _ in
      self.applyAccentToAll = UserDefaults.standard.bool(forKey: "applyAccentToAll")
    }
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    OrbMenuPremium(isHidden: .constant(false), accentColor: .yellow)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
  }
}
