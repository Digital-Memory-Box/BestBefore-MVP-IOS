import Combine
import PhotosUI
import Combine
import SwiftUI

struct RoomDetailView: View {
  enum RoomContext {
    case hallway
    case roaming
  }

  @State private var currentRoom: RoomObject
  private var context: RoomContext
  @Environment(\.dismiss) private var dismiss

  init(room: RoomObject, context: RoomContext = .hallway) {
    self._currentRoom = State(initialValue: room)
    self.context = context
    self._isLockedState = State(initialValue: room.isLocked)
  }

  // Sheet States
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var selectedVideoItem: PhotosPickerItem?  // NEW
  @State private var showFileImporter = false  // NEW
  @State private var showNoteEditor = false
  @State private var noteText = ""
  @State private var showAudioRecorder = false
  @State private var showEditRoom = false
  @State private var showShowroom = false  // Toggle showroom gallery
  @State private var showShareSheet = false // NEW
  @State private var showRoomInfo = false
  @State private var showVault = false
  @State private var showUnlockToast = false
  @State private var showLinkRoomSheet = false  // NEW
  @State private var connectedRooms: [RoomObject] = []  // NEW

  // Real Data State (Synced with Backend)
  @State private var memories: [MemoryItem] = []
  @State private var archivedMemories: [MemoryItem] = []
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var showAlert = false
  @State private var alertMessage = ""
  @State private var isLockedState: Bool = false

  // Upload State
  @State private var isUploading = false
  @State private var uploadingLabel = ""

  // Audio Simulation State
  @State private var isRecording = false
  @State private var recordingTime = 0.0
  @State private var audioTimer: Timer?
  @StateObject private var scController = SoundCloudController()

  private var isExpired: Bool {
    guard let expDate = currentRoom.expirationDate else { return false }
    return Date() > expDate
  }

  private var isBeforeUploadWindow: Bool {
    guard let startDate = currentRoom.uploadStartDate else { return false }
    return Date() < startDate
  }

  private var isOwner: Bool {
    guard context == .hallway else { return false }  // Force read-only in Roaming

    guard let userEmail = AuthService.shared.currentUser?.email,
      let roomOwnerEmail = currentRoom.ownerEmail
    else {
      return false
    }

    let normalizedUser = userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let normalizedRoom = roomOwnerEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    return normalizedUser == normalizedRoom
  }

  // NEW: Determines if the user is an owner or a registered collaborator
  private var canContribute: Bool {
    guard context == .hallway else { return false }
    if isOwner { return true }

    guard
      let userEmail = AuthService.shared.currentUser?.email.trimmingCharacters(
        in: .whitespacesAndNewlines
      ).lowercased()
    else {
      return false
    }

    return currentRoom.collaborators.contains {
      $0.email.lowercased() == userEmail && $0.role == .contributor
    }
  }

  private var accentColor: Color {
    if let hex = AuthService.shared.currentUser?.accentColor {
      return Color(hex: hex)
    }
    return .blue
  }

  var body: some View {
    ZStack {
      // Dynamic Background
      AnimatedBackgroundView(theme: currentRoom.theme)
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 0) {
        // Custom Header
        HStack {
          Button(action: { dismiss() }) {
            HStack(spacing: 6) {
              Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .bold))
              Text("Back")
                .font(.system(size: 18, weight: .medium))
            }
            .foregroundColor(.white)
          }

          Spacer()

          HStack(spacing: 20) {
            // Showroom Button
            Button(action: {
              if currentRoom.isLocked {
                alertMessage = "Showroom is locked until the time capsule opens."
                showAlert = true
              } else {
                showShowroom = true
              }
            }) {
              Image(systemName: "square.grid.2x2.fill")
                .foregroundColor(accentColor)
            }

            if currentRoom.isPrivate && isOwner {
              Button(action: {
                showShareSheet = true
              }) {
                Image(systemName: "qrcode.viewfinder")
                  .foregroundColor(accentColor)
              }
            }

            Menu {
              Button("Archive Vault", systemImage: "archivebox.fill") {
                if currentRoom.isLocked {
                  alertMessage = "Vault is locked until the time capsule opens."
                  showAlert = true
                } else {
                  showVault = true
                }
              }

              Button("Room Details", systemImage: "info.circle") { showRoomInfo = true }

              if isOwner {
                Button("Dump Active Memories", systemImage: "archivebox") { dumpMemories() }
                Button("Edit Room", systemImage: "pencil") { showEditRoom = true }
                Button("Delete Room", systemImage: "trash", role: .destructive) { deleteRoom() }
              }
            } label: {
              Image(systemName: "ellipsis.circle")
                .font(.system(size: 24))
                .foregroundColor(.white)
            }
          }
        }

        .padding(.horizontal, 24)
        .padding(.top, 20)

        ScrollView(showsIndicators: false) {
          if isLoading {
            ProgressView()
              .tint(.white)
              .padding(.top, 40)
          } else {
            VStack(alignment: .center, spacing: 30) {

              // Hero Countdown Section
              VStack(spacing: 8) {
                Text(currentRoom.name)
                  .font(.system(size: 28, weight: .bold))
                  .foregroundColor(.white)
                  .multilineTextAlignment(.center)

                if isExpired {
                  Text("Expired Archive")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Capsule())
                }

                if currentRoom.isTimeCapsule && isLockedState {
                  VStack(spacing: 8) {
                    Text("Unlocks in")
                      .font(.system(size: 14, weight: .bold))
                      .foregroundColor(.white.opacity(0.7))
                      .textCase(.uppercase)
                      .tracking(2)

                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                      let secs = currentRoom.secondsRemaining
                      Text(formatCountdown(secs))
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(color: accentColor.opacity(0.5), radius: 15)
                    }
                  }
                  .padding(20)
                  .background(
                    RoundedRectangle(cornerRadius: 32)
                      .fill(Color.white.opacity(0.05))
                  )
                  .overlay(
                    RoundedRectangle(cornerRadius: 32)
                      .stroke(
                        Color.white.opacity(0.1),
                        lineWidth: 1)
                  )
                }

                if let music = currentRoom.backgroundMusic, music != "None" {
                  if music.lowercased().contains("soundcloud.com") {
                    ZStack {
                      SoundCloudPlayerView(soundCloudUrl: music, isController: true, controller: scController)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                      
                      CustomMusicPlayerView(controller: scController)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                  } else {
                    HStack(spacing: 8) {
                      LivePulseIndicator(color: accentColor)

                      Text(music)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Capsule())
                  }
                }

                // Collaborator Summary Row
                if !currentRoom.collaborators.isEmpty {
                  Button(action: { showRoomInfo = true }) {
                    HStack(spacing: 8) {
                      Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                      Text("\(currentRoom.collaborators.count) People Invited")
                        .font(.system(size: 12, weight: .bold))

                      HStack(spacing: -8) {
                        ForEach(currentRoom.collaborators.prefix(3), id: \.self) { collab in
                          Circle()
                            .fill(collab.role == .contributor ? Color.blue : Color.purple)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1))
                        }
                      }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                  }
                  .padding(.top, 4)
                }
              }
              .padding(.top, 20)

              // Memory Grid (Owner or Collaborator)
              if canContribute {
                if isBeforeUploadWindow {
                  VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                      .font(.system(size: 32))
                      .foregroundColor(.white.opacity(0.6))
                    Text("Uploads open on \(currentRoom.uploadStartDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "")")
                      .font(.system(size: 16))
                      .foregroundColor(.white.opacity(0.6))
                      .multilineTextAlignment(.center)
                  }
                  .frame(maxWidth: .infinity)
                  .padding()
                } else if isExpired {
                  VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "lock.fill")
                      .font(.system(size: 32))
                      .foregroundColor(.white.opacity(0.6))
                    Text("This room is expired.\nNo new memories can be added.")
                      .font(.system(size: 16))
                      .foregroundColor(.white.opacity(0.6))
                      .multilineTextAlignment(.center)
                  }
                  .padding(.vertical, 40)
                } else {
                  VStack(alignment: .leading, spacing: 16) {
                    Text("Memories")
                      .font(.system(size: 20, weight: .bold))
                      .foregroundColor(.white)
                      .padding(.leading, 4)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16)
                    {

                      // Photo Picker Button
                      PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        GlassActionButton(
                          title: isLockedState ? "Deposit Photo" : "Add Photo",
                          icon: "photo.on.rectangle",
                          color: accentColor)
                      }
                      .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                          print("[DEBUG] Picker: Item selected")
                          if let newItem = newItem {
                            await MainActor.run { isUploading = true; uploadingLabel = "Uploading photo..." }
                            do {
                              var finalImage: UIImage?

                              // Try loading as Data
                              if let data = try await newItem.loadTransferable(type: Data.self) {
                                print("[DEBUG] Picker: Data loaded, size: \(data.count)")
                                finalImage = UIImage(data: data)
                              }

                              if let uiImage = finalImage {
                                print(
                                  "[DEBUG] Picker: UIImage successfully resolved (\(uiImage.size.width)x\(uiImage.size.height))"
                                )
                                let resized = resizeImage(uiImage, targetWidth: 800)
                                if let compressedData = resized.jpegData(compressionQuality: 0.5) {
                                  print(
                                    "[DEBUG] Picker: Resized/Compressed to \(compressedData.count) bytes"
                                  )
                                  let base64 = compressedData.base64EncodedString()
                                  await saveMemory(
                                    type: .photo, title: "Photo Drop", content: base64)
                                }
                              } else {
                                print("[DEBUG] Picker: FAILED to load image data or create UIImage")
                              }
                            } catch {
                              print("[DEBUG] Picker: ERROR during load: \(error)")
                            }
                          }
                          await MainActor.run { isUploading = false; selectedPhotoItem = nil }
                        }
                      }

                      Button(action: { showNoteEditor = true }) {
                        GlassActionButton(
                          title: isLockedState ? "Deposit Note" : "Write Note",
                          icon: "square.and.pencil",
                          color: .purple)
                      }

                      // Video Picker Button
                      PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                        GlassActionButton(
                          title: isLockedState ? "Deposit Video" : "Add Video",
                          icon: "film.fill",
                          color: .orange)
                      }
                      .onChange(of: selectedVideoItem) { _, newItem in
                        Task {
                          if let newItem = newItem {
                            print("[DEBUG] Video Picker: Item selected")
                            await MainActor.run { isUploading = true; uploadingLabel = "Uploading video..." }
                            do {
                              if let data = try await newItem.loadTransferable(type: Data.self) {
                                print(
                                  "[DEBUG] Video Picker: Data loaded, size: \(data.count) bytes")
                                if data.count < 15 * 1024 * 1024 {  // 15MB Limit
                                  let base64 = data.base64EncodedString()
                                  await saveMemory(
                                    type: .video, title: "Video Drop", content: base64)
                                } else {
                                  await MainActor.run {
                                    alertMessage = "Video too large (Max 15MB)"
                                    showAlert = true
                                  }
                                }
                              }
                            } catch {
                              print("[DEBUG] Video Picker Error: \(error)")
                            }
                          }
                          await MainActor.run { isUploading = false; selectedVideoItem = nil }
                        }
                      }

                      // Music File Importer Button
                      Button(action: { showFileImporter = true }) {
                        GlassActionButton(
                          title: isLockedState ? "Deposit Music" : "Add Music",
                          icon: "music.note",
                          color: .pink)
                      }

                      Button(action: { showAudioRecorder = true }) {
                        GlassActionButton(
                          title: isLockedState ? "Deposit Audio" : "Record Audio",
                          icon: "mic.fill",
                          color: .red)
                      }

                      if !isLockedState {
                        Button(action: { showShowroom = true }) {
                          GlassActionButton(
                            title: "View All", icon: "archivebox.fill", color: .green)
                        }
                      }
                    }
                  }
                }  // close else !isExpired
              } else {
                // Public view header (Explorer Mode)
                HStack(spacing: 15) {
                  ZStack {
                    Circle()
                      .fill(Color.blue.opacity(0.2))
                      .frame(width: 44, height: 44)
                    Image(systemName: "globe.americas.fill")
                      .font(.system(size: 20))
                      .foregroundColor(.blue)
                  }

                  VStack(alignment: .leading, spacing: 4) {
                    Text("EXPLORER MODE")
                      .font(.system(size: 14, weight: .black))
                      .foregroundColor(.blue)
                    Text("Viewing memories in this public space.")
                      .font(.system(size: 12))
                      .foregroundColor(.white.opacity(0.6))
                  }

                  Spacer()

                  Text("READ ONLY")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                      RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                )
              }

              // Recent Drops Section
              VStack(alignment: .leading, spacing: 16) {
                Text("Recent Drops")
                  .font(.system(size: 20, weight: .bold))
                  .foregroundColor(.white)
                  .padding(.leading, 4)

                if isLockedState {
                  VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                      .font(.system(size: 50))
                      .foregroundColor(.white.opacity(0.2))
                    Text("This Time Capsule is Sealed")
                      .font(.headline)
                      .foregroundColor(.white)
                    Text(
                      "Memories are currently hidden. They will be revealed once the timer hits zero."
                    )
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 60)
                  .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
                } else if memories.isEmpty {
                  VStack(spacing: 12) {
                    Image(systemName: "tray")
                      .font(.system(size: 40))
                      .foregroundColor(.white.opacity(0.2))
                    Text("No drops yet. Be the first to add a memory!")
                      .font(.system(size: 14))
                      .foregroundColor(.white.opacity(0.4))
                      .multilineTextAlignment(.center)
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 40)
                  .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                } else {
                  VStack(spacing: 12) {
                    ForEach(memories) { memory in
                      let uiImage: UIImage? = {
                        guard memory.type == .photo, let content = memory.content,
                          let data = Data(base64Encoded: content, options: .ignoreUnknownCharacters)
                        else { return nil }
                        return UIImage(data: data)
                      }()

                      GlassMemoryCard(
                        title: memory.title,
                        date: timeAgoString(from: memory.date),
                        icon: memory.type.icon,
                        image: uiImage
                      )
                    }
                  }
                }
              }

              // --- Connected Rooms (Shortcuts) Section ---
              VStack(alignment: .leading, spacing: 16) {
                HStack {
                  Text("Connected Rooms")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 4)
                  Spacer()
                  if canContribute {
                    Button(action: { showLinkRoomSheet = true }) {
                      Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(accentColor)
                    }
                  }
                }

                if connectedRooms.isEmpty {
                  Text("No connections yet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.leading, 4)
                } else {
                  ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                      ForEach(connectedRooms) { linkedRoom in
                        NavigationLink(
                          destination: RoomDetailView(room: linkedRoom, context: .roaming)
                        ) {
                          VStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 12)
                              .fill(Color(hex: linkedRoom.theme) ?? .blue)
                              .frame(width: 120, height: 80)
                              .overlay(
                                VStack {
                                  Spacer()
                                  Text(linkedRoom.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.4))
                                }
                              )
                              .clipShape(RoundedRectangle(cornerRadius: 12))
                          }
                        }
                      }
                    }
                    .padding(.horizontal, 4)
                  }
                }
              }

            }
            .padding(24)
            .padding(.bottom, 100)
          }
        }
      }

      HStack {
        Spacer()
      }

      if isUploading {
        Color.black.opacity(0.6).ignoresSafeArea()
        VStack(spacing: 16) {
          ProgressView()
            .tint(.white)
            .scaleEffect(1.5)
          Text(uploadingLabel)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
      }
    }
    .navigationBarHidden(true)
    .task {
      self.isLockedState = currentRoom.isLocked
      await fetchMemories()
      await fetchConnectedRooms()
      AudioManager.shared.playBackgroundMusic(for: currentRoom.backgroundMusic)

      // Initial check for unlock toast
      if currentRoom.isTimeCapsule && !currentRoom.isLocked {
        showUnlockToast = true
        try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
        withAnimation { showUnlockToast = false }
      }
    }

    .overlay(alignment: .top) {
      if showUnlockToast {
        HStack(spacing: 12) {
          Image(systemName: "lock.open.fill")
            .foregroundColor(.green)
            .font(.title3)
          Text("Time Capsule Unlocked")
            .font(.headline)
            .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.thinMaterial)
        .cornerRadius(30)
        .shadow(radius: 10)
        .padding(.top, 60)
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
      if currentRoom.isTimeCapsule {
        let nowLocked = currentRoom.isLocked
        if isLockedState != nowLocked {
          withAnimation(.spring()) {
            isLockedState = nowLocked
            // If it just unlocked, show the toast
            if !nowLocked {
              showUnlockToast = true
              DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { showUnlockToast = false }
              }
            }
          }
        }
      }
    }
    .onDisappear {
      AudioManager.shared.stopMusic()
    }
    .alert("Upload Error", isPresented: $showAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(alertMessage)
    }

    // --- Sheets & Modals ---

    .sheet(isPresented: $showEditRoom) {
      EditRoomView(room: currentRoom) {
        name, descriptionText, tags, isPrivate, isTimeCapsule, days, hours, mins, date, music,
        theme, expirationDate,
        rollingExpiryDays, collaborators in
        updateRoom(
          name: name, description: descriptionText, tags: tags, isPrivate: isPrivate,
          isTimeCapsule: isTimeCapsule,
          days: days, hours: hours, mins: mins,
          unlockDate: date,
          backgroundMusic: music,
          theme: theme,
          expirationDate: expirationDate,
          rollingExpiryDays: rollingExpiryDays,
          collaborators: collaborators)
      }
    }

    .sheet(isPresented: $showShareSheet) {
      ShareRoomSheet(room: currentRoom)
    }

    .sheet(isPresented: $showLinkRoomSheet) {
      LinkRoomSheet(currentRoom: $currentRoom) { updatedRoom in
        self.currentRoom = updatedRoom
        Task { await fetchConnectedRooms() }
      }
    }

    .fullScreenCover(isPresented: $showShowroom) {
      MemoryShowroomView(memories: memories)
    }

    .fullScreenCover(isPresented: $showVault) {
      MemoryShowroomView(memories: archivedMemories)
    }

    .sheet(isPresented: $showRoomInfo) {
      RoomInfoSheet(room: currentRoom)
        .presentationDetents([.medium])
    }

    // Note Editor
    .sheet(isPresented: $showNoteEditor) {
      VStack(spacing: 0) {
        HStack {
          Button("Cancel") { showNoteEditor = false }
          Spacer()
          Text("New Note").font(.headline)
          Spacer()
          Button("Save") {
            Task {
              await MainActor.run { isUploading = true; uploadingLabel = "Saving note..." }
              await saveMemory(
                type: .note,
                title: noteText.count > 20 ? String(noteText.prefix(20)) + "..." : noteText,
                content: noteText)
              await MainActor.run { isUploading = false; showNoteEditor = false }
            }
          }
          .font(.headline)
          .disabled(noteText.isEmpty)
        }
        .padding()

        Divider()

        TextEditor(text: $noteText)
          .padding()
          .font(.body)

        Spacer()
      }
      .presentationDetents([.medium, .large])
    }

    // Audio Recorder Simulation
    .sheet(isPresented: $showAudioRecorder, onDismiss: stopRecording) {
      VStack(spacing: 30) {
        Text(isRecording ? "Recording..." : "Ready to Record")
          .font(.title2.bold())
          .padding(.top, 20)

        ZStack {
          Circle()
            .fill(Color.red.opacity(0.1))
            .frame(width: 150, height: 150)
            .scaleEffect(isRecording ? 1.2 : 1.0)
            .animation(
              isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
              value: isRecording)

          Image(systemName: "mic.circle.fill")
            .font(.system(size: 100))
            .foregroundColor(.red)
        }

        Text(timeString(from: recordingTime))
          .font(.system(size: 40))
          .monospacedDigit()

        Button(action: toggleRecording) {
          Text(isRecording ? "Stop Recording" : "Start Recording")
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 200, height: 50)
            .background(isRecording ? Color.gray : Color.red)
            .cornerRadius(25)
        }
        .padding(.bottom, 30)
      }
      .presentationDetents([.medium])
    }
    .fileImporter(
      isPresented: $showFileImporter,
      allowedContentTypes: [.audio],
      allowsMultipleSelection: false
    ) { result in
      Task {
        do {
          guard let selectedFile: URL = try result.get().first else { return }
          if selectedFile.startAccessingSecurityScopedResource() {
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: selectedFile)
            print("[DEBUG] Music Import: Loaded \(data.count) bytes")
            if data.count < 15 * 1024 * 1024 {
              await MainActor.run { isUploading = true; uploadingLabel = "Uploading music..." }
              let base64 = data.base64EncodedString()
              await saveMemory(type: .music, title: selectedFile.lastPathComponent, content: base64)
              await MainActor.run { isUploading = false }
            } else {
              await MainActor.run {
                alertMessage = "Audio file too large (Max 15MB)"
                showAlert = true
              }
            }
          }
        } catch {
          print("File Import Error: \(error)")
        }
      }
    }
  }

  // MARK: - API Handlers

  private func fetchMemories() async {
    isLoading = true
    do {
      let fetched = try await Database.shared.getMemories(for: currentRoom.id)
      let archived = try await Database.shared.getArchivedMemories(for: currentRoom.id)
      await MainActor.run {
        self.memories = fetched
        self.archivedMemories = archived
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.errorMessage = error.localizedDescription
        self.isLoading = false
      }
    }
  }

  private func fetchConnectedRooms() async {
    let linkedIds = currentRoom.linkedRooms.map { $0.roomId }
    guard !linkedIds.isEmpty else { return }

    do {
      let allUserRooms = try await Database.shared.getAllRooms()
      let publicRooms = try await Database.shared.getDiscoverableRooms()
      let totalRooms = allUserRooms + publicRooms

      let resolved = totalRooms.filter { linkedIds.contains($0.id) }
      // Remove duplicates by ID natively
      var unique = [RoomObject]()
      var seen = Set<String>()
      for r in resolved {
        if !seen.contains(r.id) {
          seen.insert(r.id)
          unique.append(r)
        }
      }

      await MainActor.run {
        self.connectedRooms = unique
      }
    } catch {
      print("[DEBUG] fetchConnectedRooms: Failed to load linked rooms - \(error)")
    }
  }

  private func dumpMemories() {
    isLoading = true
    Task {
      do {
        try await Database.shared.dumpMemories(for: currentRoom.id)
        await fetchMemories()
      } catch {
        print("Dump failed: \(error)")
        await MainActor.run {
          alertMessage = "Failed to archive memories."
          showAlert = true
          isLoading = false
        }
      }
    }
  }

  private func saveMemory(type: MemoryType, title: String, content: String? = nil) async {
    print("[DEBUG] saveMemory: Starting save for \(type) - \(title)")
    do {
      try await Database.shared.addMemory(
        roomId: currentRoom.id, type: type, title: title, content: content)
      print("[DEBUG] saveMemory: Successfully saved to DB")
      await fetchMemories()  // Refresh list
      if type == .note { noteText = "" }
    } catch {
      print("[DEBUG] saveMemory: FAILED with error: \(error)")
      await MainActor.run {
        alertMessage = "Failed to upload: \(error.localizedDescription)"
        showAlert = true
      }
    }
  }

  private func resizeImage(_ image: UIImage, targetWidth: CGFloat) -> UIImage {
    if image.size.width <= targetWidth {
      print("[DEBUG] resizeImage: Image already smaller than target (\(image.size.width)px)")
      return image
    }
    let scale = targetWidth / image.size.width
    let targetHeight = image.size.height * scale
    let size = CGSize(width: targetWidth, height: targetHeight)
    let renderer = UIGraphicsImageRenderer(size: size)
    print("[DEBUG] resizeImage: Resizing from \(image.size.width)px to \(targetWidth)px")
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }

  // MARK: - Audio Helpers
  private func toggleRecording() {
    isRecording.toggle()
    if isRecording {
      audioTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
        recordingTime += 0.1
      }
    } else {
      Task {
        await MainActor.run { isUploading = true; uploadingLabel = "Saving audio..." }
        await saveMemory(
          type: .audio, title: "Voice Memo (\(timeString(from: recordingTime, short: true)))")
        await MainActor.run { isUploading = false; stopRecording() }
      }
    }
  }

  private func stopRecording() {
    isRecording = false
    audioTimer?.invalidate()
    audioTimer = nil
    recordingTime = 0
  }

  private func deleteRoom() {
    Task {
      do {
        try await Database.shared.deleteRoom(id: currentRoom.id)
        await MainActor.run { dismiss() }
      } catch {
        print("Delete failed: \(error)")
      }
    }
  }

  private func updateRoom(
    name: String, description: String, tags: [String], isPrivate: Bool, isTimeCapsule: Bool,
    days: Int, hours: Int, mins: Int,
    unlockDate: Date?,  // NEW
    backgroundMusic: String?,
    theme: String,
    expirationDate: Date?,
    rollingExpiryDays: Int,
    collaborators: [Collaborator]
  ) {
    Task {
      do {
        try await Database.shared.updateRoom(
          id: currentRoom.id, name: name, description: description, tags: tags,
          isPrivate: isPrivate, isTimeCapsule: isTimeCapsule,
          capsuleDurationDays: days,
          capsuleDurationHours: hours,
          capsuleDurationMinutes: mins,
          unlockDate: unlockDate,  // NEW
          backgroundMusic: backgroundMusic,
          theme: theme,
          expirationDate: expirationDate,
          rollingExpiryDays: rollingExpiryDays,
          collaborators: collaborators)
        // Update local state
        await MainActor.run {
          currentRoom.name = name
          currentRoom.description = description
          currentRoom.tags = tags
          currentRoom.isPrivate = isPrivate
          currentRoom.isTimeCapsule = isTimeCapsule
          currentRoom.capsuleDurationDays = days
          currentRoom.capsuleDurationHours = hours
          currentRoom.capsuleDurationMinutes = mins
          currentRoom.unlockDate = unlockDate  // NEW
          currentRoom.theme = theme
          currentRoom.expirationDate = expirationDate
          currentRoom.rollingExpiryDays = rollingExpiryDays
          currentRoom.collaborators = collaborators

          // Re-calc unlock date if Duration mode
          if isTimeCapsule, unlockDate == nil {
            var components = DateComponents()
            components.day = days
            components.hour = hours
            components.minute = mins
            currentRoom.unlockDate = Calendar.current.date(
              byAdding: components, to: currentRoom.createdAt)
          }

          currentRoom.backgroundMusic = backgroundMusic
          // Update playing music
          AudioManager.shared.playBackgroundMusic(for: backgroundMusic)
        }
      } catch {
        print("Update failed: \(error)")
        await MainActor.run {
          alertMessage = "Update failed: \(error.localizedDescription)"
          showAlert = true
        }
      }
    }
  }

  private func timeString(from time: Double, short: Bool = false) -> String {
    let seconds = Int(time)
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    if short {
      return String(format: "%01d:%02d", minutes, remainingSeconds)
    }
    let tenths = Int((time * 10).truncatingRemainder(dividingBy: 10))
    return String(format: "%02d:%02d.%d", minutes, remainingSeconds, tenths)
  }

  private func timeAgoString(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
  }

  private func formatCountdown(_ diff: Double) -> String {
    if diff <= 0 { return "00:00:00" }
    let hours = Int(diff) / 3600
    let minutes = (Int(diff) % 3600) / 60
    let seconds = Int(diff) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }

  private func timeRemainingString(from created: Date, duration: Int) -> String {
    let unlockDate = Calendar.current.date(byAdding: .day, value: duration, to: created) ?? created
    let diff = unlockDate.timeIntervalSince(Date())

    if diff <= 0 { return "00:00:00" }

    let hours = Int(diff) / 3600
    let minutes = (Int(diff) % 3600) / 60
    let seconds = Int(diff) % 60

    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }
}

// MARK: - Reusable Components

struct GlassActionButton: View {
  let title: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(spacing: 12) {
      Circle()
        .fill(
          LinearGradient(
            colors: [color.opacity(0.6), color.opacity(0.3)], startPoint: .topLeading,
            endPoint: .bottomTrailing)
        )
        .frame(width: 56, height: 56)
        .overlay(
          Image(systemName: icon)
            .font(.system(size: 24))
            .foregroundColor(.white)
        )

      Text(title)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.white.opacity(0.05))
        .background(.ultraThinMaterial.opacity(0.2))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.white.opacity(0.1), lineWidth: 1)
    )
  }
}

struct GlassMemoryCard: View {
  let title: String
  let date: String
  let icon: String
  var image: UIImage? = nil

  var body: some View {
    HStack(spacing: 16) {
      if let uiImage = image {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
          .frame(width: 48, height: 48)
          .cornerRadius(8)
      } else {
        ZStack {
          Circle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 48, height: 48)
          Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundColor(.white)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
          .lineLimit(1)
        Text(date)
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.6))
      }

      Spacer()

      Image(systemName: "chevron.right")
        .foregroundColor(.white.opacity(0.4))
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.05))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.white.opacity(0.1), lineWidth: 1)
    )
  }
}

#Preview {
  RoomDetailView(
    room: RoomObject(
      name: "Example Room", ownerEmail: "user@test.com", isPrivate: false, isTimeCapsule: true,
      capsuleDurationDays: 21))
}

struct LivePulseIndicator: View {
  let color: Color
  @State private var isPulsing = false

  var body: some View {
    ZStack {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)

      Circle()
        .stroke(color, lineWidth: 2)
        .frame(width: 12, height: 12)
        .scaleEffect(isPulsing ? 1.5 : 1.0)
        .opacity(isPulsing ? 0 : 0.8)
    }
    .onAppear {
      withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
        isPulsing = true
      }
    }
  }
}
