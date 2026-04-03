import SwiftUI

struct RoamingView: View {
  @State private var rooms: [RoomObject] = []
  @State private var isLoading = false
  @State private var searchText = ""
  @Binding var isMusicPlayerActive: Bool
  var onScan: () -> Void
  var onRoomSelected: (RoomObject) -> Void

  private var filteredRooms: [RoomObject] {
    if searchText.isEmpty { return rooms }
    return rooms.filter {
      $0.name.localizedCaseInsensitiveContains(searchText)
        || ($0.ownerEmail?.localizedCaseInsensitiveContains(searchText) ?? false)
        || $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
    }
  }

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
            
            HStack(spacing: 20) {
              Button(action: {
                withAnimation(.spring()) {
                  isMusicPlayerActive.toggle()
                }
              }) {
                Image(systemName: "music.note.list")
                  .font(.system(size: 22))
                  .foregroundColor(.white)
              }
              
              if isLoading {
                ProgressView().tint(.white)
              } else {
                Button(action: onScan) {
                  HStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                      .font(.system(size: 22))
                    Text("Scan")
                      .font(.system(size: 18, weight: .medium))
                  }
                  .foregroundColor(.white)
                }
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, 20)

          // Search Bar
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor(.gray)
            TextField("Search by name, owner, or tags...", text: $searchText)
              .foregroundColor(.white)
              .autocapitalization(.none)
            if !searchText.isEmpty {
              Button(action: { searchText = "" }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.gray)
              }
            }
          }
          .padding(10)
          .background(Color.white.opacity(0.1))
          .cornerRadius(10)
          .padding(.horizontal, 24)

          if filteredRooms.isEmpty && !isLoading {
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
            if let featured = filteredRooms.first {
              RoamingCardView(room: featured, height: 320)
                .padding(.horizontal, 24)
                .onTapGesture {
                  onRoomSelected(featured)
                }
            }

            // Others
            LazyVStack(spacing: 24) {
              ForEach(filteredRooms.dropFirst()) { room in
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
        UnsplashImageView(
          query: room.tags.first ?? room.name,
          width: UIScreen.main.bounds.width - 48,
          height: height,
          contentMode: .fill
        )
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

        if room.isLocked {
          HStack(spacing: 4) {
            Image(systemName: "lock.fill")
            Text("Locked")
          }
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(.orange)
          .padding(.top, 4)
        }
      }
      .padding(20)
    }
    .frame(height: height)
    .cornerRadius(24)
    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
  }
}

#Preview {
  RoamingView(isMusicPlayerActive: .constant(false), onScan: {}, onRoomSelected: { _ in })
}
