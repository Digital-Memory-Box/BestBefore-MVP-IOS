import SwiftUI

struct LinkRoomSheet: View {
  @Binding var currentRoom: RoomObject
  var onLinked: (RoomObject) -> Void
  @Environment(\.dismiss) private var dismiss

  @State private var availableRooms: [RoomObject] = []
  @State private var filteredRooms: [RoomObject] = []
  @State private var searchText = ""
  @State private var isLoading = false
  @State private var isLinking = false
  @State private var errorMessage: String?

  private var accentColor: Color {
    if let hex = AuthService.shared.currentUser?.accentColor {
      return Color(hex: hex)
    }
    return .blue
  }

  var body: some View {
    NavigationView {
      ZStack {
        Color.black.ignoresSafeArea()

        VStack {
          if isLoading {
            Spacer()
            ProgressView()
              .tint(.white)
            Spacer()
          } else if let error = errorMessage {
            Spacer()
            Text("Error: \(error)")
              .foregroundColor(.red)
              .multilineTextAlignment(.center)
              .padding()
            Spacer()
          } else if availableRooms.isEmpty {
            Spacer()
            VStack(spacing: 12) {
              Image(systemName: "link.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.4))
              Text("No available rooms to link.")
                .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
          } else {
            // Search Bar
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
              TextField("Search rooms...", text: $searchText)
                .foregroundColor(.white)
                .onChange(of: searchText) { _, newValue in
                  filterRooms(query: newValue)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 10)

            ScrollView {
              LazyVStack(spacing: 16) {
                ForEach(filteredRooms, id: \.id) { room in
                  HStack {
                    RoundedRectangle(cornerRadius: 8)
                      .fill(Color(hex: room.theme) ?? .blue)
                      .frame(width: 60, height: 60)
                      .overlay(
                        Text(String(room.name.prefix(1)).uppercased())
                          .font(.title2.bold())
                          .foregroundColor(.white)
                      )

                    VStack(alignment: .leading, spacing: 4) {
                      Text(room.name)
                        .font(.headline)
                        .foregroundColor(.white)
                      if room.isTimeCapsule {
                        Text("Time Capsule")
                          .font(.caption)
                          .foregroundColor(.orange)
                      }
                    }
                    .padding(.leading, 8)

                    Spacer()

                    Button(action: {
                      linkRoom(targetRoom: room)
                    }) {
                      if isLinking {
                        ProgressView().tint(.white)
                      } else {
                        Image(systemName: "link")
                          .font(.headline)
                          .foregroundColor(.white)
                          .padding(8)
                          .background(accentColor)
                          .clipShape(Circle())
                      }
                    }
                    .disabled(isLinking)
                  }
                  .padding()
                  .background(Color.white.opacity(0.05))
                  .cornerRadius(16)
                  .padding(.horizontal)
                }
              }
              .padding(.vertical)
            }
          }
        }
      }
      .navigationTitle("Add Connection")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.white)
        }
      }
      .task {
        await fetchAvailableRooms()
      }
    }
    .preferredColorScheme(.dark)
  }

  private func fetchAvailableRooms() async {
    isLoading = true
    errorMessage = nil
    do {
      let myRooms = try await Database.shared.getAllRooms()
      let publicRooms = try await Database.shared.getDiscoverableRooms()
      let allFound = myRooms + publicRooms

      let existingLinks = Set(currentRoom.linkedRooms.map { $0.roomId })

      // Filter out self and already linked rooms, and dedup
      var unique = [RoomObject]()
      var seen = Set<String>()
      for r in allFound {
        if r.id != currentRoom.id && !existingLinks.contains(r.id) && !seen.contains(r.id) {
          seen.insert(r.id)
          unique.append(r)
        }
      }

      await MainActor.run {
        self.availableRooms = unique
        self.filteredRooms = unique
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.errorMessage = error.localizedDescription
        self.isLoading = false
      }
    }
  }

  private func filterRooms(query: String) {
    if query.isEmpty {
      filteredRooms = availableRooms
    } else {
      filteredRooms = availableRooms.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
  }

  private func linkRoom(targetRoom: RoomObject) {
    isLinking = true
    Task {
      do {
        try await Database.shared.addLink(roomId: currentRoom.id, targetRoomId: targetRoom.id)
        print("[DEBUG] Link added successfully")

        // Update local object blindly for faster UI
        var newRoom = currentRoom
        let newLink = LinkedRoom(roomId: targetRoom.id, type: "manual")
        newRoom.linkedRooms.append(newLink)

        await MainActor.run {
          self.isLinking = false
          self.onLinked(newRoom)
          dismiss()
        }
      } catch {
        print("[DEBUG] Failed to link room: \(error)")
        await MainActor.run {
          self.errorMessage = "Failed to add connection."
          self.isLinking = false
        }
      }
    }
  }
}
