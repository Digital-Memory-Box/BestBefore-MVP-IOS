import SwiftUI

struct ProfileView: View {
  @Environment(\.dismiss) var dismiss
  @State private var name: String = ""
  @State private var selectedTheme: String = "Default"
  @State private var selectedColor: Color = .blue
  @State private var selectedMusic: String? = nil
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var selectedTab = 0  // 0: Dashboard, 1: Customization, 2: Settings
  @State private var newEmail: String = ""
  @State private var newPassword: String = ""
  @State private var myRooms: [RoomObject] = []
  @State private var totalMemoryCount: Int = 0
  @State private var activities: [ActivityItem] = [
    ActivityItem(title: "Joined BestBefore", date: Date().addingTimeInterval(-86400 * 5)),
    ActivityItem(title: "Created first room", date: Date().addingTimeInterval(-86400 * 4)),
  ]

  let themes = ["Default", "Glass", "Midnight", "Vibrant"]
  let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .red]

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 0) {
        // Header
        HStack {
          Button("Cancel") { dismiss() }
            .foregroundColor(.white)
          Spacer()
          Text("Edit Profile")
            .font(.headline)
            .foregroundColor(.white)
          Spacer()
          Button("Save") {
            saveProfile()
          }
          .font(.headline)
          .foregroundColor(.blue)
          .disabled(isLoading)
        }
        .padding()

        // Tab Picker
        HStack(spacing: 0) {
          TabButton(title: "Dashboard", isSelected: selectedTab == 0) { selectedTab = 0 }
          TabButton(title: "Customization", isSelected: selectedTab == 1) { selectedTab = 1 }
          TabButton(title: "Settings", isSelected: selectedTab == 2) { selectedTab = 2 }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)

        ScrollView {
          VStack(alignment: .leading, spacing: 32) {
            if selectedTab == 0 {
              dashboardSection
            } else if selectedTab == 1 {
              customizationSection
            } else {
              settingsSection
            }
          }
          .padding(24)
        }
      }

      if isLoading {
        Color.black.opacity(0.4).ignoresSafeArea()
        ProgressView().tint(.white)
      }
    }
    .onAppear {
      loadUserData()
      if let music = selectedMusic {
        AudioManager.shared.playBackgroundMusic(for: music)
      }
    }
    .onDisappear {
      AudioManager.shared.stopMusic()
    }
  }

  // MARK: - Sections

  private var dashboardSection: some View {
    VStack(alignment: .leading, spacing: 32) {
      // Stats/Overview
      HStack(spacing: 20) {
        StatCard(
          title: "My Rooms", value: "\(myRooms.count)", icon: "house.fill", color: selectedColor)
        StatCard(
          title: "Memories", value: "\(totalMemoryCount)", icon: "photo.on.rectangle.angled",
          color: .purple)
      }

      // My Rooms (History)
      VStack(alignment: .leading, spacing: 16) {
        Text("Your Rooms")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)

        if myRooms.isEmpty {
          Text("No rooms created yet.")
            .foregroundColor(.gray)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        } else {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
              ForEach(myRooms) { room in
                VStack(alignment: .leading) {
                  ZStack {
                    RoundedRectangle(cornerRadius: 12)
                      .fill(
                        LinearGradient(
                          colors: [selectedColor.opacity(0.3), .black], startPoint: .topLeading,
                          endPoint: .bottomTrailing))
                    Image(systemName: "folder.fill")
                      .foregroundColor(selectedColor)
                  }
                  .frame(width: 120, height: 80)

                  Text(room.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                }
              }
            }
          }
        }
      }

      // Recent Activity
      VStack(alignment: .leading, spacing: 16) {
        Text("Recent Activity")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)

        VStack(spacing: 12) {
          ForEach(activities) { activity in
            ActivityRow(activity: activity)
          }
        }
      }
    }
  }

  private var customizationSection: some View {
    VStack(alignment: .leading, spacing: 32) {
      // Profile Info
      VStack(alignment: .leading, spacing: 8) {
        Text("Public Name")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.gray)
        TextField("Display Name", text: $name)
          .padding()
          .background(Color.white.opacity(0.05))
          .cornerRadius(12)
          .foregroundColor(.white)
      }

      // Theme Selection
      VStack(alignment: .leading, spacing: 16) {
        Text("Interface Theme")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.gray)

        HStack(spacing: 12) {
          ForEach(themes, id: \.self) { theme in
            Button(action: { selectedTheme = theme }) {
              Text(theme)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTheme == theme ? selectedColor : Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(20)
            }
          }
        }
      }

      // Accent Color
      VStack(alignment: .leading, spacing: 16) {
        Text("Accent Color")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.gray)

        HStack(spacing: 16) {
          ForEach(colors, id: \.self) { color in
            Circle()
              .fill(color)
              .frame(width: 32, height: 32)
              .overlay(
                Circle()
                  .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
              )
              .onTapGesture {
                selectedColor = color
              }
          }
        }
      }

      // Profile Music
      VStack(alignment: .leading, spacing: 16) {
        Text("Profile Music")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.gray)

        VStack(spacing: 12) {
          MusicPresetOption(
            title: "None", icon: "speaker.slash.fill", isSelected: selectedMusic == nil
          ) {
            selectedMusic = nil
            AudioManager.shared.stopMusic()
          }
          MusicPresetOption(
            title: "Dreamy Synth", icon: "sparkles",
            isSelected: selectedMusic == "Dreamy Synth"
          ) {
            selectedMusic = "Dreamy Synth"
            AudioManager.shared.playBackgroundMusic(for: "Dreamy Synth")
          }
          MusicPresetOption(
            title: "Chill Cafe", icon: "cup.and.saucer.fill",
            isSelected: selectedMusic == "Chill Cafe"
          ) {
            selectedMusic = "Chill Cafe"
            AudioManager.shared.playBackgroundMusic(for: "Chill Cafe")
          }
        }
      }
    }
  }

  private var settingsSection: some View {
    VStack(alignment: .leading, spacing: 32) {
      VStack(alignment: .leading, spacing: 20) {
        Text("Account Settings")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)

        VStack(alignment: .leading, spacing: 12) {
          Text("Update Email")
            .font(.system(size: 14))
            .foregroundColor(.gray)
          TextField(AuthService.shared.currentUser?.email ?? "New Email", text: $newEmail)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .foregroundColor(.white)
            .autocapitalization(.none)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("Update Password")
            .font(.system(size: 14))
            .foregroundColor(.gray)
          SecureField("New Password (min 6 chars)", text: $newPassword)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .foregroundColor(.white)
        }

        Button(action: saveCredentials) {
          Text("Update Credentials")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedColor.opacity(0.2))
            .cornerRadius(12)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(selectedColor.opacity(0.5), lineWidth: 1)
            )
        }
        .disabled(newEmail.isEmpty && newPassword.isEmpty)
      }

      VStack(alignment: .leading, spacing: 20) {
        Text("App Preferences")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)

        Toggle("High Fidelity Mode", isOn: .constant(true))
          .foregroundColor(.white)
        Toggle("Spatial Audio", isOn: .constant(true))
          .foregroundColor(.white)
      }

      if let error = errorMessage {
        Text(error)
          .foregroundColor(.red)
          .font(.system(size: 14))
      }

      // Logout Button
      Button(action: logout) {
        Text("Log Out")
          .foregroundColor(.red)
          .font(.system(size: 16, weight: .bold))
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.red.opacity(0.1))
          .cornerRadius(12)
      }
      .padding(.top, 20)
    }
  }

  private func loadUserData() {
    guard let user = AuthService.shared.currentUser else { return }
    name = user.name ?? ""
    selectedTheme = user.theme ?? "Default"
    if let hex = user.accentColor {
      selectedColor = Color(hex: hex)
    }
    selectedMusic = user.profileMusic

    // Load History & Stats
    Task {
      do {
        async let allRooms = Database.shared.getAllRooms()
        async let count = Database.shared.getMemoryCount()

        let rooms = try await allRooms
        let mCount = try await count

        await MainActor.run {
          self.myRooms = rooms.filter { $0.ownerEmail == user.email }
          self.totalMemoryCount = mCount
        }
      } catch {
        print("Failed to load history or stats: \(error)")
      }
    }
  }

  private func saveProfile() {
    Task {
      isLoading = true
      errorMessage = nil
      do {
        _ = try await AuthService.shared.updateProfile(
          name: name,
          theme: selectedTheme,
          accentColor: selectedColor.toHex() ?? "#007AFF",
          profileMusic: selectedMusic
        )
        await MainActor.run {
          isLoading = false
          dismiss()
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isLoading = false
        }
      }
    }
  }

  private func saveCredentials() {
    Task {
      isLoading = true
      errorMessage = nil
      do {
        _ = try await AuthService.shared.updateProfile(
          name: nil,
          theme: nil,
          accentColor: nil,
          profileMusic: nil,
          email: newEmail.isEmpty ? nil : newEmail,
          password: newPassword.isEmpty ? nil : newPassword
        )
        await MainActor.run {
          isLoading = false
          newEmail = ""
          newPassword = ""
          // Success feedback?
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isLoading = false
        }
      }
    }
  }

  private func logout() {
    AuthService.shared.clearSession()
    dismiss()
    // Content view handles the state change if we trigger it via a binding or notification
    // For now, we rely on the parent HallwayView/ContentView flow
    NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
  }
}

#Preview {
  ProfileView()
}

// MARK: - Helper Models & Views

struct ActivityItem: Identifiable {
  let id = UUID()
  let title: String
  let date: Date
}

struct TabButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Text(title)
          .font(.system(size: 14, weight: isSelected ? .bold : .medium))
          .foregroundColor(isSelected ? .white : .gray)

        Rectangle()
          .fill(isSelected ? Color.blue : Color.clear)
          .frame(height: 2)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: icon)
        .foregroundColor(color)
        .font(.system(size: 20))

      VStack(alignment: .leading, spacing: 4) {
        Text(value)
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.white)
        Text(title)
          .font(.system(size: 12))
          .foregroundColor(.gray)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white.opacity(0.05))
    .cornerRadius(16)
  }
}

struct ActivityRow: View {
  let activity: ActivityItem

  var body: some View {
    HStack(spacing: 16) {
      Circle()
        .fill(Color.blue.opacity(0.2))
        .frame(width: 32, height: 32)
        .overlay(
          Image(systemName: "bolt.fill")
            .font(.system(size: 12))
            .foregroundColor(.blue)
        )

      VStack(alignment: .leading, spacing: 4) {
        Text(activity.title)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.white)
        Text(activity.date, style: .date)
          .font(.system(size: 12))
          .foregroundColor(.gray)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white.opacity(0.03))
    .cornerRadius(12)
  }
}

struct SettingsRow: View {
  let icon: String
  let title: String
  let value: String

  var body: some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(.blue)
        .frame(width: 30)
      Text(title)
        .foregroundColor(.white)
      Spacer()
      Text(value)
        .foregroundColor(.gray)
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .cornerRadius(12)
  }
}
