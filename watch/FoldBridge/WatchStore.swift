import Foundation
import Security
import CryptoKit

enum WatchStore {
    enum StorageError: Error { case keychain(OSStatus) }
    private static func query(_ name: String) -> [String: Any] { [kSecClass as String:kSecClassGenericPassword, kSecAttrService as String:"dev.foldbridge.watch", kSecAttrAccount as String:name] }
    static func get(_ name: String) throws -> Data? {
        var q = query(name); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?; let status = SecItemCopyMatching(q as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw StorageError.keychain(status) }; return item as? Data
    }
    static func put(_ name: String, _ data: Data) throws {
        let status = SecItemUpdate(query(name) as CFDictionary, [kSecValueData as String:data] as CFDictionary)
        if status == errSecItemNotFound {
            var q = query(name); q[kSecValueData as String] = data; q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let result = SecItemAdd(q as CFDictionary, nil); guard result == errSecSuccess else { throw StorageError.keychain(result) }
        } else if status != errSecSuccess { throw StorageError.keychain(status) }
    }
    static func remove(_ name: String) { SecItemDelete(query(name) as CFDictionary) }
    static func identity() throws -> P256.KeyAgreement.PrivateKey {
        if let data = try get("identity") { return try P256.KeyAgreement.PrivateKey(rawRepresentation:data) }
        let key = P256.KeyAgreement.PrivateKey(); try put("identity",key.rawRepresentation); return key
    }
}
