import SwiftUI

struct SignupView: View {
  @State private var name = ""
  @State private var email = ""
  @State private var password = ""
  @State private var isLoading = false
  @State private var errorMessage: String?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      AnimatedBackgroundView()

      VStack(spacing: 40) {
        Text("Create Account")
          .font(.system(size: 40, weight: .bold))
          .foregroundColor(.white)
          .padding(.top, 60)

        VStack(spacing: 20) {
          OutlinedInput(placeholder: "name", text: $name)
          OutlinedInput(placeholder: "email", text: $email)
          OutlinedInput(placeholder: "password", text: $password, isSecure: true)
        }
        .padding(.horizontal, 40)

        if let error = errorMessage {
          Text(error)
            .foregroundColor(.red)
            .font(.caption)
        }

        Spacer()

        Button(action: { dismiss() }) {
          Text("already have an account? login")
            .foregroundColor(.white)
            .font(.system(size: 16))
        }
        .padding(.bottom, 60)
      }

      // Orb Menu as a "Signup" Trigger
      VStack {
        Spacer()
        HStack {
          Spacer()
          ZStack(alignment: .leading) {
            OrbMenuPremium(
              onAdd: performSignup,
              onChat: {},
              onProfile: {},
              onSearch: {}
            )

            Text("Signup")
              .font(.system(size: 24, weight: .bold))
              .foregroundColor(.white)
              .offset(x: -70)
          }
          .contentShape(Rectangle())
          .onTapGesture {
            print("Signup triggered for: \(email)")
            performSignup()
          }
        }
      }
    }
  }

  private func performSignup() {
    guard !email.isEmpty && !password.isEmpty else {
      errorMessage = "Please enter email and password"
      return
    }

    isLoading = true
    errorMessage = nil

    // Check Allowed Email/Domain
    if !EmailValidator.shared.isEmailAllowed(email) {
      errorMessage = "Access Restricted: This email domain is not authorized."
      isLoading = false
      return
    }

    Task {
      do {
        _ = try await AuthService.shared.signup(name: name, email: email, password: password)
        await MainActor.run {
          dismiss()  // Go back to login or just log them in?
          // Usually signup logs you in automatically in this AuthService
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

#Preview {
  SignupView()
}
