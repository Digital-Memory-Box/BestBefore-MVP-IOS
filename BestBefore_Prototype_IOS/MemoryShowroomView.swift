import SwiftUI

struct MemoryShowroomView: View {
  let memories: [MemoryItem]
  @Environment(\.dismiss) var dismiss
  @State private var selectedMemory: MemoryItem? = nil

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 0) {
        // Simple Header
        HStack {
          Text("Showroom")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
          Spacer()
          Button("Close") {
            dismiss()
          }
          .foregroundColor(.blue)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)

        ScrollView {
          if memories.isEmpty {
            VStack(spacing: 20) {
              Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
              Text("No memories in this room yet.")
                .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, minHeight: 400)
          } else {
            // Masonry-style Grid
            LazyVGrid(
              columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
              spacing: 16
            ) {
              ForEach(memories) { memory in
                Button(action: { selectedMemory = memory }) {
                  ShowroomCard(memory: memory)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.horizontal, 24)
          }
          Spacer(minLength: 50)
        }
      }

      // Immersive Detail Overlay
      if let memory = selectedMemory {
        MemoryDetailOverlay(memory: memory) {
          selectedMemory = nil
        }
        .transition(
          .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 1.05))))
      }
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedMemory != nil)
  }
}

struct MemoryDetailOverlay: View {
  let memory: MemoryItem
  var onDismiss: () -> Void

  var body: some View {
    ZStack {
      // Backdrop blur
      Color.black.opacity(0.8)
        .ignoresSafeArea()
        .onTapGesture { onDismiss() }

      VStack(spacing: 24) {
        // Content Area
        ZStack {
          RoundedRectangle(cornerRadius: 32)
            .fill(Color.white.opacity(0.05))
            .background(.ultraThinMaterial)

          VStack(spacing: 0) {
            // Memory Header
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(memory.title)
                  .font(.system(size: 22, weight: .bold))
                  .foregroundColor(.white)
                Text(timeAgoString(from: memory.date))
                  .font(.system(size: 14))
                  .foregroundColor(.white.opacity(0.5))
              }
              Spacer()
              Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                  .font(.system(size: 32))
                  .foregroundColor(.white.opacity(0.3))
              }
            }
            .padding(24)

            // Dynamic Content
            ScrollView {
              VStack(spacing: 20) {
                if let image = decodedImage {
                  Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                } else if memory.type == .photo {
                  VStack(spacing: 20) {
                    Image(systemName: "photo.fill")
                      .font(.system(size: 80))
                      .foregroundColor(.blue.opacity(0.3))
                    Text("Loading image...")
                      .foregroundColor(.white.opacity(0.4))
                  }
                  .frame(height: 200)
                } else if memory.type == .note {
                  Text(memory.content ?? "No content")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                } else if memory.type == .audio {
                  VStack(spacing: 20) {
                    Image(systemName: "waveform")
                      .font(.system(size: 60))
                      .foregroundColor(.orange)
                    Text("Voice Memory")
                      .font(.headline)
                      .foregroundColor(.white)
                  }
                  .frame(height: 200)
                } else if memory.type == .video {
                  VStack(spacing: 20) {
                    Image(systemName: "film.fill")
                      .font(.system(size: 60))
                      .foregroundColor(.orange)
                    Text("Video Memory")
                      .font(.headline)
                      .foregroundColor(.white)
                  }
                  .frame(height: 200)
                } else if memory.type == .music {
                  VStack(spacing: 20) {
                    Image(systemName: "music.note")
                      .font(.system(size: 60))
                      .foregroundColor(.pink)
                    Text("Music Memory")
                      .font(.headline)
                      .foregroundColor(.white)
                  }
                  .frame(height: 200)
                }
              }
              .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
          }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .padding(.horizontal, 20)
        .overlay(
          RoundedRectangle(cornerRadius: 32)
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
            .padding(.horizontal, 20)
        )
      }
    }
  }

  private var decodedImage: UIImage? {
    guard memory.type == .photo, let content = memory.content,
      let data = Data(base64Encoded: content, options: .ignoreUnknownCharacters)
    else { return nil }
    return UIImage(data: data)
  }

  private func timeAgoString(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
  }
}

struct ShowroomCard: View {
  let memory: MemoryItem

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Visual Content
      ZStack {
        RoundedRectangle(cornerRadius: 16)
          .fill(typeColor.opacity(0.1))
          .frame(height: 120)

        if let image = decodedImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: 120)
            .cornerRadius(16)
            .clipped()
        } else {
          Image(systemName: memory.type.icon)
            .font(.system(size: 40))
            .foregroundColor(typeColor)
        }
      }

      // Title & Date
      VStack(alignment: .leading, spacing: 4) {
        Text(memory.title)
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.white)
          .lineLimit(1)

        Text(timeAgoString(from: memory.date))
          .font(.system(size: 10))
          .foregroundColor(.gray)
      }
      .padding(.horizontal, 4)
    }
    .padding(8)
    .background(Color.white.opacity(0.05))
    .cornerRadius(20)
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.white.opacity(0.1), lineWidth: 1)
    )
  }

  private var decodedImage: UIImage? {
    guard memory.type == .photo, let content = memory.content,
      let data = Data(base64Encoded: content, options: .ignoreUnknownCharacters)
    else { return nil }
    return UIImage(data: data)
  }

  private var typeColor: Color {
    switch memory.type {
    case .photo: return .blue
    case .note: return .purple
    case .audio: return .orange
    case .video: return .orange
    case .music: return .pink
    }
  }

  private func timeAgoString(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
  }
}

#Preview {
  MemoryShowroomView(memories: [])
}
