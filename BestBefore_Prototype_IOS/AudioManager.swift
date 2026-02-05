import AVFoundation
import Combine
import Foundation

final class AudioManager: NSObject, ObservableObject {
  static let shared = AudioManager()

  private var player: AVPlayer?
  private var currentTrack: String?

  private let streamPresets: [String: String] = [
    "Lofi Beats":
      "https://p.scdn.co/mp3-preview/766c5968f9a3f2560388a1e843f88be968746c0d?cid=774b29d4f13844c495f206cafdad9c86",  // High-quality Lofi sample
    "Nature Ambience": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",  // Public domain test stream
    "Chill Cafe": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    "Minimal Piano": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    "Vaporwave": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
    "Dreamy Synth": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
  ]

  override private init() {
    super.init()
    setupAudioSession()
  }

  private func setupAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("[AudioManager] Failed to set up audio session: \(error)")
    }
  }

  func playBackgroundMusic(for preset: String?) {
    guard let preset = preset, preset != "None" else {
      stopMusic()
      return
    }

    if currentTrack == preset && player?.timeControlStatus == .playing {
      return
    }

    currentTrack = preset

    // If it's a known preset, use the stream URL, otherwise treat as a direct URL string
    let streamURLString = streamPresets[preset] ?? preset
    guard let url = URL(string: streamURLString) else {
      print("[AudioManager] Invalid URL: \(streamURLString)")
      stopMusic()
      return
    }

    print("[AudioManager] Streaming from: \(url.absoluteString)")

    let playerItem = AVPlayerItem(url: url)

    if player == nil {
      player = AVPlayer(playerItem: playerItem)
    } else {
      player?.replaceCurrentItem(with: playerItem)
    }

    player?.volume = 0.5
    player?.play()

    // Loop logic for AVPlayer
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { [weak self] _ in
      self?.player?.seek(to: .zero)
      self?.player?.play()
    }
  }

  func stopMusic() {
    print("[AudioManager] Stopping music")
    player?.pause()
    player = nil
    currentTrack = nil
  }
}
