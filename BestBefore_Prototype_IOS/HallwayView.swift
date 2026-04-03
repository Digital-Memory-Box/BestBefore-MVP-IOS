import EventKit
import SwiftUI

struct HallwayView: View {
  @State private var rooms: [RoomObject] = []
  @State private var selectedIndex = 0
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var showingAddRoom = false
  @State private var newRoomName = ""
  @State private var selectedRoomForDetail: (RoomObject, RoomDetailView.RoomContext)?
  @State private var navigateToDetail = false
  @State private var showingProfile = false
  @State private var selectedTab = 0  // 0: Roaming (Everyone), 1: Hallway (Rooming)
  @State private var searchText = ""
  @State private var selectedFilterTag: String? = nil
  @State private var showCelebrationAlert = false
  @State private var suggestedCelebrationName = ""
  @State private var showScanner = false
  @State private var showingNotifications = false
  @State private var showingMiniPlayer = false
  @EnvironmentObject var inviteManager: InviteManager

  var onLogout: () -> Void

  init(onLogout: @escaping () -> Void = {}) {
    self.onLogout = onLogout
  }

  private var accentColor: Color {
    if let hex = AuthService.shared.currentUser?.accentColor {
      return Color(hex: hex)
    }
    return .blue
  }

  private var filteredRooms: [RoomObject] {
    var result = rooms
    if !searchText.isEmpty {
      result = result.filter {
        $0.name.localizedCaseInsensitiveContains(searchText)
          || ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
      }
    }
    if let tag = selectedFilterTag {
      result = result.filter { $0.tags.contains(tag) }
    }
    return result
  }

  private let presetTags = [
    "trip", "music", "science", "party", "family", "education", "art", "gaming", "fitness", "food",
  ]

  private var allUserTags: [String] {
    presetTags
  }

  private var mainStackRooms: [RoomObject] {
    Array(filteredRooms.prefix(4))
  }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      // Hidden NavigationLink to trigger room detail
      if let (room, context) = selectedRoomForDetail {
        NavigationLink(
          destination: RoomDetailView(room: room, context: context),
          isActive: $navigateToDetail
        ) {
          EmptyView()
        }
      }

      if selectedTab == 1 {
        VStack(alignment: .leading, spacing: 0) {
          // Updated Header Area
          HStack {
            Text("Rooming")
              .font(.system(size: 32, weight: .bold))
              .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 20) {
              Button(action: {
                withAnimation(.spring()) {
                  showingMiniPlayer.toggle()
                }
              }) {
                Image(systemName: "music.note.list")
                  .font(.system(size: 22))
                  .foregroundColor(.white)
              }
              
              Button(action: { showingNotifications = true }) {
                Image(systemName: "bell.fill")
                  .font(.system(size: 22))
                  .foregroundColor(.white)
                  .overlay(
                    Circle()
                      .fill(rooms.flatMap { $0.collaborators }.count > 0 ? Color.blue : Color.clear)
                      .frame(width: 8, height: 8)
                      .offset(x: 10, y: -10)
                  )
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, 10)

          // Search and Filter Bar
          VStack(spacing: 12) {
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
              TextField("Search rooms...", text: $searchText)
                .foregroundColor(.white)
              if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                }
              }
            }
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 24)

            if !allUserTags.isEmpty {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                  Button(action: { selectedFilterTag = nil }) {
                    Text("All")
                      .font(.system(size: 14, weight: .semibold))
                      .padding(.horizontal, 16)
                      .padding(.vertical, 8)
                      .background(selectedFilterTag == nil ? accentColor : Color.white.opacity(0.1))
                      .foregroundColor(.white)
                      .cornerRadius(20)
                  }

                  ForEach(allUserTags, id: \.self) { tag in
                    Button(action: {
                      selectedFilterTag = (selectedFilterTag == tag) ? nil : tag
                    }) {
                      Text("#\(tag)")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                          selectedFilterTag == tag ? accentColor : Color.white.opacity(0.1)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                  }
                }
                .padding(.horizontal, 24)
              }
            }
          }
          .padding(.top, 10)

          if isLoading {
            Spacer()
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
              .frame(maxWidth: .infinity)
            Spacer()
          } else if filteredRooms.isEmpty {
            Spacer()
            VStack(spacing: 20) {
              Text("No rooms found")
                .foregroundColor(.gray)
              Button("Create your first room") {
                showingAddRoom = true
              }
              .foregroundColor(accentColor)
              .padding(.horizontal, 20)
              .padding(.vertical, 10)
              .background(Color.white.opacity(0.1))
              .cornerRadius(10)
            }
            .frame(maxWidth: .infinity)
            Spacer()
          } else {
            // Side-by-Side Content Area (New!)
            HStack(alignment: .center, spacing: 0) {
              // Left Side: Card Stack
              CardStackView(rooms: mainStackRooms, selectedIndex: $selectedIndex)
                .frame(width: UIScreen.main.bounds.width * 0.40)
                .onTapGesture {
                  let room = mainStackRooms[selectedIndex]
                  selectedRoomForDetail = (room, .hallway)
                  navigateToDetail = true
                }

              // Right Side: Room Info
              let selectedRoom = mainStackRooms[selectedIndex]
              VStack(alignment: .leading, spacing: 12) {
                Text(selectedRoom.name)
                  .font(.system(size: 24, weight: .bold))
                  .foregroundColor(.white)

                if selectedRoom.isTimeCapsule {
                  VStack(alignment: .leading, spacing: 2) {
                    let d = selectedRoom.capsuleDurationDays
                    let h = selectedRoom.capsuleDurationHours
                    let m = selectedRoom.capsuleDurationMinutes
                    Text("Time Capsule: \(d)d \(h)h \(m)m")
                      .font(.system(size: 14, weight: .medium))
                      .foregroundColor(.white.opacity(0.8))
                    Text(selectedRoom.isLocked ? "Timer Active" : "Unlocked")
                      .font(.system(size: 14, weight: .semibold))
                  }
                  .foregroundColor(.white)
                }

                if let description = selectedRoom.description, !description.isEmpty {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                      .font(.system(size: 14, weight: .bold))
                      .foregroundColor(.white)
                    Text(description)
                      .font(.system(size: 10))
                      .foregroundColor(Color(white: 0.7))
                      .lineLimit(4)
                    Text("> Full Description")
                      .font(.system(size: 11, weight: .bold))
                      .foregroundColor(.white)
                      .padding(.top, 4)
                  }
                  .padding(.top, 4)
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.leading, 12)
              .padding(.trailing, 80)  // Add significant padding to clear the Orb Menu

              Spacer()
            }
            .padding(.vertical, 20)

            Spacer()

          }

          Spacer()
        }
      } else if selectedTab == 0 {
        // Roaming View content
        RoamingView(
          isMusicPlayerActive: $showingMiniPlayer,
          onScan: { showScanner = true },
          onRoomSelected: { room in
            selectedRoomForDetail = (room, .hallway)
            navigateToDetail = true
          }
        )
      }

      // Bottom Nav (ZStack for consistency)
      VStack {
        Spacer()
        HallwayBottomNav(selectedTab: $selectedTab)
      }

      // Orb Menu (Premium Design)
      OrbMenuPremium(
        onAdd: { showingAddRoom = true },
        onChat: { /* Handle chat */  },
        onScan: { showScanner = true },
        onProfile: { showingProfile = true },
        onSearch: { /* Handle search */  }
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
      .zIndex(100)

      // Mini Player Overlay
      if showingMiniPlayer {
        VStack {
          Spacer()
          MiniSoundCloudPlayer(isVisible: $showingMiniPlayer)
            .padding(.bottom, 100) // Above bottom nav
        }
        .zIndex(150)
      }
    }
    .onAppear(perform: fetchRooms)
    .alert("Today's Celebration", isPresented: $showCelebrationAlert) {
      Button("Create Room") {
        createCelebrationRoom(name: suggestedCelebrationName)
        markCelebrationAsSeen(name: suggestedCelebrationName)
      }
      Button("Maybe Later", role: .cancel) {
        markCelebrationAsSeen(name: suggestedCelebrationName)
      }
    } message: {
      Text(
        "It's \(suggestedCelebrationName) today! Would you like to create a special room for this memory?"
      )
    }
    .sheet(isPresented: $showingAddRoom) {
      CreateRoomFlowView {
        name, descriptionText, tags, isPrivate, isTimeCapsule, days, hours, mins, date,
        backgroundMusic, theme,
        expirationDate, uploadStartDate, rollingExpiryDays, collaborators in
        createRoom(
          name: name, description: descriptionText, tags: tags, isPrivate: isPrivate,
          isTimeCapsule: isTimeCapsule,
          days: days, hours: hours, mins: mins, unlockDate: date, backgroundMusic: backgroundMusic,
          theme: theme, expirationDate: expirationDate, uploadStartDate: uploadStartDate,
          rollingExpiryDays: rollingExpiryDays, collaborators: collaborators)
      }
    }
    .sheet(isPresented: $showingProfile) {
      ProfileView()
    }
    .sheet(isPresented: $showingNotifications) {
      NotificationCenterView(rooms: rooms)
    }
    .fullScreenCover(isPresented: $showScanner) {
      QRScannerView { roomId in
        // Navigate to room after successful scan
        Task {
          do {
            let room = try await Database.shared.getRoom(id: roomId)
            await MainActor.run {
              self.selectedRoomForDetail = (room, .hallway)
              self.navigateToDetail = true
            }
          } catch {
            print("[DEBUG] Failed to navigate after QR scan: \(error)")
          }
        }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserLoggedOut"))) {
      _ in
      onLogout()
    }
    .onChange(of: inviteManager.deepLinkedRoomId) { _, newId in
      if let id = newId {
        handleDeepLink(id: id)
      }
    }
  }

  private func handleDeepLink(id: String) {
    Task {
      do {
        let room = try await Database.shared.getRoom(id: id)
        await MainActor.run {
          self.selectedRoomForDetail = (room, .hallway)
          self.navigateToDetail = true
          // Reset so we can trigger again if needed
          inviteManager.deepLinkedRoomId = nil
        }
      } catch {
        print("[DEBUG] Failed to handle deep link: \(error)")
        await MainActor.run {
          inviteManager.deepLinkedRoomId = nil
        }
      }
    }
  }

  private func fetchRooms() {
    isLoading = true
    Task {
      do {
        rooms = try await Database.shared.getAllRooms()

        // --- Proactive Calendar Suggestions ---
        let celebrations = await CalendarService.shared.fetchTodayCelebrations()
        if let celebration = celebrations.first, let roomName = celebration.title, !roomName.isEmpty
        {
          let seenKey = "seenCelebration_\(roomName.lowercased())"
          let hasSeen = UserDefaults.standard.bool(forKey: seenKey)

          if !hasSeen && !rooms.contains(where: { $0.name.lowercased() == roomName.lowercased() }) {
            await MainActor.run {
              self.suggestedCelebrationName = roomName
              self.showCelebrationAlert = true
            }
          }
        }
      } catch {
        errorMessage = error.localizedDescription
      }
      
      isLoading = false
      
      // Schedule notifications for future unlocks
      for room in rooms {
        NotificationManager.shared.scheduleRoomUnlockNotification(for: room)
      }
    }
  }

  private func markCelebrationAsSeen(name: String) {
    let key = "seenCelebration_\(name.lowercased())"
    UserDefaults.standard.set(true, forKey: key)
  }

  private func createCelebrationRoom(name: String) {
    createRoom(
      name: name,
      description: "",
      tags: ["celebration"],
      isPrivate: false,
      isTimeCapsule: false,
      days: 0,
      hours: 0,
      mins: 0,
      unlockDate: nil,
      backgroundMusic: nil,
      theme: "default",
      expirationDate: nil,
      uploadStartDate: nil,
      rollingExpiryDays: 0,
      collaborators: []
    )
  }

  private func createRoom(
    name: String, description: String, tags: [String], isPrivate: Bool, isTimeCapsule: Bool,
    days: Int, hours: Int, mins: Int,
    unlockDate: Date?,
    backgroundMusic: String?,
    theme: String,
    expirationDate: Date?,
    uploadStartDate: Date?,
    rollingExpiryDays: Int,
    collaborators: [Collaborator]
  ) {
    isLoading = true
    Task {
      do {
        try await Database.shared.createRoom(
          name: name,
          ownerEmail: AuthService.shared.currentUser?.email,
          description: description.isEmpty ? nil : description,
          tags: tags,
          isPrivate: isPrivate,
          isTimeCapsule: isTimeCapsule,
          capsuleDurationDays: days,
          capsuleDurationHours: hours,
          capsuleDurationMinutes: mins,
          unlockDate: unlockDate,
          backgroundMusic: backgroundMusic,
          theme: theme,
          expirationDate: expirationDate,
          uploadStartDate: uploadStartDate,
          rollingExpiryDays: rollingExpiryDays,
          collaborators: collaborators)
        fetchRooms()  // Refresh list
      } catch {
        errorMessage = error.localizedDescription
      }
      isLoading = false
    }
  }
}

struct ExploreRow: View {
  let text: String
  var body: some View {
    HStack {
      Text(text)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white)
      Spacer()
      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(.white.opacity(0.5))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(
      LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
        startPoint: .leading,
        endPoint: .trailing
      )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white.opacity(0.1), lineWidth: 1)
    )
    .cornerRadius(12)
  }
}

struct HallwayBottomNav: View {
  @Binding var selectedTab: Int

  var body: some View {
    HStack {
      // Everyone Tab
      Button(action: { selectedTab = 0 }) {
        VStack(spacing: 2) {
          if selectedTab == 0 {
            Text("▽").foregroundColor(.white).font(.system(size: 10))
          }
          Text("Rooming")
            .foregroundColor(selectedTab == 0 ? .white : .gray)
            .fontWeight(selectedTab == 0 ? .bold : .regular)
        }
      }

      Spacer()

      // Rooming Tab
      Button(action: { selectedTab = 1 }) {
        VStack(spacing: 2) {
          if selectedTab == 1 {
            Text("▽").foregroundColor(.white).font(.system(size: 10))
          }
          Text("Everyone")
            .foregroundColor(selectedTab == 1 ? .white : .gray)
            .fontWeight(selectedTab == 1 ? .bold : .regular)
        }
      }

      Spacer()

      Text("Artists").foregroundColor(.gray)
    }
    .padding(.horizontal, 40)
    .frame(height: 80)
    .background(Color.black.opacity(0.9))
  }
}

#Preview {
  HallwayView()
}
