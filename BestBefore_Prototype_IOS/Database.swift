import FirebaseAuth
import Foundation

struct RoomDTO: Codable {
  var _id: String?
  var name: String
  var ownerEmail: String?
  var isPrivate: Bool?
  var isTimeCapsule: Bool?
  var capsuleDurationDays: Int?
  var capsuleDurationHours: Int?
  var capsuleDurationMinutes: Int?
  var unlockDate: Date?  // NEW
  var backgroundMusic: String?
  var createdAt: Date
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

  func createRoom(
    name: String, ownerEmail: String?, isPrivate: Bool, isTimeCapsule: Bool,
    capsuleDurationDays: Int, capsuleDurationHours: Int, capsuleDurationMinutes: Int,
    unlockDate: Date?,  // NEW
    backgroundMusic: String?
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

    let body: [String: Any?] = [
      "name": name,
      "ownerEmail": ownerEmail,
      "isPrivate": isPrivate,
      "isTimeCapsule": isTimeCapsule,
      "capsuleDurationDays": capsuleDurationDays,
      "capsuleDurationHours": capsuleDurationHours,
      "capsuleDurationMinutes": capsuleDurationMinutes,
      "unlockDate": unlockDateString,  // NEW
      "backgroundMusic": backgroundMusic,
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
    id: String, name: String?, isPrivate: Bool?, isTimeCapsule: Bool?,
    capsuleDurationDays: Int?, capsuleDurationHours: Int?, capsuleDurationMinutes: Int?,
    unlockDate: Date?,  // NEW
    backgroundMusic: String?
  ) async throws {
    let url = baseURL.appendingPathComponent("rooms").appendingPathComponent(id)
    var req = try await authorizedRequest(to: url, method: "PATCH")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let formatter = ISO8601DateFormatter()

    var body: [String: Any] = [:]
    if let name = name { body["name"] = name }
    if let isPrivate = isPrivate { body["isPrivate"] = isPrivate }
    if let isTimeCapsule = isTimeCapsule { body["isTimeCapsule"] = isTimeCapsule }
    if let capsuleDurationDays = capsuleDurationDays {
      body["capsuleDurationDays"] = capsuleDurationDays
    }
    if let capsuleDurationHours = capsuleDurationHours {
      body["capsuleDurationHours"] = capsuleDurationHours
    }
    if let capsuleDurationMinutes = capsuleDurationMinutes {
      body["capsuleDurationMinutes"] = capsuleDurationMinutes
    }

    if let unlockDate = unlockDate {
      body["unlockDate"] = formatter.string(from: unlockDate)
    }

    // Explicitly handle nil backgroundMusic to allow clearing it
    if let backgroundMusic = backgroundMusic {
      body["backgroundMusic"] = backgroundMusic
    } else {
      body["backgroundMusic"] = NSNull()
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
  }

  func createMemory(roomId: String, type: String, title: String, content: String?) async throws {
    let url = baseURL.appendingPathComponent("rooms")
      .appendingPathComponent(roomId)
      .appendingPathComponent("memories")
    print("[DEBUG] createMemory: POST to \(url.absoluteString)")

    var req = try await authorizedRequest(to: url, method: "POST")
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = MemoryRequest(type: type, title: title, content: content)
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

  // Point to local node server
  private let baseURL = URL(string: "http://localhost:3000")!
  private lazy var client = BackendAPIClient(baseURL: baseURL)

  private init() {}

  func getAllRooms() async throws -> [RoomObject] {
    let docs = try await self.client.getRooms()
    return docs.map { dto in
      RoomObject(
        id: dto._id ?? UUID().uuidString,
        name: dto.name,
        ownerEmail: dto.ownerEmail,
        isPrivate: dto.isPrivate ?? false,
        isTimeCapsule: dto.isTimeCapsule ?? false,
        capsuleDurationDays: dto.capsuleDurationDays ?? 21,
        capsuleDurationHours: dto.capsuleDurationHours ?? 0,
        capsuleDurationMinutes: dto.capsuleDurationMinutes ?? 0,
        unlockDate: dto.unlockDate,  // FIXED
        backgroundMusic: dto.backgroundMusic,
        createdAt: dto.createdAt)
    }
  }

  func getDiscoverableRooms() async throws -> [RoomObject] {
    let docs = try await self.client.getDiscoverableRooms()
    return docs.map { dto in
      RoomObject(
        id: dto._id ?? UUID().uuidString,
        name: dto.name,
        ownerEmail: dto.ownerEmail,
        isPrivate: dto.isPrivate ?? false,
        isTimeCapsule: dto.isTimeCapsule ?? false,
        capsuleDurationDays: dto.capsuleDurationDays ?? 21,
        capsuleDurationHours: dto.capsuleDurationHours ?? 0,
        capsuleDurationMinutes: dto.capsuleDurationMinutes ?? 0,
        unlockDate: dto.unlockDate,  // FIXED
        backgroundMusic: dto.backgroundMusic,
        createdAt: dto.createdAt)
    }
  }

  func createRoom(
    name: String, ownerEmail: String? = nil, isPrivate: Bool = false, isTimeCapsule: Bool = false,
    capsuleDurationDays: Int = 21, capsuleDurationHours: Int = 0, capsuleDurationMinutes: Int = 0,
    unlockDate: Date? = nil,  // NEW
    backgroundMusic: String? = nil
  ) async throws {
    _ = try await self.client.createRoom(
      name: name, ownerEmail: ownerEmail, isPrivate: isPrivate, isTimeCapsule: isTimeCapsule,
      capsuleDurationDays: capsuleDurationDays, capsuleDurationHours: capsuleDurationHours,
      capsuleDurationMinutes: capsuleDurationMinutes,
      unlockDate: unlockDate,
      backgroundMusic: backgroundMusic)
  }

  func deleteRoom(id: String) async throws {
    try await self.client.deleteRoom(id: id)
  }

  func updateRoom(
    id: String, name: String? = nil, isPrivate: Bool? = nil, isTimeCapsule: Bool? = nil,
    capsuleDurationDays: Int? = nil, capsuleDurationHours: Int? = nil,
    capsuleDurationMinutes: Int? = nil,
    unlockDate: Date? = nil,  // NEW
    backgroundMusic: String? = nil
  ) async throws {
    try await self.client.updateRoom(
      id: id, name: name, isPrivate: isPrivate, isTimeCapsule: isTimeCapsule,
      capsuleDurationDays: capsuleDurationDays, capsuleDurationHours: capsuleDurationHours,
      capsuleDurationMinutes: capsuleDurationMinutes,
      unlockDate: unlockDate,
      backgroundMusic: backgroundMusic)
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
        content: dto.content
      )
    }
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
        content: dto.content
      )
    }
  }

  func getMemoryCount() async throws -> Int {
    try await self.client.getMemoryCount()
  }
}
