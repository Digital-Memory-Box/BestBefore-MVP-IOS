import SwiftUI

struct EditRoomView: View {
  @Environment(\.dismiss) var dismiss
  let room: RoomObject
  var onSave:
    (
      String, String, [String], Bool, Bool, Int, Int, Int, Date?, String?, String, Date?, Int,
      [Collaborator]
    ) -> Void

  @State private var roomName: String
  @State private var descriptionText: String
  @State private var tags: [String]
  @State private var currentTag: String = ""
  @State private var isPrivate: Bool
  @State private var isTimeCapsule: Bool
  @State private var capsuleDuration: Int
  @State private var capsuleHours: Int
  @State private var capsuleMinutes: Int
  @State private var unlockDate: Date?  // Legacy mapping for init maybe?

  // New State for Picker
  enum LockMode: String, CaseIterable, Identifiable {
    case duration = "Duration"
    case date = "Date"
    var id: String { rawValue }
  }
  @State private var lockMode: LockMode = .duration
  @State private var targetDate: Date = Date().addingTimeInterval(86400)  // Default tomorrow
  @State private var backgroundMusic: String?
  @State private var selectedTheme: String

  private let presetTags = [
    "trip", "music", "science", "party", "family", "education", "art", "gaming", "fitness", "food",
  ]

  // Memory Dump Rules
  @State private var expirationDateEnabled: Bool
  @State private var expirationDate: Date
  @State private var rollingExpiryDays: Int

  // Collaborators
  @State private var collaborators: [Collaborator]
  @State private var newCollaboratorEmail: String = ""

  init(
    room: RoomObject,
    onSave:
      @escaping (
        String, String, [String], Bool, Bool, Int, Int, Int, Date?, String?, String, Date?, Int,
        [Collaborator]
      ) ->
      Void
  ) {
    self.room = room
    self.onSave = onSave
    _roomName = State(initialValue: room.name)
    _descriptionText = State(initialValue: room.description ?? "")
    _tags = State(initialValue: room.tags)
    _isPrivate = State(initialValue: room.isPrivate)
    _isTimeCapsule = State(initialValue: room.isTimeCapsule)
    _capsuleDuration = State(initialValue: room.capsuleDurationDays)
    _capsuleHours = State(initialValue: room.capsuleDurationHours)
    _capsuleMinutes = State(initialValue: room.capsuleDurationMinutes)
    _backgroundMusic = State(initialValue: room.backgroundMusic)
    _selectedTheme = State(initialValue: room.theme)

    _expirationDateEnabled = State(initialValue: room.expirationDate != nil)
    _expirationDate = State(
      initialValue: room.expirationDate ?? Date().addingTimeInterval(86400 * 30))
    _rollingExpiryDays = State(initialValue: room.rollingExpiryDays)
    _collaborators = State(initialValue: room.collaborators)

    // Init Lock Mode
    if let date = room.unlockDate {
      _lockMode = State(initialValue: .date)
      _targetDate = State(initialValue: date)
    } else {
      _lockMode = State(initialValue: .duration)
    }
  }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 24) {
        // Header
        HStack {
          Text("Edit Room")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
          Spacer()
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.gray)
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)

        ScrollView {
          VStack(alignment: .leading, spacing: 30) {
            // Room Name
            VStack(alignment: .leading, spacing: 12) {
              Text("Room Name")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
              TextField("Name", text: $roomName)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            }

            // Description
            VStack(alignment: .leading, spacing: 12) {
              Text("Description")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
              TextField("Description...", text: $descriptionText)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            }

            // Tags
            VStack(alignment: .leading, spacing: 12) {
              Text("Tags")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
              HStack {
                TextField("Add a tag...", text: $currentTag)
                  .padding()
                  .background(Color.white.opacity(0.1))
                  .cornerRadius(12)
                  .foregroundColor(.white)
                  .textInputAutocapitalization(.never)
                  .disableAutocorrection(true)
                  .onSubmit {
                    let tag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
                      .lowercased()
                    if !tag.isEmpty && !tags.contains(tag) {
                      withAnimation { tags.append(tag) }
                    }
                    currentTag = ""
                  }
                Button(action: {
                  let tag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                  if !tag.isEmpty && !tags.contains(tag) {
                    withAnimation { tags.append(tag) }
                  }
                  currentTag = ""
                }) {
                  Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(currentTag.isEmpty ? .gray : .blue)
                }
                .disabled(currentTag.isEmpty)
              }
              if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                  HStack {
                    ForEach(tags, id: \.self) { tag in
                      HStack(spacing: 4) {
                        Text("#\(tag)")
                          .font(.system(size: 14))
                        Button(action: {
                          withAnimation { tags.removeAll(where: { $0 == tag }) }
                        }) {
                          Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                        }
                      }
                      .padding(.horizontal, 10).padding(.vertical, 6)
                      .background(Color.blue.opacity(0.3))
                      .cornerRadius(16)
                      .foregroundColor(.white)
                    }
                  }
                }
              }

              // Preset Tags
              ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                  ForEach(presetTags, id: \.self) { tag in
                    Button(action: {
                      if !tags.contains(tag) {
                        withAnimation { tags.append(tag) }
                      }
                    }) {
                      Text("#\(tag)")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                          tags.contains(tag) ? Color.blue.opacity(0.8) : Color.white.opacity(0.1)
                        )
                        .foregroundColor(tags.contains(tag) ? .white : .gray)
                        .cornerRadius(16)
                    }
                  }
                }
              }
            }

            // Privacy
            VStack(alignment: .leading, spacing: 16) {
              Text("Privacy Status")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

              HStack(spacing: 12) {
                PrivacyOption(
                  title: "Public",
                  subtitle: "Anyone can see.",
                  icon: "globe",
                  isSelected: !isPrivate,
                  tintColor: .blue,
                  action: { isPrivate = false }
                )
                PrivacyOption(
                  title: "Private",
                  subtitle: "Only invited.",
                  icon: "lock.fill",
                  isSelected: isPrivate,
                  tintColor: .blue,
                  action: { isPrivate = true }
                )
              }
            }

            // Time Capsule
            VStack(alignment: .leading, spacing: 20) {
              Toggle(isOn: $isTimeCapsule) {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Enable Time Capsule")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                  Text("Content hidden until timer ends.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                }
              }
              .toggleStyle(SwitchToggleStyle(tint: .blue))
              .padding()
              .background(Color.white.opacity(0.1))
              .cornerRadius(12)

              if isTimeCapsule {
                VStack(alignment: .leading, spacing: 16) {
                  Text("Unlock Method")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                  Picker("Lock Mode", selection: $lockMode) {
                    Text("Duration").tag(LockMode.duration)
                    Text("Specific Date").tag(LockMode.date)
                  }
                  .pickerStyle(SegmentedPickerStyle())
                  .colorScheme(.dark)

                  if lockMode == .duration {
                    VStack(alignment: .leading, spacing: 20) {
                      HStack(spacing: 12) {
                        VStack(alignment: .center, spacing: 4) {
                          Text("Days").font(.caption).foregroundColor(.gray)
                          Stepper("\(capsuleDuration)", value: $capsuleDuration, in: 0...365)
                            .labelsHidden()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }

                        VStack(alignment: .center, spacing: 4) {
                          Text("Hours").font(.caption).foregroundColor(.gray)
                          Stepper("\(capsuleHours)", value: $capsuleHours, in: 0...23)
                            .labelsHidden()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }

                        VStack(alignment: .center, spacing: 4) {
                          Text("Mins").font(.caption).foregroundColor(.gray)
                          Stepper("\(capsuleMinutes)", value: $capsuleMinutes, in: 0...59)
                            .labelsHidden()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                      }
                      .padding()
                      .background(Color.white.opacity(0.05))
                      .cornerRadius(12)

                      Text("\(capsuleDuration)d \(capsuleHours)h \(capsuleMinutes)m")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding(.leading, 8)

                      // Presets
                      HStack(spacing: 8) {
                        DurationButton(label: "1 Week", days: 7, current: $capsuleDuration, tintColor: .blue)
                        DurationButton(label: "21 Days", days: 21, current: $capsuleDuration, tintColor: .blue)
                        DurationButton(label: "1 Month", days: 30, current: $capsuleDuration, tintColor: .blue)
                      }
                    }
                  } else {
                    DatePicker(
                      "Unlock Date",
                      selection: $targetDate,
                      in: Date()...,
                      displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .colorScheme(.dark)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                  }
                }
              }
            }

            Divider().background(Color.white.opacity(0.1))

            // --- MEMORY DUMP RULES ---
            VStack(alignment: .leading, spacing: 16) {
              Text("Memory Dump Rules")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

              // Option A: Rolling Expiry
              VStack(alignment: .leading, spacing: 12) {
                Text("Rolling Expiration (Snapchat Mode)")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundColor(.white)

                Text("Automatically archive memories X days after they are posted.")
                  .font(.system(size: 12))
                  .foregroundColor(.gray)

                Picker("Rolling Expiry", selection: $rollingExpiryDays) {
                  Text("Never").tag(0)
                  Text("1 Day (24 hrs)").tag(1)
                  Text("7 Days").tag(7)
                  Text("30 Days").tag(30)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 4)
              }
              .padding()
              .background(Color.white.opacity(0.05))
              .cornerRadius(12)

              // Option C: Room Expiration
              VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $expirationDateEnabled) {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Scheduled Room Closure")
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundColor(.white)

                    Text(
                      "Lock the entire room into a read-only archive state after a specific date."
                    )
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                  }
                }
                .tint(.blue)

                if expirationDateEnabled {
                  DatePicker(
                    "Closure Date",
                    selection: $expirationDate,
                    in: Date()...,
                    displayedComponents: [.date]
                  )
                  .datePickerStyle(GraphicalDatePickerStyle())
                  .colorScheme(.dark)
                  .padding()
                  .background(Color.white.opacity(0.1))
                  .cornerRadius(12)
                  .transition(.opacity.combined(with: .move(edge: .top)))
                }
              }
              .padding()
              .background(Color.white.opacity(0.05))
              .cornerRadius(12)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

            // --- COLLABORATORS (Group Control) ---
            VStack(alignment: .leading, spacing: 16) {
              Text("Invite Friends")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

              Text("Add email addresses of people who can post memories to this room.")
                .font(.system(size: 12))
                .foregroundColor(.gray)

              if !collaborators.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 8) {
                    ForEach(collaborators, id: \.self) { collab in
                      Menu {
                        Button {
                          updateRole(for: collab.email, role: .viewer)
                        } label: {
                          Label("Set as Viewer", systemImage: "eye")
                        }
                        Button {
                          updateRole(for: collab.email, role: .contributor)
                        } label: {
                          Label("Set as Contributor", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                          collaborators.removeAll { $0.email == collab.email }
                        } label: {
                          Label("Remove", systemImage: "trash")
                        }
                      } label: {
                        HStack(spacing: 6) {
                          VStack(alignment: .leading, spacing: 2) {
                            Text(collab.email)
                              .font(.system(size: 14, weight: .medium))
                            Text(collab.role.rawValue.capitalized)
                              .font(.system(size: 10))
                              .opacity(0.8)
                          }
                          .foregroundColor(.white)

                          Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                          collab.role == .contributor
                            ? Color.blue.opacity(0.3) : Color.purple.opacity(0.3)
                        )
                        .clipShape(Capsule())
                        .overlay(
                          Capsule().stroke(
                            collab.role == .contributor
                              ? Color.blue.opacity(0.5) : Color.purple.opacity(0.5), lineWidth: 1)
                        )
                      }
                    }
                  }
                }
              }

              HStack {
                TextField("Friend's Email Address", text: $newCollaboratorEmail)
                  .padding()
                  .background(Color.white.opacity(0.1))
                  .cornerRadius(12)
                  .foregroundColor(.white)
                  .font(.system(size: 16))
                  .keyboardType(.emailAddress)
                  .autocapitalization(.none)
                  .onSubmit {
                    addCollaborator()
                  }

                Button(action: addCollaborator) {
                  Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(newCollaboratorEmail.isEmpty ? .gray : .blue)
                }
                .disabled(newCollaboratorEmail.isEmpty)
              }
            }

            // --- THEME SELECTOR ---
            VStack(alignment: .leading, spacing: 12) {
              Text("Room Theme")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                  ThemeOption(
                    title: "Default", color: .blue, isSelected: selectedTheme == "default"
                  ) { selectedTheme = "default" }
                  ThemeOption(title: "Ocean", color: .teal, isSelected: selectedTheme == "ocean") {
                    selectedTheme = "ocean"
                  }
                  ThemeOption(
                    title: "Sunset", color: .orange, isSelected: selectedTheme == "sunset"
                  ) { selectedTheme = "sunset" }
                  ThemeOption(title: "Forest", color: .green, isSelected: selectedTheme == "forest")
                  { selectedTheme = "forest" }
                  ThemeOption(
                    title: "Cyberpunk", color: .purple, isSelected: selectedTheme == "cyberpunk"
                  ) { selectedTheme = "cyberpunk" }
                }
              }
            }

            Divider().background(Color.white.opacity(0.1))

            // Background Music
            VStack(alignment: .leading, spacing: 16) {
              Text("Atmosphere")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

              VStack(spacing: 12) {
                MusicPresetOption(
                  title: "None", icon: "speaker.slash.fill", isSelected: backgroundMusic == nil,
                  tintColor: .blue
                ) {
                  backgroundMusic = nil
                }
                MusicPresetOption(
                  title: "Lofi Beats", icon: "music.note",
                  isSelected: backgroundMusic == "Lofi Beats",
                  tintColor: .blue
                ) {
                  backgroundMusic = "Lofi Beats"
                }
                MusicPresetOption(
                  title: "Nature Ambience", icon: "leaf.fill",
                  isSelected: backgroundMusic == "Nature Ambience",
                  tintColor: .blue
                ) {
                  backgroundMusic = "Nature Ambience"
                }
                MusicPresetOption(
                  title: "Minimal Piano", icon: "pianokeys",
                  isSelected: backgroundMusic == "Minimal Piano",
                  tintColor: .blue
                ) {
                  backgroundMusic = "Minimal Piano"
                }
                MusicPresetOption(
                  title: "Vaporwave", icon: "sparkles", isSelected: backgroundMusic == "Vaporwave",
                  tintColor: .blue
                ) {
                  backgroundMusic = "Vaporwave"
                }

                Divider().background(Color.white.opacity(0.1))
                  .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                  Text("Custom SoundCloud Link")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))

                  TextField(
                    "Paste SoundCloud playlist or track URL",
                    text: Binding(
                      get: {
                        if let music = backgroundMusic, music.contains("soundcloud.com") {
                          return music
                        }
                        return ""
                      },
                      set: { backgroundMusic = $0.isEmpty ? nil : $0 }
                    )
                  )
                  .padding()
                  .background(Color.white.opacity(0.05))
                  .cornerRadius(12)
                  .foregroundColor(.blue)
                  .font(.system(size: 14, design: .monospaced))
                  .autocapitalization(.none)
                  .disableAutocorrection(true)

                  Text("Use this to play your custom SoundCloud playlist in this room.")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                }
              }
            }
          }
          .padding(.horizontal, 24)
        }

        Spacer()

        Button {
          let finalDate = (lockMode == .date) ? targetDate : nil
          let finalExpiration = expirationDateEnabled ? expirationDate : nil
          onSave(
            roomName, descriptionText, tags, isPrivate, isTimeCapsule,
            capsuleDuration, capsuleHours, capsuleMinutes,
            finalDate,
            backgroundMusic, selectedTheme, finalExpiration, rollingExpiryDays, collaborators)
          dismiss()
        } label: {
          Text("Save Changes")
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(roomName.isEmpty ? Color.gray : .blue)
            .cornerRadius(12)
        }
        .disabled(roomName.isEmpty)
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
      }
    }
  }

  private func addCollaborator() {
    let email = newCollaboratorEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !email.isEmpty else { return }

    if !collaborators.contains(where: { $0.email == email }) {
      withAnimation {
        collaborators.append(Collaborator(email: email, role: .contributor))
        newCollaboratorEmail = ""
      }
    }
  }

  private func updateRole(for email: String, role: CollaboratorRole) {
    if let index = collaborators.firstIndex(where: { $0.email == email }) {
      withAnimation {
        collaborators[index].role = role
      }
    }
  }
}
