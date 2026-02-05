import SwiftUI

struct LoginView: View {
  @State private var email = ""
  @State private var password = ""
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var showingSignup = false

  var onLoginSuccess: () -> Void = {}

  var body: some View {
    ZStack {
      // Premium Animated Background
      AnimatedBackgroundView()

      VStack(spacing: 60) {
        // Logo Section
        VStack(spacing: 8) {
          Text("Best")
          Text("Before.")
        }
        .font(.system(size: 60, weight: .bold))
        .foregroundColor(.white)
        .padding(.top, 60)

        Spacer()

        // Form Section
        VStack(spacing: 20) {
          OutlinedInput(placeholder: "email or nickname", text: $email)
          OutlinedInput(placeholder: "password", text: $password, isSecure: true)

          Button(action: performLogin) {
            Text("Login")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.black)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(Color.white)
              .cornerRadius(28)  // Fully rounded pill shape
          }
          .padding(.top, 20)
        }
        .padding(.horizontal, 40)

        if let error = errorMessage {
          Text(error)
            .foregroundColor(.red)
            .font(.caption)
            .padding(.top, 8)
        }

        Spacer()

        // Bottom Links
        VStack(alignment: .leading, spacing: 16) {
          Button(action: {}) {
            Text("forgot my password")
              .foregroundColor(.white)
              .font(.system(size: 16))
          }
          Button(action: { showingSignup = true }) {
            Text("create an account")
              .foregroundColor(.white)
              .font(.system(size: 16))
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 40)
        .padding(.bottom, 60)
      }

    }
    .fullScreenCover(isPresented: $showingSignup) {
      SignupView()
    }
    .overlay(
      Group {
        if isLoading {
          ProgressView()
            .scaleEffect(1.5)
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .background(Color.black.opacity(0.4).ignoresSafeArea())
        }
      }
    )
  }

  private func performLogin() {
    guard !email.isEmpty && !password.isEmpty else {
      errorMessage = "Please enter email and password"
      return
    }

    isLoading = true
    errorMessage = nil

    Task {
      do {
        _ = try await AuthService.shared.login(email: email, password: password)
        await MainActor.run {
          onLoginSuccess()
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
        }
      }
      await MainActor.run {
        isLoading = false
      }
    }
  }
}

struct OutlinedInput: View {
  let placeholder: String
  @Binding var text: String
  var isSecure: Bool = false

  var body: some View {
    ZStack(alignment: .leading) {
      if text.isEmpty {
        Text(placeholder)
          .foregroundColor(.white.opacity(0.4))
          .padding(.horizontal, 20)
      }
      Group {
        if isSecure {
          SecureField("", text: $text)
        } else {
          TextField("", text: $text)
        }
      }
      .padding(.horizontal, 20)
      .foregroundColor(.white)
    }
    .frame(height: 56)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white, lineWidth: 1)
    )
  }
}

#Preview {
  LoginView()
}
