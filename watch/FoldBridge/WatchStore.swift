import Foundation
import Security
import CryptoKit
import UIKit
import UserNotifications

enum AppIconStore {
    private static let images: NSCache<NSString,UIImage> = { let value = NSCache<NSString,UIImage>(); value.countLimit = 64; return value }()
    private static func url(_ key: String) -> URL? {
        guard key.count == 64, key.allSatisfy({ "0123456789abcdef".contains($0) }),
              let base = FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask).first else { return nil }
        return base.appendingPathComponent("AppIcons",isDirectory:true).appendingPathComponent(key+".png")
    }
    static func accept(key: String?, png: String?) -> String? {
        guard let key, let target = url(key) else { return nil }
        if let png, png.utf8.count <= 4096, let data = Data(base64Encoded:png), data.count <= 3072,
           SHA256.hash(data:data).map({String(format:"%02x",$0)}).joined() == key,
           let image = UIImage(data:data), image.size.width <= 64, image.size.height <= 64 {
            do {
                try FileManager.default.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true)
                try data.write(to:target,options:.atomic); images.setObject(image,forKey:key as NSString)
            } catch { return nil }
        }
        return FileManager.default.fileExists(atPath:target.path) ? key:nil
    }
    static func notificationAttachment(for key: String?) -> (attachment: UNNotificationAttachment, staging: URL)? {
        guard let key, let source = url(key), FileManager.default.fileExists(atPath:source.path) else { return nil }
        // UserNotifications moves attachment files into system storage. Give it a
        // disposable copy so the shared app-icon cache survives subsequent alerts.
        let staging = FileManager.default.temporaryDirectory.appendingPathComponent("FoldBridgeIcon-"+UUID().uuidString,isDirectory:true)
        do {
            try FileManager.default.createDirectory(at:staging,withIntermediateDirectories:true)
            let copy = staging.appendingPathComponent("app-icon.png")
            try FileManager.default.copyItem(at:source,to:copy)
            let attachment = try UNNotificationAttachment(identifier:"source-app-icon",url:copy,options:[UNNotificationAttachmentOptionsTypeHintKey:"public.png"])
            return (attachment,staging)
        } catch {
            try? FileManager.default.removeItem(at:staging)
            return nil
        }
    }
    static func image(for key: String?) -> UIImage? {
        guard let key else { return nil }
        if let image = images.object(forKey:key as NSString) { return image }
        guard let path = url(key), let data = try? Data(contentsOf:path), let image = UIImage(data:data) else { return nil }
        images.setObject(image,forKey:key as NSString); return image
    }
}

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
