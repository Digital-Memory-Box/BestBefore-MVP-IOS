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

  var onComplete: (String, Bool, Bool, Int, Int, Int, Date?, String?) -> Void

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
            .frame(width: 40, height: 2)
          Circle()
            .fill(step >= 2 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 10, height: 10)
          Rectangle()
            .fill(step >= 3 ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 40, height: 2)
          Circle()
            .fill(step >= 3 ? Color.blue : Color.gray.opacity(0.3))
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
        } else {
          stepThreeView
            .transition(
              .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }

        Spacer()

        // Navigation Buttons
        HStack {
          if step == 2 {
            Button {
              withAnimation { step = 1 }
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
            if step == 1 {
              if !roomName.isEmpty {
                withAnimation { step += 1 }
              }
            } else if step == 2 {
              withAnimation { step = 3 }
            } else {
              let finalDate = (lockMode == .date) ? targetDate : nil
              onComplete(
                roomName, isPrivate, timeCapsuleEnabled, capsuleDuration, capsuleHours,
                capsuleMinutes, finalDate, selectedMusic)
              dismiss()
            }
          } label: {
            Text(step < 3 ? "Next" : "Create Room")
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
            title: "Minimal Piano", icon: "pianokeys", isSelected: selectedMusic == "Minimal Piano"
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
    .padding(.horizontal, 24)
  }
}

#Preview {
  CreateRoomFlowView { _, _, _, _, _, _, _, _ in }
}
