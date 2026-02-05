import SwiftUI

struct EditRoomView: View {
  @Environment(\.dismiss) var dismiss
  let room: RoomObject
  var onSave: (String, Bool, Bool, Int, Int, Int, Date?, String?) -> Void

  @State private var roomName: String
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

  init(
    room: RoomObject, onSave: @escaping (String, Bool, Bool, Int, Int, Int, Date?, String?) -> Void
  ) {
    self.room = room
    self.onSave = onSave
    _roomName = State(initialValue: room.name)
    _isPrivate = State(initialValue: room.isPrivate)
    _isTimeCapsule = State(initialValue: room.isTimeCapsule)
    _capsuleDuration = State(initialValue: room.capsuleDurationDays)
    _capsuleHours = State(initialValue: room.capsuleDurationHours)
    _capsuleMinutes = State(initialValue: room.capsuleDurationMinutes)
    _backgroundMusic = State(initialValue: room.backgroundMusic)

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
                  action: { isPrivate = false }
                )
                PrivacyOption(
                  title: "Private",
                  subtitle: "Only invited.",
                  icon: "lock.fill",
                  isSelected: isPrivate,
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
                    // ... Existing Steppers ...
                    HStack(spacing: 12) {
                      // ... (Steppers code)
                    }
                    // ... (Duration Buttons)
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

            // Background Music
            VStack(alignment: .leading, spacing: 16) {
              Text("Atmosphere")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

              VStack(spacing: 12) {
                MusicPresetOption(
                  title: "None", icon: "speaker.slash.fill", isSelected: backgroundMusic == nil
                ) {
                  backgroundMusic = nil
                }
                MusicPresetOption(
                  title: "Lofi Beats", icon: "music.note",
                  isSelected: backgroundMusic == "Lofi Beats"
                ) {
                  backgroundMusic = "Lofi Beats"
                }
                MusicPresetOption(
                  title: "Nature Ambience", icon: "leaf.fill",
                  isSelected: backgroundMusic == "Nature Ambience"
                ) {
                  backgroundMusic = "Nature Ambience"
                }
                MusicPresetOption(
                  title: "Minimal Piano", icon: "pianokeys",
                  isSelected: backgroundMusic == "Minimal Piano"
                ) {
                  backgroundMusic = "Minimal Piano"
                }
                MusicPresetOption(
                  title: "Vaporwave", icon: "sparkles", isSelected: backgroundMusic == "Vaporwave"
                ) {
                  backgroundMusic = "Vaporwave"
                }
              }
            }
          }
          .padding(.horizontal, 24)
        }

        Spacer()

        Button {
          let finalDate = (lockMode == .date) ? targetDate : nil
          onSave(
            roomName, isPrivate, isTimeCapsule,
            capsuleDuration, capsuleHours, capsuleMinutes,
            finalDate,
            backgroundMusic)
          dismiss()
        } label: {
          Text("Save Changes")
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(roomName.isEmpty ? Color.gray : Color.blue)
            .cornerRadius(12)
        }
        .disabled(roomName.isEmpty)
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
      }
    }
  }
}
