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

@MainActor
class SoundCloudController: ObservableObject {
    @Published var currentTrackTitle: String = "Loading..."
    @Published var currentTrackArtist: String = ""
    @Published var currentArtworkUrl: String? = nil
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    // Playlist Support
    @Published var tracks: [SoundCloudTrack] = []
    @Published var currentIndex: Int = 0
    @Published var currentPlaylistUrl: String? = nil

    var playAction: (() -> Void)?
    var pauseAction: (() -> Void)?
    var nextAction: (() -> Void)?
    var prevAction: (() -> Void)?
    var playAtIndexAction: ((Int) -> Void)?

    func play() { playAction?() }
    func pause() { pauseAction?() }
    func next() { nextAction?() }
    func prev() { prevAction?() }
    func playTrack(at index: Int) { playAtIndexAction?(index) }

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
}
