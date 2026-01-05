import Foundation

#if canImport(RealmSwift)
import RealmSwift

final class RoomObject: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String
    @Persisted var ownerEmail: String?
    @Persisted var createdAt: Date

    convenience init(name: String, ownerEmail: String?) {
        self.init()
        self.name = name
        self.ownerEmail = ownerEmail
        self.createdAt = Date()
    }
}
#else
// Fallback so the project can compile without RealmSwift installed.
// This is a lightweight placeholder and does NOT persist data.
struct RoomObject: Identifiable, Hashable {
    // Using UUID instead of ObjectId when RealmSwift is unavailable
    var id: UUID = UUID()
    var name: String
    var ownerEmail: String?
    var createdAt: Date = Date()

    init(name: String, ownerEmail: String?) {
        self.name = name
        self.ownerEmail = ownerEmail
    }
}
#endif
