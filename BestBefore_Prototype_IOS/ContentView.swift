import FirebaseAuth
import QuartzCore
import SwiftUI
import Combine

struct ContentView: View {
  @State private var isLoggedIn = false
  @State private var isVerified = false

  init() {
    if let user = Auth.auth().currentUser {
      _isLoggedIn = State(initialValue: true)
      _isVerified = State(initialValue: user.isEmailVerified)
    }
  }

  var body: some View {
    ZStack {
      Group {
        if isLoggedIn {
          if isVerified {
            NavigationView {
              HallwayView(onLogout: {
                logout()
              })
            }
          } else {
            VerificationView(onVerified: {
              isVerified = true
            })
          }
        } else {
          LoginView(onLoginSuccess: {
            isLoggedIn = true
            isVerified = Auth.auth().currentUser?.isEmailVerified ?? false
          })
        }
      }

      VStack {
        HStack {
          FPSMeter()
            .hidden()
            .padding(.top, 60)
            .padding(.leading, 16)
          Spacer()
        }
        Spacer()
      }
      .zIndex(100)
    }
    .ignoresSafeArea(.all, edges: .top)

    .task {
      if isLoggedIn {
        await AuthService.shared.restoreSession()
      }
    }
  }

  func logout() {
    AuthService.shared.clearSession()
    isLoggedIn = false
    isVerified = false
  }
}

#Preview {
  ContentView()
}

// MARK: - FPS Meter

class FPSCounter: ObservableObject {
  @Published var fps: Int = 0
  private var displayLink: CADisplayLink?
  private var lastUpdateTimestamp: CFTimeInterval = 0
  private var frameCount: Int = 0

  init() {}

  func start() {
    if displayLink == nil {
      let target = DisplayLinkTarget { [weak self] link in
        self?.update(link: link)
      }
      displayLink = CADisplayLink(
        target: target, selector: #selector(DisplayLinkTarget.update(link:)))
      displayLink?.add(to: .main, forMode: .common)
    }
  }

  func stop() {
    displayLink?.invalidate()
    displayLink = nil
  }

  private func update(link: CADisplayLink) {
    if lastUpdateTimestamp == 0 {
      lastUpdateTimestamp = link.timestamp
      return
    }

    frameCount += 1
    let delta = link.timestamp - lastUpdateTimestamp
    if delta >= 1.0 {
      fps = Int(round(Double(frameCount) / delta))
      frameCount = 0
      lastUpdateTimestamp = link.timestamp
    }
  }
}

class DisplayLinkTarget {
  var callback: (CADisplayLink) -> Void
  init(callback: @escaping (CADisplayLink) -> Void) {
    self.callback = callback
  }
  @objc func update(link: CADisplayLink) {
    callback(link)
  }
}

struct FPSMeter: View {
  @StateObject private var counter = FPSCounter()

  var body: some View {
    Text("FPS: \(counter.fps)")
      .font(.system(size: 14, weight: .bold, design: .monospaced))
      .foregroundColor(counter.fps >= 50 ? .green : (counter.fps >= 30 ? .yellow : .red))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color.black.opacity(0.8))
      .cornerRadius(8)
      .onAppear {
        counter.start()
      }
      .onDisappear {
        counter.stop()
      }
  }
}
