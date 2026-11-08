import Foundation
import Security

enum KeychainStore {
    private static let service = "app.mlbbpulse.vpn-password"

    struct KeychainError: LocalizedError {
        let status: OSStatus
        var errorDescription: String? { "Ошибка Keychain (\(status))." }
    }

    static func savePassword(_ password: String, for id: UUID) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: id.uuidString]
        let bytes = Data(password.utf8)
        let update = SecItemUpdate(query as CFDictionary, [kSecValueData as String: bytes] as CFDictionary)
        if update == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = bytes
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let result = SecItemAdd(item as CFDictionary, nil)
            guard result == errSecSuccess else { throw KeychainError(status: result) }
        } else if update != errSecSuccess {
            throw KeychainError(status: update)
        }
    }

    static func passwordReference(for id: UUID) throws -> Data {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: id.uuidString,
                                    kSecReturnPersistentRef as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let reference = result as? Data else {
            throw KeychainError(status: status)
        }
        return reference
    }

    static func deletePassword(for id: UUID) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: id.uuidString]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }
}
