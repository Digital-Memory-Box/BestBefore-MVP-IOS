import FirebaseAuth
import SwiftUI

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

    }
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
