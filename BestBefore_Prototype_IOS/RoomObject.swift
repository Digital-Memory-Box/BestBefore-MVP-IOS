import Foundation

struct RoomObject: Identifiable, Hashable, Codable {
  var id: String
  var name: String
  var ownerEmail: String?
  var imageName: String?
  var isPrivate: Bool
  var isTimeCapsule: Bool
  var capsuleDurationDays: Int
  var capsuleDurationHours: Int
  var capsuleDurationMinutes: Int
  var backgroundMusic: String?
  var unlockDate: Date?  // NEW
  var createdAt: Date = Date()

  init(
    id: String = UUID().uuidString,
    name: String,
    ownerEmail: String?,
    imageName: String? = nil,
    isPrivate: Bool = false,
    isTimeCapsule: Bool = false,
    capsuleDurationDays: Int = 21,
    capsuleDurationHours: Int = 0,
    capsuleDurationMinutes: Int = 0,
    unlockDate: Date? = nil,  // NEW
    backgroundMusic: String? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.ownerEmail = ownerEmail
    self.imageName = imageName
    self.isPrivate = isPrivate
    self.isTimeCapsule = isTimeCapsule
    self.capsuleDurationDays = capsuleDurationDays
    self.capsuleDurationHours = capsuleDurationHours
    self.capsuleDurationMinutes = capsuleDurationMinutes
    self.unlockDate = unlockDate  // NEW
    self.backgroundMusic = backgroundMusic
    self.createdAt = createdAt

    // Auto-calculate unlockDate from duration if missing but capsule enabled
    if isTimeCapsule, self.unlockDate == nil {
      var components = DateComponents()
      components.day = capsuleDurationDays
      components.hour = capsuleDurationHours
      components.minute = capsuleDurationMinutes
      self.unlockDate = Calendar.current.date(byAdding: components, to: createdAt)
    }
  }

  var isLocked: Bool {
    guard isTimeCapsule else { return false }
    // If unlockDate exists, check it. Otherwise fallback to old duration logic.
    if let unlockDate = unlockDate {
      return Date() < unlockDate
    }
    return secondsRemaining > 0
  }

  var secondsRemaining: Double {
    guard isTimeCapsule else { return 0 }

    // Priority: unlockDate
    if let unlockDate = unlockDate {
      return max(0, unlockDate.timeIntervalSince(Date()))
    }

    // Fallback: Duration
    var components = DateComponents()
    components.day = capsuleDurationDays
    components.hour = capsuleDurationHours
    components.minute = capsuleDurationMinutes

    let targetDate = Calendar.current.date(byAdding: components, to: createdAt) ?? createdAt
    return max(0, targetDate.timeIntervalSince(Date()))
  }
}

// --- Memory Models ---

enum MemoryType: String, Codable {
  case photo
  case note
  case audio
  case video  // NEW
  case music  // NEW

  var icon: String {
    switch self {
    case .photo: return "photo.fill"
    case .note: return "doc.text.fill"
    case .audio: return "mic.fill"
    case .video: return "film.fill"  // NEW
    case .music: return "music.note"  // NEW
    }
  }
}

struct MemoryItem: Identifiable, Codable {
  var id: String
  let type: MemoryType
  let title: String
  let date: Date
  var content: String?  // URL or Note Text

  init(
    id: String = UUID().uuidString, type: MemoryType, title: String, date: Date = Date(),
    content: String? = nil
  ) {
    self.id = id
    self.type = type
    self.title = title
    self.date = date
    self.content = content
  }
}
