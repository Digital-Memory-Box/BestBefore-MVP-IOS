import SwiftUI

struct PlaylistSheetView: View {
    @ObservedObject var controller: SoundCloudController
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Playlist")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                if controller.tracks.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView().tint(.white)
                        Text("Loading playlist...")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(controller.tracks) { track in
                                Button(action: {
                                    controller.playTrack(at: track.id)
                                }) {
                                    TrackRow(track: track, isPlaying: controller.currentIndex == track.id)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }
}

struct TrackRow: View {
    let track: SoundCloudTrack
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Artwork
            ZStack {
                if let urlString = track.artwork, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.white.opacity(0.1)
                    }
                } else {
                    Color.white.opacity(0.1)
                    Image(systemName: "music.note")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isPlaying ? .blue : .white)
                    .lineLimit(1)
                
                Text(track.user)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isPlaying {
                Image(systemName: "waveform")
                    .foregroundColor(.blue)
                    .font(.system(size: 14, weight: .bold))
            }
        }
        .padding(12)
        .background(isPlaying ? Color.blue.opacity(0.1) : Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPlaying ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PlaylistSheetView(controller: SoundCloudController())
    }
}
