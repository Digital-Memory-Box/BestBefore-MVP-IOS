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
  let isMenuHidden: Bool
  var soundCloudControllers: [String: SoundCloudController] = [:]
  var onProximityChange: ((Int, Double) -> Void)? = nil

  @State private var dragOffset: CGFloat = 0

  var body: some View {
    let cardWidth: CGFloat = 110
    let spacing: CGFloat = 0
    
    ZStack {
      ForEach(Array(rooms.enumerated()), id: \.element.id) { index, room in
        let offset = CGFloat(index - selectedIndex)
        // Horizontal translation logic
        let translationX = offset * (cardWidth + spacing) + dragOffset
        
        let absOffset = abs(offset + dragOffset / (cardWidth + spacing))
        
        // Scale and Alpha logic based on distance from center
        let scale = 1.0 - min(absOffset * 0.15, 0.4)
        let alpha = 1.0 - min(absOffset * 0.5, 0.8)

        // Glow intensity based on distance from center
        let glowOpacity = max(0, 1.0 - abs(offset + dragOffset / (cardWidth + spacing)))

        StackCardView(room: room, glowOpacity: glowOpacity, scController: soundCloudControllers[room.id])
          .scaleEffect(scale)
          .opacity(alpha)
          .offset(x: translationX)
          .zIndex(Double(rooms.count) - Double(absOffset))
      }
    }
    .frame(maxWidth: .infinity)
    .offset(x: isMenuHidden ? 0 : -45) // Slightly more left for better balance
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isMenuHidden)
    .gesture(
      DragGesture()
        .onChanged { gesture in
          dragOffset = gesture.translation.width
          
          // Report proximity for all visible cards
          let cardWidth: CGFloat = 110
          let spacing: CGFloat = 0
          for (index, _) in rooms.enumerated() {
            let offset = CGFloat(index - selectedIndex)
            let absOffset = abs(Double(offset) + Double(dragOffset) / Double(cardWidth + spacing))
            onProximityChange?(index, absOffset)
          }
        }
        .onEnded { gesture in
          let threshold: CGFloat = 50
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if gesture.translation.width > threshold && selectedIndex > 0 {
              selectedIndex -= 1
            } else if gesture.translation.width < -threshold && selectedIndex < rooms.count - 1 {
              selectedIndex += 1
            }
            dragOffset = 0
            
            // Final proximity report
            for (index, _) in rooms.enumerated() {
                let offset = CGFloat(index - selectedIndex)
                onProximityChange?(index, abs(Double(offset)))
            }
          }
        }
    )
  }
}

struct StackCardView: View {
  let room: RoomObject
  let glowOpacity: Double
  var scController: SoundCloudController? = nil

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      // Card Background
      if let imageName = room.imageName, let uiImage = UIImage(contentsOfFile: imageName) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 180, height: 300)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 32))
      } else {
        UnsplashImageView(
          query: room.tags.first ?? room.name,
          width: 180, height: 300,
          contentMode: .fill
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
      }
      
      // Embedded Invisible SoundCloud Engine
      if let musicUrl = room.backgroundMusic, !musicUrl.isEmpty, let controller = scController {
          SoundCloudPlayerView(
              soundCloudUrl: musicUrl,
              autoPlay: false,
              isController: true,
              controller: controller
          )
          .frame(width: 1, height: 1)
          .opacity(0.01)
          .allowsHitTesting(false)
      }
    }
    .frame(width: 180, height: 300)
    .background(
      ZStack {
        // Core Glow (Broad - Final Polish)
        RoundedRectangle(cornerRadius: 32)
          .fill(room.themeColor)
          .blur(radius: 35)
          .opacity(glowOpacity * 0.35)
          .scaleEffect(1.2)
        
        // Vibrant Inner Glow (Subtle - Final Polish)
        RoundedRectangle(cornerRadius: 32)
          .fill(room.themeColor)
          .blur(radius: 15)
          .opacity(glowOpacity * 0.5)
          .scaleEffect(1.03)
      }
    )
    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
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
      selectedIndex: .constant(1),
      isMenuHidden: false,
      soundCloudControllers: [:]
    )
  }
}
