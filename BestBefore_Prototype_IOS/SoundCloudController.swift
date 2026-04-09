import Combine
import SwiftUI

struct SoundCloudTrack: Identifiable, Equatable, Codable {
    let id: Int
    let title: String
    let user: String
    let artwork: String?
}

struct SoundCloudPlaylist: Codable {
    let id: String
    let url: String
    let title: String?
    let tracks: [SoundCloudTrack]?
}

struct OEmbedResponse: Codable {
    let title: String
    let author_name: String
    let thumbnail_url: String
}

@MainActor
class SoundCloudController: ObservableObject {
    @Published var currentTrackTitle: String = ""
    @Published var currentTrackArtist: String = ""
    @Published var currentArtworkUrl: String? = nil
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var volume: Double = 100.0 // 0 to 100

    // Playlist Support
    @Published var tracks: [SoundCloudTrack] = []
    @Published var currentIndex: Int = 0
    @Published var currentPlaylistUrl: String? = nil

    var playAction: (() -> Void)?
    var pauseAction: (() -> Void)?
    var nextAction: (() -> Void)?
    var prevAction: (() -> Void)?
    var playAtIndexAction: ((Int) -> Void)?
    var setVolumeAction: ((Double) -> Void)?

    func play() { playAction?() }
    func pause() { pauseAction?() }
    func next() { nextAction?() }
    func prev() { prevAction?() }
    func playTrack(at index: Int) { playAtIndexAction?(index) }
    func setVolume(_ value: Double) { 
        self.volume = value
        setVolumeAction?(value) 
    }

    // MARK: - Backend Integration

    /// Load SoundCloud playlist/music from backend
    func loadMusicFromBackend(roomId: String) async {
        isLoading = true
        error = nil

        do {
            let playlist = try await Database.shared.getRoomMusic(roomId: roomId)
            await MainActor.run {
                self.currentPlaylistUrl = playlist.url
                self.tracks = playlist.tracks ?? []
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load music: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    /// Save SoundCloud URL to backend
    func saveMusicToBackend(roomId: String, soundCloudUrl: String) async {
        isLoading = true
        error = nil

        do {
            try await Database.shared.updateRoomMusic(roomId: roomId, musicUrl: soundCloudUrl)
            await MainActor.run {
                self.currentPlaylistUrl = soundCloudUrl
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to save music: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Native OEmbed Metadata Fetching
    func fetchMetadata(for trackUrl: String) async {
        guard !trackUrl.isEmpty else { return }
        
        // Use OEmbed for 100% reliability and high-res recovery
        let encodedUrl = trackUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let apiUrl = URL(string: "https://soundcloud.com/oembed?url=\(encodedUrl)&format=json") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: apiUrl)
            let response = try JSONDecoder().decode(OEmbedResponse.self, from: data)
            
            await MainActor.run {
                var cleanTitle = response.title
                let artist = response.author_name
                
                // Remove "[Artist] - " prefix if present
                if cleanTitle.lowercased().hasPrefix(artist.lowercased() + " - ") {
                    cleanTitle = String(cleanTitle.dropFirst(artist.count + 3))
                }
                
                // Remove " by [Artist]" suffix if present
                if let range = cleanTitle.lowercased().range(of: " by " + artist.lowercased()) {
                    cleanTitle = String(cleanTitle[..<range.lowerBound])
                }
                
                self.currentTrackTitle = cleanTitle
                self.currentTrackArtist = artist
                
                // Force t500x500 Ultra-Res natively
                self.currentArtworkUrl = response.thumbnail_url
                    .replacingOccurrences(of: "large.jpg", with: "t500x500.jpg")
                    .replacingOccurrences(of: "crop.jpg", with: "t500x500.jpg")
                    .replacingOccurrences(of: "-large.", with: "-t500x500.")
            }
        } catch {
            print("Native metadata fetch failed: \(error)")
            // Fallback to existing data if available
        }
    }
}
