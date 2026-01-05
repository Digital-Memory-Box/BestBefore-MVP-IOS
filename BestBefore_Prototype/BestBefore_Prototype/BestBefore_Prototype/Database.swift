//
//  Database.swift
//  BestBefore_Prototype
//
//  Created by Arya Zaeri on 13.11.2025.
//

import Foundation

// MARK: - RoomObject Codable mirror
// Ensure this matches your existing RoomObject model. If your RoomObject is defined elsewhere as a Realm object,
// create a lightweight Codable struct here to talk to the Data API and convert as needed.
// If RoomObject is already Codable in your project, you can remove this and use that directly.
struct RoomDTO: Codable {
    var _id: String?
    var name: String
    var ownerEmail: String?
    var createdAt: Date
}

// Response structs defined at file scope to avoid nesting
private struct FindResponse<T: Decodable>: Decodable { let documents: [T] }
private struct InsertResponse: Decodable { let insertedId: String }
private struct UpdateResponse: Decodable { let matchedCount: Int; let modifiedCount: Int; let upsertedId: String? }
private struct DeleteResponse: Decodable { let deletedCount: Int }

private final class BackendAPIClient: @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    private func applyAuth(to request: inout URLRequest) {
        if let token = AuthService.shared.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    func getRooms() async throws -> [RoomDTO] {
        let url = baseURL.appendingPathComponent("rooms")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        applyAuth(to: &req)
        print("➡️ GET \(url.absoluteString)")
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse {
            print("⬅️ GET \(http.statusCode) from \(url.absoluteString)")
            if !(200..<300).contains(http.statusCode) {
                print(String(data: data, encoding: .utf8) ?? "<no body>")
            }
        }
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder.mongoDecoder.decode([RoomDTO].self, from: data)
    }

    func createRoom(name: String, ownerEmail: String?) async throws -> String {
        let url = baseURL.appendingPathComponent("rooms")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        applyAuth(to: &req)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any?] = [
            "name": name,
            "ownerEmail": ownerEmail
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })
        print("➡️ POST \(url.absoluteString) body:", String(data: req.httpBody ?? Data(), encoding: .utf8) ?? "<no body>")
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse {
            print("⬅️ POST \(http.statusCode) from \(url.absoluteString)")
            if !(200..<300).contains(http.statusCode) {
                print(String(data: data, encoding: .utf8) ?? "<no body>")
            }
        }
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        struct InsertResponse: Decodable { let id: String }
        return try JSONDecoder().decode(InsertResponse.self, from: data).id
    }

    func updateRoomName(id: String, newName: String) async throws {
        let url = baseURL.appendingPathComponent("rooms/\(id)")
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        applyAuth(to: &req)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["name": newName])
        print("➡️ PATCH \(url.absoluteString) body:", String(data: req.httpBody ?? Data(), encoding: .utf8) ?? "<no body>")
        let (_, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse {
            print("⬅️ PATCH \(http.statusCode) from \(url.absoluteString)")
            if !(200..<300).contains(http.statusCode) {
                print(String(data: Data(), encoding: .utf8) ?? "")
            }
        }
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func deleteRoom(id: String) async throws {
        let url = baseURL.appendingPathComponent("rooms/\(id)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        applyAuth(to: &req)
        print("➡️ DELETE \(url.absoluteString)")
        let (_, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse {
            print("⬅️ DELETE \(http.statusCode) from \(url.absoluteString)")
        }
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}

private extension JSONDecoder {
    static var mongoDecoder: JSONDecoder { let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601; return dec }
}

private enum AppConfig {
    static var backendBaseURL: URL {
        guard let urlString: String = {
            if let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
               let data = try? Data(contentsOf: url),
               let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
               let s = dict["BackendBaseURL"] as? String {
                return s
            }
            return nil
        }() else {
            return URL(string: "http://localhost:3000")!
        }
        return URL(string: urlString) ?? URL(string: "http://localhost:3000")!
    }
}

// MARK: - Public Database facade (Data API–backed)
final class Database: @unchecked Sendable {
    static let shared = Database()

    // Configure these with your backend API URL.
    private let backendBaseURL = AppConfig.backendBaseURL
    private lazy var client = BackendAPIClient(baseURL: backendBaseURL)
    private init() {}

    // MARK: - CRUD Operations (API-compatible signatures)

    /// Fetch all rooms, sorted by creation date (newest first)
    func getAllRooms() async throws -> [RoomObject] {
        let docs: [RoomDTO] = try await self.client.getRooms()
        return docs.compactMap { dto in
            var room = RoomObject()
            room.id = dto._id ?? UUID().uuidString
            room.name = dto.name
            room.ownerEmail = dto.ownerEmail
            room.createdAt = dto.createdAt
            return room
        }
    }

    /// Add a new room
    func addRoom(name: String, ownerEmail: String?) async throws {
        _ = try await self.client.createRoom(name: name, ownerEmail: ownerEmail)
    }

    /// Update an existing room's name
    func updateRoomName(id: ObjectId, newName: String) async throws {
        try await self.client.updateRoomName(id: id, newName: newName)
    }

    /// Delete a room
    func deleteRoom(id: ObjectId) async throws {
        try await self.client.deleteRoom(id: id)
    }
}

// For compatibility with previous signatures
public typealias ObjectId = String
