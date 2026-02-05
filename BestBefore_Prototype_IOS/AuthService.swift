import Combine
import FirebaseAuth
import Foundation

struct AuthUser: Codable {
  let id: String
  let name: String?
  let email: String
  var theme: String?
  var accentColor: String?
  var profileMusic: String?
}

struct AuthResponse: Codable {
  let user: AuthUser
  // let token: String // Token is now managed by FirebaseAuth
}

enum AuthError: Error, LocalizedError {
  case invalidURL
  case server(String)
  case decoding
  case network(Error)
  case badStatus(Int)
  case firebase(Error)
  case notAuthenticated

  var errorDescription: String? {
    switch self {
    case .invalidURL: return "Invalid URL"
    case .server(let msg): return msg
    case .decoding: return "Failed to decode server response"
    case .network(let err): return err.localizedDescription
    case .badStatus(let code): return "Server returned status code: \(code)"
    case .firebase(let err): return err.localizedDescription
    case .notAuthenticated: return "User is not authenticated"
    }
  }
}

final class AuthService {
  static let shared = AuthService()
  private init() {}

  @Published private(set) var currentUser: AuthUser?

  // Note: Token is retrieved dynamically from Auth.auth().currentUser

  private func updateCurrentUser(_ user: AuthUser) {
    self.currentUser = user
  }

  func clearSession() {
    do {
      try Auth.auth().signOut()
      currentUser = nil
    } catch {
      print("Error signing out: \(error)")
    }
  }

  // Adjust URL to your backend
  private let baseURL = URL(string: "http://localhost:3000")!

  // MARK: - Signup
  func signup(name: String?, email: String, password: String) async throws -> AuthUser {
    do {
      // 1. Create User in Firebase
      let result = try await Auth.auth().createUser(withEmail: email, password: password)

      // 2. Update Firebase Profile (DisplayName)
      let changeRequest = result.user.createProfileChangeRequest()
      changeRequest.displayName = name
      try await changeRequest.commitChanges()

      // 3. Send Verification Email
      try await result.user.sendEmailVerification()

      // 4. Sync with Backend to create MongoDB User
      // We need to force refresh token to ensure backend validates it correctly if needed,
      // though usually a fresh sign-in token is valid.
      return try await syncUserWithBackend()

    } catch {
      throw AuthError.firebase(error)
    }
  }

  // MARK: - Login
  func login(email: String, password: String) async throws -> AuthUser {
    do {
      // 1. Sign in with Firebase
      try await Auth.auth().signIn(withEmail: email, password: password)

      // 2. Sync/Fetch Profile from Backend
      return try await syncUserWithBackend()
    } catch {
      throw AuthError.firebase(error)
    }
  }

  // MARK: - Backend Sync / Fetch Profile
  // This calls the backend to ensure the MongoDB user exists and returns the app-specific user profile.
  private func syncUserWithBackend() async throws -> AuthUser {
    guard let firebaseUser = Auth.auth().currentUser else {
      throw AuthError.notAuthenticated
    }

    // Get fresh ID Token
    let token = try await firebaseUser.getIDToken()

    let url = baseURL.appendingPathComponent("auth/sync")
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    // We don't strictly need a body since the token has the info,
    // but we can send one if we want to pass specific fields.
    // For now, empty body.
    req.httpBody = "{}".data(using: .utf8)

    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse else { throw AuthError.decoding }

    if !(200...299).contains(http.statusCode) {
      if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let msg = obj["error"] as? String
      {
        throw AuthError.server(msg)
      }
      throw AuthError.badStatus(http.statusCode)
    }

    // Expecting: { "user": { ... } }
    let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
    updateCurrentUser(decoded.user)
    return decoded.user
  }

  // MARK: - Session Management
  func restoreSession() async {
    guard Auth.auth().currentUser != nil else { return }
    do {
      _ = try await syncUserWithBackend()
      print("[DEBUG] Session restored successfully")
    } catch {
      print("[ERROR] Failed to restore session: \(error)")
    }
  }

  func checkEmailVerification() async throws -> Bool {
    guard let user = Auth.auth().currentUser else { return false }
    try await user.reload()
    return user.isEmailVerified
  }

  // MARK: - Update Profile
  func updateProfile(
    name: String?, theme: String?, accentColor: String?, profileMusic: String?,
    email: String? = nil,
    password: String? = nil
  ) async throws -> AuthUser {
    // 1. If updating email/password, do it in Firebase first
    if let email = email {
      try await Auth.auth().currentUser?.updateEmail(to: email)
    }
    if let password = password {
      try await Auth.auth().currentUser?.updatePassword(to: password)
    }

    // 2. Call Backend PATCH /me
    guard let firebaseUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
    let token = try await firebaseUser.getIDToken()

    let url = baseURL.appendingPathComponent("me")
    var req = URLRequest(url: url)
    req.httpMethod = "PATCH"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    var body: [String: Any?] = [:]
    if let name = name { body["name"] = name }
    if let theme = theme { body["theme"] = theme }
    if let accentColor = accentColor { body["accentColor"] = accentColor }
    if let profileMusic = profileMusic { body["profileMusic"] = profileMusic }

    // We don't send email/pass to backend since backend extracts email from token
    // and doesn't store password anymore. But if we changed email in Firebase,
    // the new token will reflect it.

    req.httpBody = try JSONSerialization.data(
      withJSONObject: body.compactMapValues { $0 }, options: [])

    let (data, resp) = try await URLSession.shared.data(for: req)

    // ... Error handling similar to above ...
    guard let http = resp as? HTTPURLResponse else { throw AuthError.decoding }
    if !(200...299).contains(http.statusCode) {
      if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let msg = obj["error"] as? String
      {
        throw AuthError.server(msg)
      }
      throw AuthError.badStatus(http.statusCode)
    }

    let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
    updateCurrentUser(decoded.user)
    return decoded.user
  }
}
