import Foundation
import CryptoKit

enum Wire {
    static let service = "C62D0100-7DE5-4C34-A432-7C838E687A40"
    static let tx = "C62D0101-7DE5-4C34-A432-7C838E687A40"
    static let rx = "C62D0102-7DE5-4C34-A432-7C838E687A40"
    static let info = Data("FoldBridge/v1".utf8)
    enum Failure: Error { case bounds, order, authentication, replay, state }
    static func encode(_ object: [String: Any]) throws -> Data { try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) }
    static func decode(_ data: Data) throws -> [String: Any] {
        guard data.count <= 16384, let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw Failure.bounds }
        return value
    }
    static func base64(_ value: Any?) throws -> Data {
        guard let text = value as? String, let data = Data(base64Encoded: text) else { throw Failure.bounds }; return data
    }
    static func be<T: FixedWidthInteger>(_ value: T) -> Data { withUnsafeBytes(of: value.bigEndian) { Data($0) } }
    static func number(_ bytes: Data) -> UInt64 { bytes.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) } }

    final class Framer {
        private var next: UInt32 = 0
        func split(_ data: Data, maximum: Int) throws -> [Data] {
            guard !data.isEmpty, data.count <= 16384, maximum >= 20 else { throw Failure.bounds }
            next &+= 1
            let length = min(maximum, 200) - 8, count = (data.count + length - 1) / length
            return (0..<count).map { index in
                be(next) + be(UInt16(index)) + be(UInt16(count)) + data.subdata(in: index * length..<min(data.count, (index + 1) * length))
            }
        }
    }
    final class Assembler {
        private var id: UInt64 = 0, count = 0, expected = 0
        private var started = Date.distantPast, bytes = Data()
        var hasPendingMessage: Bool { count > 0 && expected < count }
        func reset() { count = 0; expected = 0; bytes = Data() }
        func accept(_ frame: Data) throws -> Data? {
            guard frame.count >= 9, frame.count <= 200 else { throw Failure.bounds }
            let message = number(frame.prefix(4)), index = Int(number(frame.subdata(in: 4..<6))), total = Int(number(frame.subdata(in: 6..<8)))
            guard total > 0, total <= 1366, index < total else { throw Failure.bounds }
            if index == 0 { reset(); id = message; count = total; started = Date() }
            guard count > 0, message == id, total == count, index == expected, Date().timeIntervalSince(started) <= 120 else { reset(); throw Failure.order }
            bytes.append(frame.dropFirst(8)); expected += 1
            guard bytes.count <= 16384 else { reset(); throw Failure.bounds }
            guard expected == count else { return nil }
            let result = bytes; reset(); return result
        }
    }
    final class Session {
        let key: SymmetricKey
        private var sent: UInt64 = 0, received: UInt64 = 0
        init(shared: SharedSecret, watchNonce: Data, phoneNonce: Data) {
            key = shared.hkdfDerivedSymmetricKey(using: SHA256.self, salt: watchNonce + phoneNonce, sharedInfo: Wire.info, outputByteCount: 32)
        }
        var code: String {
            let raw = key.withUnsafeBytes { Data($0) }
            let digest = Data(SHA256.hash(data: raw + Data("compare".utf8)))
            return String(format: "%06llu", number(digest.prefix(4)) % 1000000)
        }
        func seal(_ object: [String: Any]) throws -> [String: Any] {
            guard sent < UInt64.max else { throw Failure.bounds }; sent += 1
            let nonce = try AES.GCM.Nonce(data: be(UInt32(0x46425731)) + be(sent))
            let box = try AES.GCM.seal(encode(object), using: key, nonce: nonce, authenticating: info)
            return ["type": "sealed", "seq": sent, "data": (box.ciphertext + box.tag).base64EncodedString()]
        }
        func open(_ envelope: [String: Any]) throws -> [String: Any] {
            guard let seq = envelope["seq"] as? NSNumber, seq.int64Value > 0, seq.uint64Value > received else { throw Failure.replay }
            let data = try base64(envelope["data"]); guard data.count >= 16 else { throw Failure.bounds }
            let nonce = try AES.GCM.Nonce(data: be(UInt32(0x46425031)) + be(seq.uint64Value))
            let box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: data.dropLast(16), tag: data.suffix(16))
            let result = try decode(AES.GCM.open(box, using: key, authenticating: info)); received = seq.uint64Value; return result
        }
    }
}
