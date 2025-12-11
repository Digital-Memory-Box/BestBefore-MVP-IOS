import Foundation

struct AuthUser: Codable {
    let id: String
    let name: String?
    let email: String
}

struct AuthResponse: Codable {
    let user: AuthUser
    let token: String
}

enum AuthError: Error, LocalizedError {
    case invalidURL
    case server(String)
    case decoding
    case network(Error)
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .server(let msg): return msg
        case .decoding: return "Failed to decode server response"
        case .network(let err): return err.localizedDescription
        case .badStatus(let code): return "Server returned status code: \(code)"
        }
    }
}

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private(set) var currentUser: AuthUser?
    private(set) var currentToken: String?

    private func updateSession(user: AuthUser, token: String) {
        currentUser = user
        currentToken = token
    }

    func clearSession() {
        currentUser = nil
        currentToken = nil
    }

    private let baseURL = URL(string: "http://localhost:3000")!

    func signup(name: String?, email: String, password: String) async throws -> (AuthUser, String) {
        let url = baseURL.appendingPathComponent("signup")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any?] = [
            "name": name,
            "email": email,
            "password": password
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 }, options: [])

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw AuthError.decoding }
            if !(200...299).contains(http.statusCode) {
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let msg = obj["error"] as? String {
                    throw AuthError.server(msg)
                }
                throw AuthError.badStatus(http.statusCode)
            }
            let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
            updateSession(user: decoded.user, token: decoded.token)
            return (decoded.user, decoded.token)
        } catch let err as AuthError {
            throw err
        } catch {
            throw AuthError.network(error)
        }
    }

    func login(email: String, password: String) async throws -> (AuthUser, String) {
        let url = baseURL.appendingPathComponent("login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw AuthError.decoding }
            if !(200...299).contains(http.statusCode) {
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let msg = obj["error"] as? String {
                    throw AuthError.server(msg)
                }
                throw AuthError.badStatus(http.statusCode)
            }
            let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
            updateSession(user: decoded.user, token: decoded.token)
            return (decoded.user, decoded.token)
        } catch let err as AuthError {
            throw err
        } catch {
            throw AuthError.network(error)
        }
    }
}
