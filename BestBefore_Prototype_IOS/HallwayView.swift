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
  @State private var selectedTab = 0  // 0: Hallway, 1: Roaming

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

  private var mainStackRooms: [RoomObject] {
    Array(rooms.prefix(4))
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

      if selectedTab == 0 {
        VStack(alignment: .leading, spacing: 0) {
          // Updated Header Area
          HStack {
            Text("Hallway")
              .font(.system(size: 32, weight: .bold))
              .foregroundColor(.white)
            Spacer()
            Text("All")
              .font(.system(size: 22))
              .foregroundColor(.gray)
          }
          .padding(.horizontal, 24)
          .padding(.top, 10)

          if isLoading {
            Spacer()
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
              .frame(maxWidth: .infinity)
            Spacer()
          } else if rooms.isEmpty {
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

                VStack(alignment: .leading, spacing: 4) {
                  Text("Description")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                  Text(
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor..."
                  )
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
      } else if selectedTab == 1 {
        // Roaming View content
        RoamingView { room in
          selectedRoomForDetail = (room, .roaming)
          navigateToDetail = true
        }
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
        onProfile: { showingProfile = true },
        onSearch: { /* Handle search */  }
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
      .zIndex(100)
    }
    .onAppear(perform: fetchRooms)
    .sheet(isPresented: $showingAddRoom) {
      CreateRoomFlowView {
        name, isPrivate, isTimeCapsule, days, hours, mins, date, backgroundMusic in
        createRoom(
          name: name, isPrivate: isPrivate, isTimeCapsule: isTimeCapsule,
          days: days, hours: hours, mins: mins, unlockDate: date, backgroundMusic: backgroundMusic)
      }
    }
    .sheet(isPresented: $showingProfile) {
      ProfileView()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserLoggedOut"))) {
      _ in
      onLogout()
    }
  }

  private func fetchRooms() {
    isLoading = true
    Task {
      do {
        rooms = try await Database.shared.getAllRooms()
      } catch {
        errorMessage = error.localizedDescription
      }
      isLoading = false
    }
  }

  private func createRoom(
    name: String, isPrivate: Bool, isTimeCapsule: Bool, days: Int, hours: Int, mins: Int,
    unlockDate: Date?,
    backgroundMusic: String?
  ) {
    isLoading = true
    Task {
      do {
        try await Database.shared.createRoom(
          name: name,
          ownerEmail: AuthService.shared.currentUser?.email,
          isPrivate: isPrivate,
          isTimeCapsule: isTimeCapsule,
          capsuleDurationDays: days,
          capsuleDurationHours: hours,
          capsuleDurationMinutes: mins,
          unlockDate: unlockDate,
          backgroundMusic: backgroundMusic)
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
      // Roaming Tab
      Button(action: { selectedTab = 1 }) {
        VStack(spacing: 2) {
          if selectedTab == 1 {
            Text("▽").foregroundColor(.white).font(.system(size: 10))
          }
          Text("Rooming")
            .foregroundColor(selectedTab == 1 ? .white : .gray)
            .fontWeight(selectedTab == 1 ? .bold : .regular)
        }
      }

      Spacer()

      // Everyone Tab
      Button(action: { selectedTab = 0 }) {
        VStack(spacing: 2) {
          if selectedTab == 0 {
            Text("▽").foregroundColor(.white).font(.system(size: 10))
          }
          Text("Everyone")
            .foregroundColor(selectedTab == 0 ? .white : .gray)
            .fontWeight(selectedTab == 0 ? .bold : .regular)
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
