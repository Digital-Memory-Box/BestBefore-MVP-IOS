import SwiftUI

struct CustomMusicPlayerView: View {
    @ObservedObject var controller: SoundCloudController
    var isMini: Bool = false
    @State private var showingPlaylist = false
    
    var body: some View {
        VStack(spacing: isMini ? 12 : 24) {
            // Album Artwork
            ZStack {
                if let urlString = controller.currentArtworkUrl, let url = URL(string: urlString.replacingOccurrences(of: "large", with: "t500x500")) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: isMini ? 30 : 60))
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
            }
            .frame(width: isMini ? 100 : 220, height: isMini ? 100 : 220)
            .cornerRadius(isMini ? 12 : 24)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .onTapGesture {
                showingPlaylist = true
            }
            
            // Metadata
            VStack(spacing: 4) {
                Text(controller.currentTrackTitle)
                    .font(.system(size: isMini ? 14 : 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(controller.currentTrackArtist)
                    .font(.system(size: isMini ? 12 : 16))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            
            // Basic Controls
            HStack(spacing: isMini ? 25 : 40) {
                Button(action: { controller.prev() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: isMini ? 20 : 30))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    if controller.isPlaying {
                        controller.pause()
                    } else {
                        controller.play()
                    }
                }) {
                    Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: isMini ? 40 : 64))
                        .foregroundColor(.white)
                }
                
                Button(action: { controller.next() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: isMini ? 20 : 30))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(isMini ? 12 : 24)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(isMini ? 20 : 35)
        .overlay(
            RoundedRectangle(cornerRadius: isMini ? 20 : 35)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .sheet(isPresented: $showingPlaylist) {
            PlaylistSheetView(controller: controller)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CustomMusicPlayerView(controller: SoundCloudController())
    }
}
