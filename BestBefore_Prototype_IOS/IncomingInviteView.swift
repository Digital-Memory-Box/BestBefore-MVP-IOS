import SwiftUI

struct IncomingInviteView: View {
    let invite: HandshakeInviteDTO
    @ObservedObject var inviteManager: InviteManager
    
    @State private var options: [String] = []
    @State private var errorMessage: String?
    @State private var isAccepting = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                }
                
                // Text
                VStack(spacing: 12) {
                    Text("You've been invited!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(invite.inviterEmail) wants to share a private room with you.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Verification Codes
                VStack(spacing: 16) {
                    Text("Select the number on their screen to enter:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 24) {
                        ForEach(options, id: \.self) { code in
                            Button {
                                acceptInvite(code: code)
                            } label: {
                                Text(code)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .frame(width: 80, height: 80)
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                    )
                            }
                            .disabled(isAccepting)
                        }
                    }
                    
                    if isAccepting {
                        ProgressView().tint(.white)
                            .padding(.top, 16)
                    }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                
                Spacer()
                
                Button("Dismiss") {
                    inviteManager.clearActiveInvite()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            generateOptions()
        }
    }
    
    private func generateOptions() {
        var opts: Set<String> = [invite.passcode]
        while opts.count < 3 {
            let rand = String(format: "%02d", Int.random(in: 10...99))
            opts.insert(rand)
        }
        self.options = Array(opts).shuffled()
    }
    
    private func acceptInvite(code: String) {

        
        isAccepting = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await Database.shared.acceptHandshakeInvite(inviteId: invite._id, passcode: code)
                await MainActor.run {
                    self.isAccepting = false
                    inviteManager.clearActiveInvite()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isAccepting = false
                }
            }
        }
    }
}
