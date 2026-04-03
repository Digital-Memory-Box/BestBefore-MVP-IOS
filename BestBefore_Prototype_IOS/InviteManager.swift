import SwiftUI
import FirebaseAuth
import Combine

@MainActor
class InviteManager: ObservableObject {
    static let shared = InviteManager()
    
    @Published var pendingInvites: [HandshakeInviteDTO] = []
    @Published var activeInvite: HandshakeInviteDTO? = nil
    @Published var deepLinkedRoomId: String? = nil
    
    private var timer: Timer?
    
    private init() {
        startPolling()
    }
    
    func startPolling() {
        // Poll every 5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchPendingInvites()
            }
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchPendingInvites() async {
        guard Auth.auth().currentUser != nil else { return }
        
        do {
            let invites = try await Database.shared.getPendingHandshakeInvites()
            
            // If we have an active invite, don't interrupt the user unless it expired
            if activeInvite == nil, let first = invites.first {
                self.activeInvite = first
            }
            
            self.pendingInvites = invites
        } catch {
            print("[InviteManager] Failed to fetch pending invites: \(error)")
        }
    }
    
    func clearActiveInvite() {
        self.activeInvite = nil
    }
}
