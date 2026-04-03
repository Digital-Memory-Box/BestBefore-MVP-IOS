import Foundation

struct NotificationItem: Identifiable, Hashable {
    let id: String = UUID().uuidString
    let userName: String
    let roomName: String
    let timestamp: Date
    let type: NotificationType
    
    enum NotificationType {
        case joinedRoom
        case roomUnlocked
    }
}
