import SwiftUI

struct RoamingView: View {
  @State private var rooms: [RoomObject] = []
  @State private var isLoading = false

  var onRoomSelected: (RoomObject) -> Void

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header
          HStack {
            Text("Roaming")
              .font(.system(size: 32, weight: .bold))
              .foregroundColor(.white)
            Spacer()
            if isLoading {
              ProgressView().tint(.white)
            } else {
              Text("Discover")
                .font(.system(size: 22))
                .foregroundColor(.gray)
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, 20)

          if rooms.isEmpty && !isLoading {
            VStack(spacing: 20) {
              Image(systemName: "globe")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.3))
              Text("No public rooms discovered yet.")
                .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 100)
          } else {
            // Featured
            if let featured = rooms.first {
              RoamingCardView(room: featured, height: 320)
                .padding(.horizontal, 24)
                .onTapGesture {
                  onRoomSelected(featured)
                }
            }

            // Others
            LazyVStack(spacing: 24) {
              ForEach(rooms.dropFirst()) { room in
                RoamingCardView(room: room, height: 220)
                  .padding(.horizontal, 24)
                  .onTapGesture {
                    onRoomSelected(room)
                  }
              }
            }
            .padding(.bottom, 100)
          }
        }
      }
      .onAppear(perform: fetchRandomPublicRooms)

    }
  }

  private func fetchRandomPublicRooms() {
    isLoading = true
    Task {
      do {
        let docs = try await Database.shared.getDiscoverableRooms()
        await MainActor.run {
          self.rooms = docs
          self.isLoading = false
        }
      } catch {
        print("Discovery failed: \(error)")
        await MainActor.run { self.isLoading = false }
      }
    }
  }
}

struct RoamingCardView: View {
  let room: RoomObject
  var height: CGFloat

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      if let imageName = room.imageName,
        let uiImage = UIImage(contentsOfFile: imageName)
      {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(height: height)
          .clipped()
      } else {
        RoundedRectangle(cornerRadius: 24)
          .fill(Color.gray.opacity(0.3))
          .frame(height: height)
      }

      // Gradient Overlay
      RoundedRectangle(cornerRadius: 24)
        .fill(
          LinearGradient(
            colors: [.clear, .black.opacity(0.8)],
            startPoint: .center,
            endPoint: .bottom
          )
        )

      VStack(alignment: .leading, spacing: 4) {
        Text(room.name)
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.white)

        Text(
          "Time Capsule: \(room.capsuleDurationDays)d \(room.capsuleDurationHours)h \(room.capsuleDurationMinutes)m"
        )
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.8))

        Text("Click to view details >")
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(.white.opacity(0.6))
          .padding(.top, 8)
      }
      .padding(20)
    }
    .frame(height: height)
    .cornerRadius(24)
    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
  }
}

#Preview {
  RoamingView(onRoomSelected: { _ in })
}
