import SwiftUI

// Fetches a photo URL from Unsplash API based on a tag query
struct UnsplashImageView: View {
  let query: String
  let width: CGFloat
  let height: CGFloat
  let contentMode: ContentMode

  @State private var imageURL: URL? = nil

  private static let clientID = "HrmrfwL1B9laPyoLeEA6_I5Nfm08GvRnEQL-OLqDeNA"

  var body: some View {
    Group {
      if let url = imageURL {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image.resizable().aspectRatio(contentMode: contentMode)
          default:
            placeholder
          }
        }
        .frame(width: width, height: height)
        .clipped()
      } else {
        placeholder
          .frame(width: width, height: height)
      }
    }
    .task(id: query) {
      await fetchImageURL()
    }
  }

  private var placeholder: some View {
    RoundedRectangle(cornerRadius: 24)
      .fill(LinearGradient(
        colors: [Color(red: 0.1, green: 0.1, blue: 0.18), Color(red: 0.08, green: 0.13, blue: 0.24)],
        startPoint: .top, endPoint: .bottom
      ))
  }

  private func fetchImageURL() async {
    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "memory"
    guard let apiURL = URL(string: "https://api.unsplash.com/photos/random?query=\(encoded)&client_id=\(Self.clientID)") else { return }
    do {
      let (data, _) = try await URLSession.shared.data(from: apiURL)
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
         let urls = json["urls"] as? [String: Any],
         let regular = urls["regular"] as? String,
         let url = URL(string: regular) {
        await MainActor.run { imageURL = url }
      }
    } catch {}
  }
}

struct CardStackView: View {
  let rooms: [RoomObject]
  @Binding var selectedIndex: Int

  @State private var dragOffset: CGFloat = 0

  var body: some View {
    ZStack {
      ForEach(Array(rooms.enumerated()), id: \.element.id) { index, room in
        let offset = index - selectedIndex
        let absOffset = abs(offset)

        // Scale and Alpha logic based on distance from selectedIndex
        let scale = 1.0 - min(Double(absOffset) * 0.1, 0.3)
        let alpha = 1.0 - min(Double(absOffset) * 0.25, 0.7)
        let translationY = CGFloat(offset) * 70.0 + dragOffset

        StackCardView(room: room)
          .scaleEffect(scale)
          .opacity(alpha)
          .offset(y: translationY)
          .zIndex(Double(rooms.count - absOffset))
      }
    }
    .frame(width: 225, height: 400)
    .gesture(
      DragGesture()
        .onChanged { gesture in
          dragOffset = gesture.translation.height
        }
        .onEnded { gesture in
          let threshold: CGFloat = 50
          withAnimation(.spring()) {
            if gesture.translation.height > threshold && selectedIndex > 0 {
              selectedIndex -= 1
            } else if gesture.translation.height < -threshold && selectedIndex < rooms.count - 1 {
              selectedIndex += 1
            }
            dragOffset = 0
          }
        }
    )
  }
}

struct StackCardView: View {
  let room: RoomObject

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      // Card Background
      if let imageName = room.imageName, let uiImage = UIImage(contentsOfFile: imageName) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 180, height: 280)
          .clipped()
      } else {
        UnsplashImageView(
          query: room.tags.first ?? room.name,
          width: 180, height: 280,
          contentMode: .fill
        )
      }

      // Subtle Overlay for text readability
      RoundedRectangle(cornerRadius: 24)
        .fill(
          LinearGradient(
            colors: [.clear, .black.opacity(0.8)],
            startPoint: .center,
            endPoint: .bottom
          )
        )

      Text(room.name)
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(.white)
        .padding(16)
    }
    .frame(width: 180, height: 280)
    .cornerRadius(24)
    .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    CardStackView(
      rooms: [
        RoomObject(name: "Room 1", ownerEmail: nil),
        RoomObject(name: "Room 2", ownerEmail: nil),
        RoomObject(name: "Room 3", ownerEmail: nil),
      ],
      selectedIndex: .constant(1)
    )
  }
}
