import Foundation

/// Only public connection metadata is persisted here. The password lives in Keychain.
struct Server: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var address: String
    var remoteID: String
    var username: String

    init(id: UUID = UUID(), name: String, address: String, remoteID: String, username: String) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.remoteID = remoteID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !name.isEmpty && !address.isEmpty && !remoteID.isEmpty && !username.isEmpty &&
        !address.contains("://") && !address.contains("/") &&
        !address.contains(where: { $0.isWhitespace }) &&
        !remoteID.contains(where: { $0.isWhitespace })
    }
}
