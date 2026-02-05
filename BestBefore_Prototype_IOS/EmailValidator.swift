import Foundation

final class EmailValidator {
  static let shared = EmailValidator()
  private init() {}

  // --- CONFIGURATION ---
  // Add allowed domains here (lowercase)
  // Any email ending in these will be allowed.
  private let allowedDomains: [String] = [
    "ug.bilkent.edu.tr",
    "ug.com",
  ]

  // Add specific emails here (whitelist)
  // These are allowed even if they don't match the domains above.
  private let allowedSpecificEmails: Set<String> = [
    "arya.zaeri@gmail.com",
    "test@example.com",
  ]
  // ---------------------

  func isEmailAllowed(_ email: String) -> Bool {
    let lowercasedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()

    // 1. Check Specific Whitelist
    if allowedSpecificEmails.contains(lowercasedEmail) {
      return true
    }

    // 2. Check Domains
    // We look for "@domain" at the end
    for domain in allowedDomains {
      if lowercasedEmail.hasSuffix("@" + domain) {
        return true
      }
    }

    return false
  }
}
