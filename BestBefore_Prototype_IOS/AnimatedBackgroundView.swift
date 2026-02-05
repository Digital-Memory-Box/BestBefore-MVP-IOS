import Combine
import SwiftUI

struct AnimatedBackgroundView: View {
  @State private var startPulse = false
  @State private var orb1Angle = 0.0
  @State private var orb2Angle = 180.0

  let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.ignoresSafeArea()

        // Main center glow - blue to green gradient
        RadialGradient(
          gradient: Gradient(colors: [
            Color(red: 0.05, green: 0.35, blue: 0.95).opacity(0.4),
            Color(red: 0.0, green: 0.85, blue: 0.45).opacity(0.2),
            .clear,
          ]),
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

        // Floating orb 1 - magenta/orange
        OrbCircle(
          colors: [
            Color(red: 0.95, green: 0.14, blue: 0.91), Color(red: 1.0, green: 0.6, blue: 0.2),
          ],
          size: 70,
          radius: 180,
          angle: orb1Angle
        )

        // Floating orb 2 - cyan/purple
        OrbCircle(
          colors: [
            Color(red: 0.3, green: 0.95, blue: 0.95), Color(red: 0.9, green: 0.3, blue: 0.95),
          ],
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
