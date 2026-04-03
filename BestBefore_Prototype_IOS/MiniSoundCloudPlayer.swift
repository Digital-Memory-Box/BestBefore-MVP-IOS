import SwiftUI

struct MiniSoundCloudPlayer: View {
    @Binding var isVisible: Bool
    @StateObject private var controller = SoundCloudController()
    let playlistUrl: String = "https://soundcloud.com/ozan-guengoer-193834135/sets/bestbefore"
    
    var body: some View {
        ZStack {
            // The Engine (Hidden)
            SoundCloudPlayerView(
                soundCloudUrl: playlistUrl,
                isController: true,
                controller: controller
            )
            .frame(width: 1, height: 1)
            .opacity(0.01)

            // The Custom UI
            HStack(spacing: 12) {
                // Dimiss button
                Button(action: {
                    withAnimation(.spring()) {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 14, weight: .bold))
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }

                // Simplified Mini View
                HStack(spacing: 12) {
                    // Small Artwork
                    ZStack {
                        if let urlString = controller.currentArtworkUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: { Color.gray.opacity(0.2) }
                        } else {
                            Color.white.opacity(0.1)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(controller.currentTrackTitle)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(controller.currentTrackArtist)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }

                    Spacer()

                    // Mini Controls
                    HStack(spacing: 15) {
                        Button(action: { controller.prev() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            if controller.isPlaying { controller.pause() } else { controller.play() }
                        }) {
                            Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { controller.next() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.trailing, 8)
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        VStack {
            Spacer()
            MiniSoundCloudPlayer(isVisible: .constant(true))
                .padding(.bottom, 100)
        }
    }
}
