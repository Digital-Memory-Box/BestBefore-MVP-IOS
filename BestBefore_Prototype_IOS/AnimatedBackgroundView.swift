import Combine
import SwiftUI

struct AnimatedBackgroundView: View {
  var theme: String = "default"
  @State private var startPulse = false
  @State private var orb1Angle = 0.0
  @State private var orb2Angle = 180.0

  let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.ignoresSafeArea()

        // Main center glow - dynamic gradient
        RadialGradient(
          gradient: Gradient(colors: centerGlowColors),
          center: .center,
          startRadius: 0,
          endRadius: (min(geometry.size.width, geometry.size.height) * 0.5)
            * (startPulse ? 1.05 : 0.95)
        )
        .onAppear {
          withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            startPulse.toggle()
          }
        }

        // Floating orb 1 - dynamic
        OrbCircle(
          colors: orb1Colors,
          size: 70,
          radius: 180,
          angle: orb1Angle
        )

        // Floating orb 2 - dynamic
        OrbCircle(
          colors: orb2Colors,
          size: 90,
          radius: 200,
          angle: orb2Angle
        )

        // Subtle vignette overlay
        RadialGradient(
          gradient: Gradient(colors: [
            .clear,
            .black.opacity(0.2),
            .black.opacity(0.4),
          ]),
          center: .center,
          startRadius: 0,
          endRadius: max(geometry.size.width, geometry.size.height) * 0.6
        )
      }
    }
    .onReceive(timer) { _ in
      orb1Angle += 1.0  // Matches 12s rotation loosely
      orb2Angle += 0.8  // Matches 15s rotation loosely
    }
  }

  // Helper for colors
  private var centerGlowColors: [Color] {
    switch theme.lowercased() {
    case "ocean":
      return [
        Color(red: 0.0, green: 0.5, blue: 0.8).opacity(0.4),
        Color(red: 0.0, green: 0.8, blue: 0.8).opacity(0.2), .clear,
      ]
    case "sunset":
      return [
        Color(red: 0.9, green: 0.3, blue: 0.1).opacity(0.4),
        Color(red: 0.9, green: 0.6, blue: 0.2).opacity(0.2), .clear,
      ]
    case "forest":
      return [
        Color(red: 0.1, green: 0.6, blue: 0.2).opacity(0.4),
        Color(red: 0.4, green: 0.8, blue: 0.3).opacity(0.2), .clear,
      ]
    case "cyberpunk":
      return [
        Color(red: 0.8, green: 0.0, blue: 0.8).opacity(0.4),
        Color(red: 0.0, green: 0.8, blue: 0.9).opacity(0.2), .clear,
      ]
    default:
      return [
        Color(red: 0.05, green: 0.35, blue: 0.95).opacity(0.4),
        Color(red: 0.0, green: 0.85, blue: 0.45).opacity(0.2), .clear,
      ]
    }
  }

  private var orb1Colors: [Color] {
    switch theme.lowercased() {
    case "ocean":
      return [Color(red: 0.1, green: 0.4, blue: 0.9), Color(red: 0.2, green: 0.8, blue: 0.9)]
    case "sunset":
      return [Color(red: 0.9, green: 0.1, blue: 0.3), Color(red: 1.0, green: 0.5, blue: 0.1)]
    case "forest":
      return [Color(red: 0.2, green: 0.5, blue: 0.1), Color(red: 0.5, green: 0.9, blue: 0.2)]
    case "cyberpunk":
      return [Color(red: 1.0, green: 0.0, blue: 0.5), Color(red: 0.5, green: 0.0, blue: 1.0)]
    default:
      return [Color(red: 0.95, green: 0.14, blue: 0.91), Color(red: 1.0, green: 0.6, blue: 0.2)]
    }
  }

  private var orb2Colors: [Color] {
    switch theme.lowercased() {
    case "ocean":
      return [Color(red: 0.3, green: 0.8, blue: 1.0), Color(red: 0.1, green: 0.3, blue: 0.8)]
    case "sunset":
      return [Color(red: 1.0, green: 0.8, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.4)]
    case "forest":
      return [Color(red: 0.4, green: 0.8, blue: 0.3), Color(red: 0.1, green: 0.4, blue: 0.2)]
    case "cyberpunk":
      return [Color(red: 0.0, green: 1.0, blue: 0.8), Color(red: 0.8, green: 0.2, blue: 1.0)]
    default:
      return [Color(red: 0.3, green: 0.95, blue: 0.95), Color(red: 0.9, green: 0.3, blue: 0.95)]
    }
  }
}

struct OrbCircle: View {
  let colors: [Color]
  let size: CGFloat
  let radius: CGFloat
  let angle: Double

  var body: some View {
    RadialGradient(
      gradient: Gradient(colors: [colors[0].opacity(0.5), colors[1].opacity(0.2), .clear]),
      center: .center,
      startRadius: 0,
      endRadius: size
    )
    .frame(width: size * 2, height: size * 2)
    .offset(
      x: radius * CGFloat(cos(angle * .pi / 180)),
      y: radius * CGFloat(sin(angle * .pi / 180))
    )
  }
}

#Preview {
  AnimatedBackgroundView()
}
