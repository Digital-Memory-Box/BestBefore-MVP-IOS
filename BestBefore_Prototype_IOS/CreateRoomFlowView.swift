import SwiftUI

struct CreateRoomFlowView: View {
  @Environment(\.dismiss) var dismiss
  @State private var step = 1

  // Step 1 Data
  @State private var roomName = ""
  @State private var isPrivate = false

  // Step 2 Data
  @State private var timeCapsuleEnabled = false
  @State private var capsuleDuration = 21
  @State private var capsuleHours = 0
  @State private var capsuleMinutes = 0

  // New Lock Mode State
  enum LockMode: String, CaseIterable, Identifiable {
    case duration = "Duration"
    case date = "Date"
    var id: String { rawValue }
  }
  @State private var lockMode: LockMode = .duration
  @State private var targetDate: Date = Date().addingTimeInterval(86400)  // Default tomorrow

  @State private var selectedMusic: String? = nil
  @State private var selectedTheme: String = "default"

  // Step 4 Data - Memory Dump Rules
  @State private var expirationDateEnabled = false
  @State private var expirationDate: Date = Date().addingTimeInterval(86400 * 30)  // Default 30 days
  @State private var rollingExpiryDays: Int = 0  // 0 = Never

  // Step 5 Data - Collaborators
  @State private var collaborators: [Collaborator] = []
  @State private var newCollaboratorEmail: String = ""

  var onComplete:
    (String, Bool, Bool, Int, Int, Int, Date?, String?, String, Date?, Int, [Collaborator]) -> Void

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 30) {
        // Header
        HStack {
          Text("Create Room")
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

        // Progress Indicator
        HStack(spacing: 8) {
          Circle()
            .fill(step >= 1 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 10, height: 10)
          Rectangle()
            .fill(step >= 2 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 30, height: 2)
          Circle()
            .fill(step >= 2 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 10, height: 10)
          Rectangle()
            .fill(step >= 3 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 30, height: 2)
          Circle()
            .fill(step >= 3 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 10, height: 10)
          Rectangle()
            .fill(step >= 4 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 30, height: 2)
          Circle()
            .fill(step >= 4 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 10, height: 10)
          Rectangle()
            .fill(step >= 5 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 30, height: 2)
          Circle()
            .fill(step >= 5 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 10, height: 10)
        }

        if step == 1 {
          stepOneView
            .transition(
              .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else if step == 2 {
          stepTwoView
            .transition(
              .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else if step == 3 {
          stepThreeView
            .transition(
              .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else if step == 4 {
          stepFourView
            .transition(
              .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else {
          stepFiveView
            .transition(
              .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }

        Spacer()

        // Navigation Buttons
        HStack {
          if step > 1 {
            Button {
              withAnimation { step -= 1 }
            } label: {
              Text("Back")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
          }

          Button {
            if step < 5 {
              if step == 1 && roomName.isEmpty { return }
              withAnimation { step += 1 }
            } else {
              let finalDate = (lockMode == .date) ? targetDate : nil
              let finalExpiration = expirationDateEnabled ? expirationDate : nil
              onComplete(
                roomName, isPrivate, timeCapsuleEnabled, capsuleDuration, capsuleHours,
                capsuleMinutes, finalDate, selectedMusic, selectedTheme, finalExpiration,
                rollingExpiryDays, collaborators)
              dismiss()
            }
          } label: {
            Text(step < 5 ? "Next" : "Create Room")
              .fontWeight(.bold)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(roomName.isEmpty ? Color.gray : Color.blue)
              .cornerRadius(12)
          }
          .disabled(roomName.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
      }
    }
  }

  var stepOneView: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 8) {
        Text("What's the name?")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.white)
        Text("Give your room a unique title.")
          .font(.system(size: 16))
          .foregroundColor(.gray)
      }

      TextField("Room Name", text: $roomName)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .foregroundColor(.white)
        .font(.system(size: 18, weight: .medium))

      VStack(alignment: .leading, spacing: 16) {
        Text("Privacy Status")
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.white)

        HStack(spacing: 12) {
          PrivacyOption(
            title: "Public",
            subtitle: "Anyone can see and join.",
            icon: "globe",
            isSelected: !isPrivate,
            action: { isPrivate = false }
          )
          PrivacyOption(
            title: "Private",
            subtitle: "Only visible to invited.",
            icon: "lock.fill",
            isSelected: isPrivate,
            action: { isPrivate = true }
          )
        }
      }
    }
    .padding(.horizontal, 24)
  }

  var stepTwoView: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Time Capsule?")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.white)
        Text("Lock memories for a future date.")
          .font(.system(size: 16))
          .foregroundColor(.gray)
      }

      VStack(alignment: .leading, spacing: 20) {
        Toggle(isOn: $timeCapsuleEnabled) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Enable Time Capsule")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)
            Text("Content will be hidden until the timer ends.")
              .font(.system(size: 12))
              .foregroundColor(.gray)
          }
        }
        .toggleStyle(SwitchToggleStyle(tint: .blue))
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)

        if timeCapsuleEnabled {
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
                DurationButton(label: "1 Week", days: 7, current: $capsuleDuration)
                DurationButton(label: "21 Days", days: 21, current: $capsuleDuration)
                DurationButton(label: "1 Month", days: 30, current: $capsuleDuration)
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
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
    .padding(.horizontal, 24)
  }

  var stepThreeView: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Atmosphere")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.white)
        Text("Set the mood with background music.")
          .font(.system(size: 16))
          .foregroundColor(.gray)
      }

      ScrollView {
        VStack(spacing: 24) {
          // --- THEME SELECTOR ---
          VStack(alignment: .leading, spacing: 12) {
            Text("Room Theme")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 12) {
                ThemeOption(title: "Default", color: .blue, isSelected: selectedTheme == "default")
                { selectedTheme = "default" }
                ThemeOption(title: "Ocean", color: .teal, isSelected: selectedTheme == "ocean") {
                  selectedTheme = "ocean"
                }
                ThemeOption(title: "Sunset", color: .orange, isSelected: selectedTheme == "sunset")
                { selectedTheme = "sunset" }
                ThemeOption(title: "Forest", color: .green, isSelected: selectedTheme == "forest") {
                  selectedTheme = "forest"
                }
                ThemeOption(
                  title: "Cyberpunk", color: .purple, isSelected: selectedTheme == "cyberpunk"
                ) { selectedTheme = "cyberpunk" }
              }
            }
          }

          Divider().background(Color.white.opacity(0.1))

          // --- MUSIC SELECTOR ---
          VStack(alignment: .leading, spacing: 12) {
            Text("Background Music")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.white)

            VStack(spacing: 12) {
              MusicPresetOption(
                title: "None", icon: "speaker.slash.fill", isSelected: selectedMusic == nil
              ) {
                selectedMusic = nil
              }

              MusicPresetOption(
                title: "Lofi Beats", icon: "music.note", isSelected: selectedMusic == "Lofi Beats"
              ) {
                selectedMusic = "Lofi Beats"
              }

              MusicPresetOption(
                title: "Nature Ambience", icon: "leaf.fill",
                isSelected: selectedMusic == "Nature Ambience"
              ) {
                selectedMusic = "Nature Ambience"
              }

              MusicPresetOption(
                title: "Minimal Piano", icon: "pianokeys",
                isSelected: selectedMusic == "Minimal Piano"
              ) {
                selectedMusic = "Minimal Piano"
              }

              MusicPresetOption(
                title: "Vaporwave", icon: "sparkles", isSelected: selectedMusic == "Vaporwave"
              ) {
                selectedMusic = "Vaporwave"
              }
            }
          }
        }
      }
    }
    .padding(.horizontal, 24)
  }

  // --- NEW STEP 4: Memory Dump Rules ---
  var stepFourView: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Memory Dump Rules")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.white)
        Text("Configure auto-archival for drops.")
          .font(.system(size: 16))
          .foregroundColor(.gray)
      }

      ScrollView {
        VStack(spacing: 24) {

          // Option A: Rolling Expiry
          VStack(alignment: .leading, spacing: 12) {
            Text("Rolling Expiration (Snapchat Mode)")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)

            Text("Automatically archive memories X days after they are posted.")
              .font(.system(size: 14))
              .foregroundColor(.gray)

            Picker("Rolling Expiry", selection: $rollingExpiryDays) {
              Text("Never").tag(0)
              Text("1 Day (24 hrs)").tag(1)
              Text("7 Days").tag(7)
              Text("30 Days").tag(30)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.top, 8)
          }
          .padding()
          .background(Color.white.opacity(0.05))
          .cornerRadius(12)

          // Option C: Room Expiration
          VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $expirationDateEnabled) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Scheduled Room Closure")
                  .font(.system(size: 18, weight: .bold))
                  .foregroundColor(.white)

                Text("Lock the entire room into a read-only archive state after a specific date.")
                  .font(.system(size: 14))
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
      }
    }
    .padding(.horizontal, 24)
  }

  // --- NEW STEP 5: Collaborator Group ---
  var stepFiveView: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Invite Friends")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.white)
        Text("Add people and assign them roles (Viewer or Contributor).")
          .font(.system(size: 16))
          .foregroundColor(.gray)
      }

      // Selected Collaborator Chips
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
                  collab.role == .contributor ? Color.blue.opacity(0.3) : Color.purple.opacity(0.3)
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

      // Input Field
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
    .padding(.horizontal, 24)
  }

  private func addCollaborator() {
    let email = newCollaboratorEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !email.isEmpty else { return }

    if !collaborators.contains(where: { $0.email == email }) {
      withAnimation {
        collaborators.append(Collaborator(email: email, role: .contributor))  // Default: Contributor
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

#Preview {

  CreateRoomFlowView { _, _, _, _, _, _, _, _, _, _, _, _ in }
}
