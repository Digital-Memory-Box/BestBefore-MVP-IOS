import FirebaseAuth
import Foundation

struct RoomDTO: Codable {
  var _id: String?
  var name: String
  var ownerEmail: String?
  var description: String?
  var tags: [String]?
  var isPrivate: Bool?
  var isTimeCapsule: Bool?
  var capsuleDurationDays: Int?
  var capsuleDurationHours: Int?
  var capsuleDurationMinutes: Int?
  var unlockDate: Date?
  var backgroundMusic: String?
  var theme: String?
  var expirationDate: Date?
  var uploadStartDate: Date?
  var rollingExpiryDays: Int?
  var collaborators: [Collaborator]?  // CHANGED
  var collaboratorEmails: [String]?  // BACKWARD COMPATIBILITY
    var linkedRooms: [LinkedRoom]?
    var createdAt: Date
}

struct HandshakeInviteDTO: Codable, Identifiable {
    var id: String { _id }
    var _id: String
    var roomId: String
    var roomName: String
    var inviterEmail: String
    var inviteeEmail: String
    var passcode: String
    var status: String
    var expiresAt: Date
}

// ... (Floating code removed) ...

enum AppError: Error, LocalizedError {
  case backendError(String)
  case unknown
  case notAuthenticated

  var errorDescription: String? {
    switch self {
    case .backendError(let msg): return msg
    case .unknown: return "An unknown error occurred"
    case .notAuthenticated: return "User is not authenticated"
    }
  }
}

private final class BackendAPIClient: @unchecked Sendable {
  private let baseURL: URL
  private let session: URLSession
  private let decoder: JSONDecoder

  init(baseURL: URL, session: URLSession = .shared) {
    self.baseURL = baseURL
    self.session = session
    self.decoder = JSONDecoder()
    self.decoder.dateDecodingStrategy = .iso8601
  }

  // Helper to attach async Firebase token
  private func authorizedRequest(to url: URL, method: String = "GET") async throws -> URLRequest {
    var req = URLRequest(url: url)
    req.httpMethod = method

    // Get fresh token from Firebase
    guard let currentUser = Auth.auth().currentUser else {
      // If not logged in, we decide if we throw or just send without token.
      // Most endpoints require auth, so we throw.
      // If you have public endpoints, you might handle this differently.
      return req
    }

    let token = try await currentUser.getIDToken()
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return req
  }

  func getRooms() async throws -> [RoomDTO] {
    let url = baseURL.appendingPathComponent("rooms")
    let req = try await authorizedRequest(to: url, method: "GET")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }

    return try decoder.decode([RoomDTO].self, from: data)
  }

  func getDiscoverableRooms() async throws -> [RoomDTO] {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent("discover")
    let req = try await authorizedRequest(to: url, method: "GET")

    let (data, _) = try await session.data(for: req)
    return try decoder.decode([RoomDTO].self, from: data)
  }

  func getRoom(id: String) async throws -> RoomDTO {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent(id)
    let req = try await authorizedRequest(to: url, method: "GET")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg = String(data: data, encoding: .utf8) ?? "Failed to fetch room"
      throw AppError.backendError(msg)
    }

    return try decoder.decode(RoomDTO.self, from: data)
  }

  func createRoom(
    name: String, ownerEmail: String?, description: String?, tags: [String], isPrivate: Bool,
    isTimeCapsule: Bool,
    capsuleDurationDays: Int, capsuleDurationHours: Int, capsuleDurationMinutes: Int,
    unlockDate: Date?,
    backgroundMusic: String?,
    theme: String = "default",
    expirationDate: Date? = nil,
    uploadStartDate: Date? = nil,
    rollingExpiryDays: Int = 0,
    collaborators: [Collaborator] = [],  // CHANGED
    linkedRooms: [LinkedRoom] = []
  )
    async throws -> String
  {
    let url = baseURL.appendingPathComponent("rooms")
    var req = try await authorizedRequest(to: url, method: "POST")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // Manual encoding for Dates to ensure ISO string
    let formatter = ISO8601DateFormatter()
    var unlockDateString: String? = nil
    if let date = unlockDate {
      unlockDateString = formatter.string(from: date)
    }

    var expirationDateString: String? = nil
    if let edate = expirationDate {
      expirationDateString = formatter.string(from: edate)
    }

    var uploadStartDateString: String? = nil
    if let sdate = uploadStartDate {
      uploadStartDateString = formatter.string(from: sdate)
    }

    let body: [String: Any?] = [
      "name": name,
      "ownerEmail": ownerEmail,
      "description": description,
      "tags": tags,
      "isPrivate": isPrivate,
      "isTimeCapsule": isTimeCapsule,
      "capsuleDurationDays": capsuleDurationDays,
      "capsuleDurationHours": capsuleDurationHours,
      "capsuleDurationMinutes": capsuleDurationMinutes,
      "unlockDate": unlockDateString,
      "backgroundMusic": backgroundMusic,
      "theme": theme,
      "expirationDate": expirationDateString,
      "uploadStartDate": uploadStartDateString,
      "rollingExpiryDays": rollingExpiryDays,
      "collaborators": collaborators.map { ["email": $0.email, "role": $0.role.rawValue] },  // CHANGED
      "linkedRooms": linkedRooms.map { ["roomId": $0.roomId, "type": $0.type] },
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }

    struct InsertResponse: Decodable { let id: String }
    return try JSONDecoder().decode(InsertResponse.self, from: data).id
  }

  func updateRoom(
    id _id: String, name _name: String?, description _description: String?, tags _tags: [String]?,
    isPrivate _isPrivate: Bool?,
    isTimeCapsule _isTimeCapsule: Bool?,
    capsuleDurationDays _days: Int?, capsuleDurationHours _hours: Int?,
    capsuleDurationMinutes _mins: Int?,
    unlockDate _unlockDate: Date?,
    backgroundMusic _music: String?,
    theme _theme: String?,
    expirationDate _expirationDate: Date?,
    uploadStartDate _uploadStartDate: Date?,
    rollingExpiryDays _rollingExpiryDays: Int?,
    collaborators _collaborators: [Collaborator]?,  // CHANGED
    linkedRooms _linkedRooms: [LinkedRoom]?
  ) async throws {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent(_id)
    var req = try await authorizedRequest(to: url, method: "PATCH")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let formatter = ISO8601DateFormatter()

    var body: [String: Any] = [:]
    if let nameValue = _name { body["name"] = nameValue }
    if let descriptionValue = _description { body["description"] = descriptionValue }
    if let tagsValue = _tags { body["tags"] = tagsValue }
    if let privateValue = _isPrivate { body["isPrivate"] = privateValue }
    if let capsuleValue = _isTimeCapsule { body["isTimeCapsule"] = capsuleValue }
    if let daysValue = _days { body["capsuleDurationDays"] = daysValue }
    if let hoursValue = _hours { body["capsuleDurationHours"] = hoursValue }
    if let minsValue = _mins { body["capsuleDurationMinutes"] = minsValue }

    if let unlockVal = _unlockDate {
      body["unlockDate"] = formatter.string(from: unlockVal)
    }

    if let themeValue = _theme { body["theme"] = themeValue }

    if let expiryVal = _expirationDate {
      body["expirationDate"] = formatter.string(from: expiryVal)
    }

    if let startVal = _uploadStartDate {
      body["uploadStartDate"] = formatter.string(from: startVal)
    }

    if let rollingValue = _rollingExpiryDays {
      body["rollingExpiryDays"] = rollingValue
    }

    if let collaboratorsVal = _collaborators {
      body["collaborators"] = collaboratorsVal.map {
        ["email": $0.email, "role": $0.role.rawValue]
      }
    }

    if let linkedRoomsVal = _linkedRooms {
      body["linkedRooms"] = linkedRoomsVal.map {
        ["roomId": $0.roomId, "type": $0.type]
      }
    }

    // Explicitly handle nil music to allow clearing it if needed (optional)
    if let musicValue = _music {
      body["backgroundMusic"] = musicValue
    }

    req.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (_, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }
  }

  func deleteRoom(id: String) async throws {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent(id)
    let req = try await authorizedRequest(to: url, method: "DELETE")

    let (_, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }
  }

  func updateFCMToken(_ token: String) async throws {
    let url = baseURL.appendingPathComponent("me")
    var req = try await authorizedRequest(to: url, method: "PATCH")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(["fcmToken": token])

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg = String(data: data, encoding: .utf8) ?? "Failed to update FCM token"
      print("[ERROR] updateFCMToken: \(msg)")
      throw AppError.backendError(msg)
    }
    print("[DEBUG] FCM token sent to backend successfully")
  }

  // MARK: - SoundCloud Music API

  func getRoomMusic(roomId: String) async throws -> SoundCloudPlaylist {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent(roomId).appendingPathComponent("music")
    let req = try await authorizedRequest(to: url, method: "GET")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(SoundCloudPlaylist.self, from: data)
  }

  func updateRoomMusic(roomId: String, musicUrl: String) async throws {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent(roomId).appendingPathComponent("music")
    var req = try await authorizedRequest(to: url, method: "PATCH")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(["url": musicUrl])

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg = String(data: data, encoding: .utf8) ?? "Failed to update music"
      throw AppError.backendError(msg)
    }
  }

  func addLink(roomId: String, targetRoomId: String) async throws {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent(roomId)
      .appendingPathComponent("links")
    var req = try await authorizedRequest(to: url, method: "POST")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["targetRoomId": targetRoomId]
    req.httpBody = try JSONEncoder().encode(body)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg =
        String(data: data, encoding: .utf8)
        ?? "Status \((resp as? HTTPURLResponse)?.statusCode ?? 500)"
      print("[DEBUG] addLink error: \(msg)")
      throw AppError.backendError(msg)
    }
  }

  func removeLink(roomId: String, targetRoomId: String) async throws {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent(roomId)
      .appendingPathComponent("links").appendingPathComponent(targetRoomId)
    let req = try await authorizedRequest(to: url, method: "DELETE")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg =
        String(data: data, encoding: .utf8)
        ?? "Status \((resp as? HTTPURLResponse)?.statusCode ?? 500)"
      print("[DEBUG] removeLink error: \(msg)")
      throw AppError.backendError(msg)
    }
  }

  // --- Handshake Invites ---

  struct HandshakeInviteRequest: Encodable {
    let inviteeEmail: String
  }
  struct HandshakeInviteResponse: Decodable {
    let passcode: String
  }
  func createHandshakeInvite(roomId: String, inviteeEmail: String) async throws -> String {
    let url = baseURL.appendingPathComponent("rooms")
      .appendingPathComponent(roomId)
      .appendingPathComponent("handshake-invites")
    var req = try await authorizedRequest(to: url, method: "POST")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = HandshakeInviteRequest(inviteeEmail: inviteeEmail)
    req.httpBody = try JSONEncoder().encode(body)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg = String(data: data, encoding: .utf8) ?? "Failed to create invite"
      throw AppError.backendError(msg)
    }

    let response = try decoder.decode(HandshakeInviteResponse.self, from: data)
    return response.passcode
  }

  struct PendingInvitesResponse: Decodable {
    let invites: [HandshakeInviteDTO]
  }
  func getPendingHandshakeInvites() async throws -> [HandshakeInviteDTO] {
    let url = baseURL.appendingPathComponent("me").appendingPathComponent("handshake-invites")
    let req = try await authorizedRequest(to: url, method: "GET")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }

    let res = try decoder.decode(PendingInvitesResponse.self, from: data)
    return res.invites
  }

  struct AcceptInviteRequest: Encodable { let code: String }
  struct AcceptInviteResponse: Decodable { let roomId: String }
  func acceptHandshakeInvite(inviteId: String, passcode: String) async throws -> String {
    let url = baseURL.appendingPathComponent("handshake-invites")
      .appendingPathComponent(inviteId)
      .appendingPathComponent("accept")
    var req = try await authorizedRequest(to: url, method: "POST")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = AcceptInviteRequest(code: passcode)
    req.httpBody = try JSONEncoder().encode(body)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg = String(data: data, encoding: .utf8) ?? "Failed to accept invite"
      throw AppError.backendError(msg)
    }

    let result = try decoder.decode(AcceptInviteResponse.self, from: data)
    return result.roomId
  }

  struct RoomQRCodeResponse: Decodable { let qrCode: String }
  func getRoomQRCode(roomId: String) async throws -> String {
    let url = baseURL.appendingPathComponent("rooms")
      .appendingPathComponent(roomId)
      .appendingPathComponent("qr")
    let req = try await authorizedRequest(to: url, method: "GET")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg = String(data: data, encoding: .utf8) ?? "Failed to fetch QR code"
      throw AppError.backendError(msg)
    }

    let result = try decoder.decode(RoomQRCodeResponse.self, from: data)
    return result.qrCode
  }

  // --- QR Join ---

  struct QRJoinResponse: Decodable {
    let success: Bool
    let roomId: String
    let roomName: String
    let alreadyMember: Bool?
    let message: String?
  }

  func joinRoomViaQR(roomId: String) async throws -> QRJoinResponse {
    let url = baseURL.appendingPathComponent("rooms")
      .appendingPathComponent(roomId)
      .appendingPathComponent("join-via-qr")
    var req = try await authorizedRequest(to: url, method: "POST")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = "{}".data(using: .utf8)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      let msg = String(data: data, encoding: .utf8) ?? "Failed to join room"
      throw AppError.backendError(msg)
    }

    return try decoder.decode(QRJoinResponse.self, from: data)
  }

  // --- Memories ---

  func getMemories(roomId: String) async throws -> [MemoryDTO] {
    let url = baseURL.appendingPathComponent("rooms")
      .appendingPathComponent(roomId)
      .appendingPathComponent("memories")
    let req = try await authorizedRequest(to: url, method: "GET")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }

    return try decoder.decode([MemoryDTO].self, from: data)
  }

  func getTrendingMemories() async throws -> [MemoryDTO] {
    let url = baseURL.appendingPathComponent("memories").appendingPathComponent("trending")
    let req = try await authorizedRequest(to: url, method: "GET")
    let (data, _) = try await session.data(for: req)
    return try decoder.decode([MemoryDTO].self, from: data)
  }

  func getMemoryCount() async throws -> Int {
    let url = baseURL.appendingPathComponent("memories").appendingPathComponent("count")
    let req = try await authorizedRequest(to: url, method: "GET")
    let (data, _) = try await session.data(for: req)
    struct CountResponse: Decodable { let count: Int }
    return try decoder.decode(CountResponse.self, from: data).count
  }

  struct MemoryRequest: Encodable {
    let type: String
    let title: String
    let content: String?
    let contributorEmail: String?
  }

  func getArchivedMemories(roomId: String) async throws -> [MemoryDTO] {
    let url = baseURL.appendingPathComponent("rooms")
      .appendingPathComponent(roomId)
      .appendingPathComponent("memories")
      .appendingPathComponent("archived")
    let req = try await authorizedRequest(to: url, method: "GET")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }

    return try decoder.decode([MemoryDTO].self, from: data)
  }

  func dumpMemories(roomId: String) async throws {
    let url = baseURL.appendingPathComponent("rooms")
      .appendingPathComponent(roomId)
      .appendingPathComponent("dump")
    var req = try await authorizedRequest(to: url, method: "POST")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let (_, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }
  }

  func createMemory(roomId: String, type: String, title: String, content: String?) async throws {
    let url = baseURL.appendingPathComponent("rooms")
      .appendingPathComponent(roomId)
      .appendingPathComponent("memories")
    print("[DEBUG] createMemory: POST to \(url.absoluteString)")

    var req = try await authorizedRequest(to: url, method: "POST")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = MemoryRequest(type: type, title: title, content: content, contributorEmail: AuthService.shared.currentUser?.email)
    let encoder = JSONEncoder()
    req.httpBody = try encoder.encode(body)
    print("[DEBUG] createMemory: Body encoded, size: \(req.httpBody?.count ?? 0)")

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse else {
      print("[DEBUG] createMemory: Not an HTTP response")
      throw URLError(.badServerResponse)
    }

    print("[DEBUG] createMemory: Response status: \(http.statusCode)")
    if !(200..<300 ~= http.statusCode) {
      let msg = String(data: data, encoding: .utf8) ?? "Status \(http.statusCode)"
      print("[DEBUG] createMemory: Server error: \(msg)")
      throw AppError.backendError(msg)
    }
    print("[DEBUG] createMemory: Success")
  }
}

struct MemoryDTO: Codable {
  var _id: String
  var type: String
  var title: String
  var content: String?
  var createdAt: Date
}

final class Database: @unchecked Sendable {
  static let shared = Database()

  // Production URL pointing to Railway backend
  private let baseURL = URL(string: "https://bestbefore.up.railway.app")!
  private lazy var client = BackendAPIClient(baseURL: baseURL)

  private init() {}

  func getAllRooms() async throws -> [RoomObject] {
    let docs = try await self.client.getRooms()
    return docs.map { mapDTOToRoom($0) }
  }

  func getDiscoverableRooms() async throws -> [RoomObject] {
    let docs = try await self.client.getDiscoverableRooms()
    return docs.map { mapDTOToRoom($0) }
  }

  func getRoom(id: String) async throws -> RoomObject {
    let dto = try await self.client.getRoom(id: id)
    return mapDTOToRoom(dto)
  }

  private func mapDTOToRoom(_ dto: RoomDTO) -> RoomObject {
    return RoomObject(
      id: dto._id ?? UUID().uuidString,
      name: dto.name,
      ownerEmail: dto.ownerEmail,
      description: dto.description,
      tags: dto.tags ?? [],
      isPrivate: dto.isPrivate ?? false,
      isTimeCapsule: dto.isTimeCapsule ?? false,
      capsuleDurationDays: dto.capsuleDurationDays ?? 21,
      capsuleDurationHours: dto.capsuleDurationHours ?? 0,
      capsuleDurationMinutes: dto.capsuleDurationMinutes ?? 0,
      unlockDate: dto.unlockDate,
      backgroundMusic: dto.backgroundMusic,
      theme: dto.theme ?? "default",
      expirationDate: dto.expirationDate,
      uploadStartDate: dto.uploadStartDate,
      rollingExpiryDays: dto.rollingExpiryDays ?? 0,
      collaborators: {
        var combined = dto.collaborators ?? []
        if let emails = dto.collaboratorEmails {
          let legacy = emails.map { Collaborator(email: $0, role: .contributor) }
          for c in legacy {
            if !combined.contains(where: { $0.email == c.email }) {
              combined.append(c)
            }
          }
        }
        return combined
      }(),
      linkedRooms: dto.linkedRooms ?? [],
      createdAt: dto.createdAt
    )
  }

  func createRoom(
    name: String, ownerEmail: String? = nil, description: String? = nil, tags: [String] = [],
    isPrivate: Bool = false, isTimeCapsule: Bool = false,
    capsuleDurationDays: Int = 21, capsuleDurationHours: Int = 0, capsuleDurationMinutes: Int = 0,
    unlockDate: Date? = nil,
    backgroundMusic: String? = nil,
    theme: String = "default",
    expirationDate: Date? = nil,
    uploadStartDate: Date? = nil,
    rollingExpiryDays: Int = 0,
    collaborators: [Collaborator] = [],
    linkedRooms: [LinkedRoom] = []
  ) async throws {
    _ = try await self.client.createRoom(
      name: name, ownerEmail: ownerEmail, description: description, tags: tags,
      isPrivate: isPrivate, isTimeCapsule: isTimeCapsule,
      capsuleDurationDays: capsuleDurationDays, capsuleDurationHours: capsuleDurationHours,
      capsuleDurationMinutes: capsuleDurationMinutes,
      unlockDate: unlockDate,
      backgroundMusic: backgroundMusic,
      theme: theme,
      expirationDate: expirationDate,
      uploadStartDate: uploadStartDate,
      rollingExpiryDays: rollingExpiryDays,
      collaborators: collaborators,
      linkedRooms: linkedRooms)
  }

  func deleteRoom(id: String) async throws {
    try await self.client.deleteRoom(id: id)
  }

  func updateRoom(
    id _id: String,
    name _name: String? = nil,
    description _description: String? = nil,
    tags _tags: [String]? = nil,
    isPrivate _isPrivate: Bool? = nil,
    isTimeCapsule _isTimeCapsule: Bool? = nil,
    capsuleDurationDays _days: Int? = nil,
    capsuleDurationHours _hours: Int? = nil,
    capsuleDurationMinutes _mins: Int? = nil,
    unlockDate _unlockDate: Date? = nil,
    backgroundMusic _music: String? = nil,
    theme _theme: String? = nil,
    expirationDate _expirationDate: Date? = nil,
    uploadStartDate _uploadStartDate: Date? = nil,
    rollingExpiryDays _rollingExpiryDays: Int? = nil,
    collaborators _collaborators: [Collaborator]? = nil,
    linkedRooms _linkedRooms: [LinkedRoom]? = nil
  ) async throws {
    try await self.client.updateRoom(
      id: _id,
      name: _name,
      description: _description,
      tags: _tags,
      isPrivate: _isPrivate,
      isTimeCapsule: _isTimeCapsule,
      capsuleDurationDays: _days,
      capsuleDurationHours: _hours,
      capsuleDurationMinutes: _mins,
      unlockDate: _unlockDate,
      backgroundMusic: _music,
      theme: _theme,
      expirationDate: _expirationDate,
      uploadStartDate: _uploadStartDate,
      rollingExpiryDays: _rollingExpiryDays,
      collaborators: _collaborators,
      linkedRooms: _linkedRooms
    )
  }

  func addLink(roomId: String, targetRoomId: String) async throws {
    try await self.client.addLink(roomId: roomId, targetRoomId: targetRoomId)
  }

  func removeLink(roomId: String, targetRoomId: String) async throws {
    try await self.client.removeLink(roomId: roomId, targetRoomId: targetRoomId)
  }

  // --- Handshake Invites ---
  func createHandshakeInvite(roomId: String, inviteeEmail: String) async throws -> String {
    try await self.client.createHandshakeInvite(roomId: roomId, inviteeEmail: inviteeEmail)
  }

  func getPendingHandshakeInvites() async throws -> [HandshakeInviteDTO] {
    try await self.client.getPendingHandshakeInvites()
  }

  func acceptHandshakeInvite(inviteId: String, passcode: String) async throws -> String {
    try await self.client.acceptHandshakeInvite(inviteId: inviteId, passcode: passcode)
  }

  func getRoomQRCode(roomId: String) async throws -> String {
    try await self.client.getRoomQRCode(roomId: roomId)
  }

  func joinRoomViaQR(roomId: String) async throws -> (roomName: String, alreadyMember: Bool) {
    let result = try await self.client.joinRoomViaQR(roomId: roomId)
    return (roomName: result.roomName, alreadyMember: result.alreadyMember ?? false)
  }

  // --- Memory Persistence ---

  func getMemories(for roomId: String) async throws -> [MemoryItem] {
    let dtos = try await self.client.getMemories(roomId: roomId)
    return dtos.map { dto in
      MemoryItem(
        id: dto._id,
        type: MemoryType(rawValue: dto.type) ?? .note,
        title: dto.title,
        date: dto.createdAt,
        content: dto.content,
        isArchived: false  // Defaulted for main vault
      )
    }
  }

  func getArchivedMemories(for roomId: String) async throws -> [MemoryItem] {
    let dtos = try await self.client.getArchivedMemories(roomId: roomId)
    return dtos.map { dto in
      MemoryItem(
        id: dto._id,
        type: MemoryType(rawValue: dto.type) ?? .note,
        title: dto.title,
        date: dto.createdAt,
        content: dto.content,
        isArchived: true
      )
    }
  }

  func dumpMemories(for roomId: String) async throws {
    try await self.client.dumpMemories(roomId: roomId)
  }

  func addMemory(roomId: String, type: MemoryType, title: String, content: String? = nil)
    async throws
  {
    try await self.client.createMemory(
      roomId: roomId, type: type.rawValue, title: title, content: content)
  }

  func getTrendingMemories() async throws -> [MemoryItem] {
    let dtos = try await self.client.getTrendingMemories()
    return dtos.map { dto in
      MemoryItem(
        id: dto._id,
        type: MemoryType(rawValue: dto.type) ?? .note,
        title: dto.title,
        date: dto.createdAt,
        content: dto.content,
        isArchived: false
      )
    }
  }

  func getMemoryCount() async throws -> Int {
    try await self.client.getMemoryCount()
  }

  func updateFCMToken(_ token: String) async throws {
    try await self.client.updateFCMToken(token)
  }

  // MARK: - SoundCloud Music API

  func getRoomMusic(roomId: String) async throws -> SoundCloudPlaylist {
    try await self.client.getRoomMusic(roomId: roomId)
  }

  func updateRoomMusic(roomId: String, musicUrl: String) async throws {
    try await self.client.updateRoomMusic(roomId: roomId, musicUrl: musicUrl)
  }
}
