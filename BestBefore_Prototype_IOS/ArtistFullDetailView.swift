import SwiftUI

struct ArtistFullDetailView: View {
  let room: RoomObject
  @Binding var isPresented: Bool
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      
      VStack(spacing: 0) {
        // 1. Room Title (Header)
        Text(room.name)
          .font(.system(size: 26, weight: .bold))
          .foregroundColor(.white)
          .padding(.top, 60) // Safe area top
          .padding(.bottom, 20)
        
        // 2. Focused Card representation
        ZStack {
          // Broad Halo Glow - Clipped to prevent frame expansion
          RoundedRectangle(cornerRadius: 32)
            .fill(room.themeColor)
            .blur(radius: 40)
            .opacity(0.4)
            .scaleEffect(1.1)
          
          // The Card itself
          if let imageName = room.imageName, let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 240, height: 360)
              .clipShape(RoundedRectangle(cornerRadius: 32))
          } else {
            RoundedRectangle(cornerRadius: 32)
              .fill(room.themeColor.opacity(0.3))
              .frame(width: 240, height: 360)
              .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.white.opacity(0.5)))
          }
        }
        .frame(height: 380) // Fixed height to lock spacing
        
        // 3. Artist Detail Block (Footer area)
        VStack(alignment: .leading, spacing: 10) {
          // Profile + Username
          HStack(spacing: 12) {
            Circle()
              .fill(room.themeColor)
              .frame(width: 44, height: 44)
              .overlay(Image(systemName: "person.fill").foregroundColor(.black))
            
            Text("@\(room.ownerEmail?.components(separatedBy: "@").first ?? "artist")")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)
          }
          
          // Full Description
          if let desc = room.description {
            Text(desc)
              .font(.system(size: 14))
              .foregroundColor(.white.opacity(0.9))
              .lineSpacing(4)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          
          // See Less Button
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              isPresented = false
            }
          }) {
            Text("See Less")
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(.white)
          }
          .padding(.top, 4)
          
          // Tags Section
          VStack(alignment: .leading, spacing: 6) {
            Text("Tags")
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(.gray)
            
            HStack(spacing: 8) {
              ForEach(room.tags, id: \.self) { tag in
                Text("#\(tag)")
                  .font(.system(size: 12, weight: .semibold))
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)
                  .background(Color.white.opacity(0.12))
                  .foregroundColor(.white)
                  .cornerRadius(12)
              }
            }
          }
          .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .padding(.top, 20) // Balanced with title's bottom padding
        
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
  }
}

#Preview {
  ArtistFullDetailView(
    room: RoomObject(name: "Squad Goals", ownerEmail: nil, description: "Best crew, best memories. Living proof that weekends are always better together.", tags: ["friends", "party"]),
    isPresented: .constant(true)
  )
}
