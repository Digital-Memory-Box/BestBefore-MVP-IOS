import FirebaseAuth
import SwiftUI

struct VerificationView: View {
  var onVerified: () -> Void
  @State private var isChecking = false
  @State private var errorMessage: String?
  @State private var showResendSuccess = false

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 30) {
        Spacer()

        Image(systemName: "envelope.badge")
          .font(.system(size: 70))
          .foregroundStyle(.white)

        Text("Verify your Email")
          .font(.title)
          .fontWeight(.bold)
          .foregroundStyle(.white)

        if let email = Auth.auth().currentUser?.email {
          Text("We sent a verification link to:\n\(email)")
            .multilineTextAlignment(.center)
            .foregroundStyle(.gray)
            .padding(.horizontal)
        }

        Text("Please check your inbox and click the link to verify your account.")
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .foregroundStyle(.gray)
          .padding(.horizontal)

        if let errorMessage = errorMessage {
          Text(errorMessage)
            .foregroundStyle(.red)
            .font(.caption)
            .multilineTextAlignment(.center)
        }

        if showResendSuccess {
          Text("Email sent!")
            .foregroundStyle(.green)
            .font(.caption)
        }

        Spacer()

        Button(action: checkVerification) {
          if isChecking {
            ProgressView()
              .tint(.black)
          } else {
            Text("I Verified My Email")
              .fontWeight(.semibold)
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .foregroundColor(.black)
        .padding(.horizontal, 40)
        .disabled(isChecking)

        Button(action: resendEmail) {
          Text("Resend Verification Email")
            .font(.subheadline)
            .foregroundColor(.white)
            .underline()
        }

        Button("Log Out") {
          AuthService.shared.clearSession()
        }
        .font(.caption)
        .foregroundColor(.gray)
        .padding(.top, 20)

        Spacer()
      }
    }
  }

  func checkVerification() {
    isChecking = true
    errorMessage = nil

    Task {
      do {
        // Reload user to get fresh emailVerified status
        try await Auth.auth().currentUser?.reload()

        if Auth.auth().currentUser?.isEmailVerified == true {
          DispatchQueue.main.async {
            onVerified()
          }
        } else {
          DispatchQueue.main.async {
            errorMessage = "Email not verified yet. Please click the link in your email."
            isChecking = false
          }
        }
      } catch {
        DispatchQueue.main.async {
          errorMessage = error.localizedDescription
          isChecking = false
        }
      }
    }
  }

  func resendEmail() {
    Task {
      do {
        try await Auth.auth().currentUser?.sendEmailVerification()
        DispatchQueue.main.async {
          showResendSuccess = true
          // Hide success msg after 3s
          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showResendSuccess = false
          }
        }
      } catch {
        DispatchQueue.main.async {
          errorMessage = error.localizedDescription
        }
      }
    }
  }
}

#Preview {
  VerificationView(onVerified: {})
}
