import SwiftUI
import UIKit

struct ShareRoomSheet: View {
  @Environment(\.dismiss) var dismiss
  let room: RoomObject

  @State private var email: String = ""
  @State private var passcode: String? = nil
  @State private var isLoading = false
  @State private var isLoadingQR = true
  @State private var errorMessage: String?
  @State private var qrImage: UIImage? = nil

  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 30) {
          // QR Code
          VStack(spacing: 16) {
            if isLoadingQR {
              ProgressView()
                .frame(width: 200, height: 200)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
            } else if let image = qrImage {
              Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
            } else {
              VStack {
                Image(systemName: "exclamationmark.triangle")
                  .font(.system(size: 40))
                  .foregroundColor(.red)
                Text("Failed to load QR")
                  .font(.system(size: 12))
                  .foregroundColor(.red)
              }
              .frame(width: 200, height: 200)
              .background(Color.white.opacity(0.1))
              .cornerRadius(16)
            }

            Text("Scan to view room details")
              .font(.system(size: 14))
              .foregroundColor(.gray)

            Button(action: {
              UIPasteboard.general.string = "bestbefore://room/\(room.id)"
            }) {
              Label("Copy Share Link", systemImage: "doc.on.doc.fill")
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
          }
          .padding(.top, 40)

          if let code = passcode {
            // Secret Code Section
            VStack(spacing: 12) {
              Text("Your Passcode")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

              Text(code)
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)

              Text("Tell \(email) to select this code on their screen.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }
          } else {
            // Email Input Section
            VStack(alignment: .leading, spacing: 12) {
              Text("Invite via Handshake")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

              if let currError = errorMessage {
                Text(currError)
                  .font(.system(size: 14))
                  .foregroundColor(.red)
              }

              TextField("Friend's Email Address", text: $email)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .font(.system(size: 16))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

              Button(action: sendInvite) {
                HStack {
                  if isLoading {
                    ProgressView().tint(.white)
                  } else {
                    Text("Send Handshake Request")
                      .fontWeight(.bold)
                  }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(email.isEmpty || isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
              }
              .disabled(email.isEmpty || isLoading)
              .padding(.top, 8)
            }
            .padding(.horizontal, 32)
          }

          Spacer()
        }
      }
      .navigationTitle("Share Room")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.gray)
          }
        }
      }
      .preferredColorScheme(.dark)
      .task {
        await fetchQRCode()
      }
    }
  }

  private func fetchQRCode() async {
    isLoadingQR = true
    do {
      let base64StringWithPrefix = try await Database.shared.getRoomQRCode(roomId: room.id)
      // Backend returns data:image/png;base64,.....
      let base64String = base64StringWithPrefix.replacingOccurrences(
        of: "data:image/png;base64,", with: "")

      if let data = Data(base64Encoded: base64String), let uiImage = UIImage(data: data) {
        await MainActor.run {
          self.qrImage = uiImage
          self.isLoadingQR = false
        }
      } else {
        await MainActor.run {
          self.isLoadingQR = false
        }
      }
    } catch {
      print("[DEBUG] Failed to fetch QR: \(error)")
      await MainActor.run {
        self.isLoadingQR = false
      }
    }
  }

  private func sendInvite() {
    guard !email.isEmpty else { return }
    isLoading = true
    errorMessage = nil

    Task {
      do {
        let code = try await Database.shared.createHandshakeInvite(
          roomId: room.id, inviteeEmail: email)
        await MainActor.run {
          self.passcode = code
          self.isLoading = false
        }
      } catch {
        await MainActor.run {
          self.errorMessage = error.localizedDescription
          self.isLoading = false
        }
      }
    }
  }
}
