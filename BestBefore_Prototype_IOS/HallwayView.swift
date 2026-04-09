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
  @State private var selectedTab = 1  // 0: Roaming, 1: Hallway, 2: Artists
  @State private var searchText = ""
  @State private var selectedFilterTag: String? = nil
  @State private var showCelebrationAlert = false
  @State private var suggestedCelebrationName = ""
  @State private var showingNotifications = false
  @State private var showingMiniPlayer = false
  @State private var isOrbMenuHidden = false
  @State private var showScanner = false
  @State private var isDescriptionExpanded = false
  @State private var showingSoundCloudModal = false
  @State private var soundCloudControllers: [String: SoundCloudController] = [:]
  @State private var accentColorHex: String = UserDefaults.standard.string(forKey: "accentColor") ?? (AuthService.shared.currentUser?.accentColor ?? "#007AFF")
  @State private var selectedTheme: String = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Default"
  @State private var syncAccentWithRoom: Bool = UserDefaults.standard.bool(forKey: "syncAccentWithRoom")
  @State private var applyAccentToAll: Bool = UserDefaults.standard.bool(forKey: "applyAccentToAll")
  @EnvironmentObject var inviteManager: InviteManager

  var onLogout: () -> Void

  init(onLogout: @escaping () -> Void = {}) {
    self.onLogout = onLogout
  }

  private var accentColor: Color {
    return Color(hex: accentColorHex)
  }

  private var iconColor: Color {
    if applyAccentToAll && selectedTheme != "Default" {
      return accentColor
    }
    return selectedTheme == "Midnight" ? accentColor : (selectedTheme == "Glass" ? accentColor : .white)
  }

  private var filteredRooms: [RoomObject] {
    var baseRooms: [RoomObject]
    if selectedTab == 1 {
      // Show mock rooms for verification + any real rooms
      baseRooms = MockData.hallwayRooms + rooms.filter { !MockData.hallwayRooms.contains($0) }
    } else if selectedTab == 2 {
      baseRooms = MockData.artistRooms
    } else {
      baseRooms = rooms
    }

    var result = baseRooms
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

  private var currentRoom: RoomObject {
    if filteredRooms.indices.contains(selectedIndex) {
        return filteredRooms[selectedIndex]
    }
    return filteredRooms.first ?? MockData.hallwayRooms[0]
  }

  private var currentController: SoundCloudController {
    let roomId = currentRoom.id
    if let existing = soundCloudControllers[roomId] {
        return existing
    }
    return SoundCloudController()
  }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      // --- Background SoundCloud Player (Görünmez Ses Motoru) ---
      // Bu katman, WebView hiyerarşide olmadığı sürece sesin çalmaması sorununu kökten çözer.
      if let musicUrl = currentRoom.backgroundMusic, !musicUrl.isEmpty {
          SoundCloudPlayerView(
              soundCloudUrl: musicUrl,
              autoPlay: true,
              isController: true,
              controller: currentController
          )
          .id("bg_audio_\(currentRoom.id)") // Oda değiştiğinde player'ı yeniden yaratır
      }

      // Hidden NavigationLink to trigger room detail
      if let (room, context) = selectedRoomForDetail {
        NavigationLink(
          destination: RoomDetailView(room: room, context: context),
          isActive: $navigateToDetail
        ) {
          EmptyView()
        }
      }

      if selectedTab == 1 || selectedTab == 2 {
        VStack(alignment: .leading, spacing: 0) {
          // --- Premium Header ---
          HStack {
            Text(selectedTab == 1 ? "Hallway" : "Artists")
              .font(.system(size: 32, weight: .bold))
              .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
            
            Spacer()
            
            HStack(spacing: 20) {
              Button(action: {
                withAnimation(.spring()) {
                  showingMiniPlayer.toggle()
                }
              }) {
                Image(systemName: "music.note.list")
                  .font(.system(size: 22))
                  .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
              }
              
              Button(action: { showingNotifications = true }) {
                Image(systemName: "bell.fill")
                  .font(.system(size: 22))
                  .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, 25)

          // --- Search Bar ---
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .gray)
            TextField("Search...", text: $searchText)
              .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
          }
          .padding(12)
          .background(Color.white.opacity(0.1))
          .cornerRadius(12)
          .padding(.horizontal, 24)
          .padding(.top, 15)

          // --- Tag Filter Bar (Restored) ---
          if !allUserTags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                Button(action: { selectedFilterTag = nil }) {
                  Text("All")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                      ZStack {
                      if selectedFilterTag == nil {
                        if selectedTheme == "Glass" {
                          accentColor.opacity(0.12)
                            .background(.thickMaterial)
                            .overlay(
                              RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.18))
                            )
                            .overlay(
                              RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                            )
                        } else if selectedTheme == "Midnight" {
                          Color.black
                            .overlay(
                              RoundedRectangle(cornerRadius: 20)
                                .stroke(accentColor, lineWidth: 2)
                            )
                        } else {
                          accentColor
                        }
                      } else {
                        Color.white.opacity(0.1)
                      }
                      }
                      .clipShape(Capsule())
                    )
                    .foregroundColor(selectedFilterTag == nil ? iconColor : (applyAccentToAll ? iconColor : .white))
                }

                ForEach(["#trip", "#music", "#science", "#party", "#family"], id: \.self) { tag in
                  Button(action: { selectedFilterTag = tag }) {
                    Text(tag)
                      .font(.system(size: 14, weight: .medium))
                      .padding(.horizontal, 16)
                      .padding(.vertical, 8)
                      .background(
                        ZStack {
                        if selectedFilterTag == tag {
                          if selectedTheme == "Glass" {
                            accentColor.opacity(0.12)
                              .background(.thickMaterial)
                              .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                  .fill(Color.white.opacity(0.18))
                              )
                              .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                  .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                              )
                          } else if selectedTheme == "Midnight" {
                            Color.black
                              .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                  .stroke(accentColor, lineWidth: 2)
                            )
                          } else {
                            accentColor
                          }
                        } else {
                          Color.white.opacity(0.1)
                        }
                        }
                        .clipShape(Capsule())
                      )
                      .foregroundColor(selectedFilterTag == tag ? iconColor : (applyAccentToAll ? iconColor : .white))
                  }
                }
              }
              .padding(.horizontal, 24)
            }
            .padding(.top, 16)
          }

          if isLoading {
            Spacer()
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
              .frame(maxWidth: .infinity)
            Spacer()
          } else if filteredRooms.isEmpty {
            Spacer()
            Text("No content found")
              .foregroundColor(.gray)
              .frame(maxWidth: .infinity)
            Spacer()
          } else {
            // --- Horizontal Carousel Area ---
            let selectedRoom = selectedIndex < filteredRooms.count ? filteredRooms[selectedIndex] : filteredRooms[0]
            
            // Room title + CD Button at same level, card below
            ZStack(alignment: .topTrailing) {
              VStack(spacing: 0) {
                // Room name centered
                Text(selectedRoom.name)
                  .font(.system(size: 24, weight: .bold))
                  .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
                  .frame(maxWidth: .infinity)
                  .padding(.top, 4)
                  .offset(x: isOrbMenuHidden ? 0 : -35)
                  .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isOrbMenuHidden)
                
                // Card stack directly below
                CardStackView(
                  rooms: filteredRooms,
                  selectedIndex: $selectedIndex,
                  isMenuHidden: isOrbMenuHidden,
                  soundCloudControllers: soundCloudControllers
                )
                .frame(height: 320) // Reduced to make room for description x32780 (definitive final)
                .padding(.top, 6)
              }
              
              // CD Button - positioned next to room name, NOT overlapping card
              Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                  showingSoundCloudModal = true
                }
              }) {
                Image(systemName: "opticaldisc")
                  .font(.system(size: 22))
                  .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
                  .frame(width: 44, height: 44)
                  .background(Color.white.opacity(0.12))
                  .clipShape(Circle())
              }
              .contentShape(Circle())
              .padding(.trailing, 20)
              .padding(.top, 4) // Aligns with room name vertically
              .offset(x: isOrbMenuHidden ? 0 : -35)
              .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isOrbMenuHidden)
              .zIndex(99)
            }
            .padding(.top, 10)
            .zIndex(2)
            
            // --- Artist Detail Section ---
            VStack(alignment: .leading, spacing: 14) {
              // Header Row: Profile + Username ... Tags
              HStack(alignment: .center) {
                HStack(spacing: 12) {
                  Circle()
                    .fill(accentColor)
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 18)).foregroundColor(.black))
                  
                  Text("@\(selectedRoom.ownerEmail?.components(separatedBy: "@").first ?? "artist")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                  ForEach(selectedRoom.tags.prefix(2), id: \.self) { tag in
                    Text("#\(tag)").tagStyle(color: (applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
                  }
                  if selectedRoom.tags.count > 2 {
                    Text("+")
                      .font(.system(size: 13, weight: .bold))
                      .padding(.horizontal, 10)
                      .padding(.vertical, 4)
                      .background(Color.white.opacity(0.15))
                      .foregroundColor((applyAccentToAll && selectedTheme != "Default") ? accentColor : .white)
                      .cornerRadius(12)
                  }
                }
              }
              
              // Description (Static 2-line limit)
              Text(selectedRoom.description ?? "No description provided.")
                .font(.system(size: 14))
                .foregroundColor(((applyAccentToAll && selectedTheme != "Default") ? accentColor : Color.white).opacity(0.8))
                .lineLimit(2)
              
              // See All Button
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  isDescriptionExpanded = true
                }
              }) {
                Text("See All")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accentColor)
              }
            }
            .padding(.horizontal, 24)
            .padding(.top, 2)
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

      VStack {
        Spacer()
        HallwayBottomNav(
          selectedTab: $selectedTab,
          accentColor: accentColor,
          applyAccentToAll: applyAccentToAll && selectedTheme != "Default"
        )
      }



      // Orb Menu (Premium Design)
      if !isOrbMenuHidden {
        OrbMenuPremium(
          isHidden: $isOrbMenuHidden,
          accentColor: accentColor,
          selectedTheme: selectedTheme,
          onAdd: { showingAddRoom = true },
          onChat: { /* Handle chat */  },
          onScan: { showScanner = true },
          onProfile: { showingProfile = true },
          onSearch: { /* Handle search */  }
        )
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .zIndex(100)
      }

      // Swipe-to-show detector (Responsive edge trigger)
      if isOrbMenuHidden {
        Color.clear
          .frame(width: 80, height: 400) // Restricted height to prevent blocking the whole edge
          .contentShape(Rectangle())
          .gesture(
            DragGesture()
              .onChanged { gesture in
                if gesture.translation.width < -10 {
                  withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isOrbMenuHidden = false
                  }
                }
              }
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
          .zIndex(150) // Ensure it stays on top
      }

      // --- SoundCloud Player Modal Overlay (Full Width) ---
      if showingSoundCloudModal {
          SoundCloudPlayerModal(
              room: currentRoom,
              controller: currentController,
              isPresented: $showingSoundCloudModal
          )
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .zIndex(2000)
      }

      // --- Full Screen Detail Overlay (TOP LEVEL) ---
      if isDescriptionExpanded {
        ArtistFullDetailView(room: currentRoom, isPresented: $isDescriptionExpanded)
          .transition(.opacity)
          .zIndex(1000)
      }
    }
    .onAppear {
        fetchRooms()
        
        // Initial play for the first card after stabilization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if selectedIndex < filteredRooms.count {
                let room = filteredRooms[selectedIndex]
                if let controller = soundCloudControllers[room.id] {
                    controller.setVolume(100)
                    controller.play()
                }
            }
        }
    }
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
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AccentColorChanged"))) { _ in
      self.accentColorHex = UserDefaults.standard.string(forKey: "accentColor") ?? "#007AFF"
      self.selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Default"
      self.applyAccentToAll = UserDefaults.standard.bool(forKey: "applyAccentToAll")
      self.syncAccentWithRoom = UserDefaults.standard.bool(forKey: "syncAccentWithRoom")
      updateDynamicColor()
    }
    .onChange(of: selectedIndex) { newIndex in
        syncSoundCloudAudio(for: newIndex)
        updateDynamicColor()
    }
    .onChange(of: selectedTab) { newTab in
        // Stop all music when leaving the Hallway tab (Tab 1 or Artists Tab 2)
        if newTab != 1 && newTab != 2 {
            for controller in soundCloudControllers.values {
                controller.pause()
            }
        }
    }
    .onChange(of: inviteManager.deepLinkedRoomId) { newId in
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
        let fetchedRooms = try await Database.shared.getAllRooms()
        
        // --- Proactive Calendar Suggestions ---
        let celebrations = await CalendarService.shared.fetchTodayCelebrations()
        
        await MainActor.run {
          self.rooms = fetchedRooms
          
          if let celebration = celebrations.first, let roomName = celebration.title, !roomName.isEmpty {
            let seenKey = "seenCelebration_\(roomName.lowercased())"
            let hasSeen = UserDefaults.standard.bool(forKey: seenKey)
            
            if !hasSeen && !rooms.contains(where: { $0.name.lowercased() == roomName.lowercased() }) {
              self.suggestedCelebrationName = roomName
              self.showCelebrationAlert = true
            }
          }
          
          // Pre-initialize SoundCloud controllers
          for room in MockData.hallwayRooms {
            if let musicUrl = room.backgroundMusic, !musicUrl.isEmpty {
              if soundCloudControllers[room.id] == nil {
                soundCloudControllers[room.id] = SoundCloudController()
              }
            }
          }
          
          // Schedule notifications
          for room in rooms {
            NotificationManager.shared.scheduleRoomUnlockNotification(for: room)
          }
          
          self.isLoading = false
          syncSoundCloudAudio(for: selectedIndex)
        }
      } catch {
        await MainActor.run {
          self.errorMessage = error.localizedDescription
          self.isLoading = false
        }
      }
    }
  }

  private func syncSoundCloudAudio(for index: Int) {
    guard filteredRooms.indices.contains(index) else { return }
    let selectedRoom = filteredRooms[index]

    // 1. Proactively ensure the controller exists for the target room
    if let musicUrl = selectedRoom.backgroundMusic, !musicUrl.isEmpty {
      if soundCloudControllers[selectedRoom.id] == nil {
        soundCloudControllers[selectedRoom.id] = SoundCloudController()
      }
    }

    // 2. Direct Switch: Play active, Pause others
    for (id, controller) in soundCloudControllers {
      if id == selectedRoom.id {
        controller.setVolume(100)
        controller.play()
      } else {
        controller.pause()
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

  // Helper to update color based on selected room theme
  private func updateDynamicColor() {
    if syncAccentWithRoom {
      let roomColor = currentRoom.themeColor
      let hex = roomColor.toHex()
      if accentColorHex != hex {
        accentColorHex = hex
        UserDefaults.standard.set(hex, forKey: "accentColor")
        // Broadcast to other components (like the Orb)
        NotificationCenter.default.post(name: NSNotification.Name("AccentColorChanged"), object: nil)
      }
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
  let accentColor: Color
  let applyAccentToAll: Bool

  var body: some View {
    HStack {
      // Roaming Tab
      Button(action: { selectedTab = 0 }) {
        TabItem(title: "Roaming", isSelected: selectedTab == 0, accentColor: accentColor, applyAccentToAll: applyAccentToAll)
      }

      Spacer()

      // Hallway Tab
      Button(action: { selectedTab = 1 }) {
        TabItem(title: "Hallway", isSelected: selectedTab == 1, accentColor: accentColor, applyAccentToAll: applyAccentToAll)
      }

      Spacer()

      // Artists Tab
      Button(action: { selectedTab = 2 }) {
        TabItem(title: "Artists", isSelected: selectedTab == 2, accentColor: accentColor, applyAccentToAll: applyAccentToAll)
      }
    }
    .padding(.horizontal, 40)
    .frame(height: 80)
    .background(Color.black.opacity(0.9))
  }
}

struct TabItem: View {
  let title: String
  let isSelected: Bool
  let accentColor: Color
  let applyAccentToAll: Bool

  var body: some View {
    VStack(spacing: 2) {
      if isSelected {
        Text("▽")
          .foregroundColor(applyAccentToAll ? accentColor : .white)
          .font(.system(size: 10))
      }
      Text(title)
        .foregroundColor(isSelected ? (applyAccentToAll ? accentColor : .white) : .gray)
        .fontWeight(isSelected ? .bold : .regular)
    }
  }
}

extension View {
  func tagStyle(color: Color = .white) -> some View {
    self.font(.system(size: 12, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(12)
  }
}

struct SoundCloudPlayerModal: View {
    let room: RoomObject
    @ObservedObject var controller: SoundCloudController
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Backup Controller (Invisible but active in Modal ZStack)
            if let musicUrl = room.backgroundMusic, !musicUrl.isEmpty {
                SoundCloudPlayerView(
                    soundCloudUrl: musicUrl,
                    autoPlay: false,
                    isController: true,
                    controller: controller
                )
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
            }

            // Semi-transparent Backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) { isPresented = false }
                }
            
            VStack {
                Spacer()
                
                // Modal content with Handle
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 30)

                    // Track Content
                    VStack(spacing: 35) {
                        // High-Res Artwork with Theme-Aware Glow
                        ZStack {
                            // Deep Glow behind artwork
                            Circle()
                                .fill(room.themeColor)
                                .frame(width: 200, height: 200)
                                .blur(radius: 80)
                                .opacity(0.6)

                            if let artwork = controller.currentArtworkUrl, let url = URL(string: artwork) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable()
                                             .aspectRatio(contentMode: .fill)
                                             .frame(width: 280, height: 280)
                                             .cornerRadius(24)
                                             .shadow(color: room.themeColor.opacity(0.3), radius: 20, x: 0, y: 10)
                                    } else {
                                        artworkPlaceholder
                                    }
                                }
                            } else {
                                artworkPlaceholder
                            }
                        }
                        
                        // Metadata Section (Uppercase Bold as per reference)
                        VStack(spacing: 8) {
                            Text(controller.currentTrackTitle.isEmpty ? room.name.uppercased() : controller.currentTrackTitle.uppercased())
                                .font(.system(size: 20, weight: .black))
                                .tracking(1)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                            
                            Text(controller.currentTrackArtist.isEmpty ? "jergkoppf" : controller.currentTrackArtist.lowercased())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))

                            // Contextual Now Playing with Theme Color
                            HStack(spacing: 8) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 14))
                                    .foregroundColor(room.themeColor)
                                    .symbolEffect(.variableColor.iterative, isActive: true)

                                Text("NOW PLAYING FROM \(room.name.uppercased())")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(room.themeColor)
                            }
                            .padding(.top, 15)
                        }

                        // Premium Listen Button (Orange)
                        if let urlString = room.backgroundMusic, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square.fill")
                                    Text("Listen on SoundCloud")
                                        .fontWeight(.bold)
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color(hex: "FF5500")) // SoundCloud Orange
                                .cornerRadius(16)
                                .padding(.horizontal, 40)
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.black.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
            }
        }
        .task {
            // Native Metadata Fetch on Modal Load
            if let musicUrl = room.backgroundMusic {
                await controller.fetchMetadata(for: musicUrl)
            }
        }
    }
    
    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(room.themeColor.opacity(0.2))
            .frame(width: 280, height: 280)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundColor(room.themeColor)
            )
    }
}

#Preview {
  HallwayView()
    .environmentObject(InviteManager.shared)
}
