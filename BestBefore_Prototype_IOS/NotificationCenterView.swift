import SwiftUI

struct NotificationCenterView: View {
    @Environment(\.dismiss) var dismiss
    let rooms: [RoomObject]
    
    // In a real app, notifications would likely come from a dedicated backend endpoint.
    // For now, we derive them from room collaborator data as requested.
    var notifications: [NotificationItem] {
        var items: [NotificationItem] = []
        for room in rooms {
            // --- Join Notifications ---
            for collaborator in room.collaborators {
                if collaborator.email != room.ownerEmail {
                    items.append(NotificationItem(
                        userName: collaborator.email,
                        roomName: room.name,
                        timestamp: room.createdAt,
                        type: .joinedRoom
                    ))
                }
            }
            
            // --- Unlock Notifications ---
            if let unlockDate = room.unlockDate, unlockDate <= Date() {
                items.append(NotificationItem(
                    userName: "System",
                    roomName: room.name,
                    timestamp: unlockDate,
                    type: .roomUnlocked
                ))
            }
        }
        return items.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Notifications")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    if notifications.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.2))
                            Text("No activity yet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                            Text("When people join your rooms, you'll see it here.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(notifications) { notification in
                                    NotificationRow(notification: notification)
                                        .padding(.horizontal, 24)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(notification.type == .joinedRoom ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: notification.type == .joinedRoom ? "person.fill.badge.plus" : "lock.open.fill")
                    .foregroundColor(notification.type == .joinedRoom ? .blue : .green)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if notification.type == .joinedRoom {
                        Text(notification.userName)
                            .fontWeight(.bold) +
                        Text(" joined ") +
                        Text(notification.roomName)
                            .fontWeight(.bold)
                    } else {
                        Text("Room ") +
                        Text(notification.roomName)
                            .fontWeight(.bold) +
                        Text(" is now unlocked!")
                    }
                }
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(2)
                
                Text(notification.timestamp, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    NotificationCenterView(rooms: [
        RoomObject(name: "Summer Trip", ownerEmail: "owner@me.com", collaborators: [Collaborator(email: "friend@me.com", role: .contributor)]),
        RoomObject(name: "Music Jams", ownerEmail: "owner@me.com", collaborators: [Collaborator(email: "alex@me.com", role: .contributor)])
    ])
}
