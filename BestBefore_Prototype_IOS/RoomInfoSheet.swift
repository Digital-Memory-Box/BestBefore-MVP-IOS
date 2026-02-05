import SwiftUI

struct RoomInfoSheet: View {
  let room: RoomObject
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 24) {
        // Header
        HStack {
          Text("Room Details")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
          Spacer()
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.gray)
          }
        }
        .padding(.top, 20)

        Divider().background(Color.white.opacity(0.1))

        // Info Grid
        VStack(spacing: 20) {
          InfoRow(
            icon: "person.fill",
            label: "Created By",
            value: room.ownerEmail ?? "Unknown"
          )

          InfoRow(
            icon: "calendar",
            label: "Created On",
            value: formatDate(room.createdAt)
          )

          if room.isTimeCapsule {
            Divider().background(Color.white.opacity(0.1))

            Text("Time Capsule History")
              .font(.headline)
              .foregroundColor(.blue)
              .frame(maxWidth: .infinity, alignment: .leading)

            InfoRow(
              icon: "timer",
              label: "Original Duration",
              value:
                "\(room.capsuleDurationDays)d \(room.capsuleDurationHours)h \(room.capsuleDurationMinutes)m"
            )

            let unlockDate =
              Calendar.current.date(
                byAdding: .day, value: room.capsuleDurationDays, to: room.createdAt
              ) ?? room.createdAt
            // Add hours and minutes too for accuracy if needed, but simple day addition logic was in RoomObject

            InfoRow(
              icon: room.isLocked ? "lock.fill" : "lock.open.fill",
              label: "Status",
              value: room.isLocked
                ? "Locked until \(formatDate(unlockDate))"
                : "Unlocked since \(formatDate(unlockDate))"
            )
          }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)

        Spacer()
      }
      .padding(.horizontal, 24)
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

struct InfoRow: View {
  let icon: String
  let label: String
  let value: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon)
        .foregroundColor(.gray)
        .frame(width: 20)

      VStack(alignment: .leading, spacing: 4) {
        Text(label)
          .font(.caption)
          .foregroundColor(.gray)
        Text(value)
          .font(.system(size: 16))
          .foregroundColor(.white)
      }
      Spacer()
    }
  }
}
