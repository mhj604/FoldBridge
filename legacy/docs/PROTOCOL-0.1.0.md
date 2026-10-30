# FoldBridge v1 protocol

Android is the GATT peripheral. watchOS is the central. The user selects the phone inside the watch app; Android system Bluetooth pairing is not a prerequisite.

## GATT

- Service: `c62d0100-7de5-4c34-a432-7c838e687a40`
- Phone to watch characteristic: `c62d0101-7de5-4c34-a432-7c838e687a40`, notify
- Watch to phone characteristic: `c62d0102-7de5-4c34-a432-7c838e687a40`, write with response
- CCC: standard 0x2902

ATT values contain a big-endian uint32 message identifier, uint16 fragment index, uint16 fragment count and a payload. Value size is bounded by the negotiated ATT size and 200 bytes. Messages are bounded to 16384 bytes and reassembly to 15 seconds. Ordered fragments are required. Every connection resets reassembly and outbound state.

## Authentication

Both devices generate a persistent P-256 ECDH identity. Android keeps its private key in Android Keystore. watchOS stores its private key in the device-only Keychain.

1. Watch generates a fresh 32-byte nonce and sends `commit = SHA256(SPKI_DER_public_key || nonce)` with version 1.
2. Phone commits its own key and fresh nonce before either side reveals.
3. Watch reveals its public key and nonce; phone verifies the commitment and reveals its own.
4. Watch verifies the phone commitment. Both compare any existing pinned public key and reject a change.
5. Both calculate ECDH and HKDF-SHA256 with salt `watch_nonce || phone_nonce`, info `FoldBridge/v1`, length 32.
6. The six-digit comparison value is the first big-endian uint32 of `SHA256(key || UTF8("compare"))` modulo 1000000. The commitment phase prevents choosing a nonce after seeing the peer's revealed nonce.
7. First registration requires matching codes and explicit confirmation on both devices. Confirmation travels inside the encrypted channel. A known, pinned peer is confirmed automatically. No notification is forwarded before both confirmations.

This is an original protocol with focused interoperability checks, not an independently audited security standard. Human comparison still matters on first registration. The first six-digit comparison has approximately a one-in-a-million guessing bound for one independent active attempt; Android bounds repeated failed sessions. Static ECDH identities mean this version does not claim forward secrecy after identity-key compromise.

## Encryption

Messages use AES-256-GCM with AAD `FoldBridge/v1`. Phone nonces are ASCII `FBP1` followed by a uint64 sequence. Watch nonces use `FBW1`. Each connection derives a fresh key from both fresh nonces. Receivers reject repeated or decreasing sequences; authentication failures do not consume a sequence. Android's sealing helper rejects reuse of an outgoing sequence.

Encrypted envelopes are JSON `{type:"sealed", seq:1, data:"base64(ciphertext || tag)"}`. Plaintext encrypted message types are `confirm`, `ready`, `state`, `sync`, `notification`, `ack` and `push_token`.

## Delivery

Notification identities are hashes of Android notification keys. Revisions hash the visible title and body. Source app selection is opt-in. Secret, local-only, ongoing and group-summary notifications are skipped. Body truncation avoids splitting UTF-16 surrogate pairs.

The Android outbox is bounded to 256 current notifications with a two-minute freshness window. It is encrypted at rest; disk writes do not block the initial BLE send. A sudden process termination can still lose an in-progress disk write. Known pending revisions retry at most three times per active link attempt and are retried after a new sync. Queue pressure may drop older unsent transport messages; fresh pending outbox entries remain eligible for retry. OS process restrictions, radio conditions and watchOS runtime budgets can still cause loss.

Queued HTTPS sends recheck both the service cancellation generation and the original notification age before writing. The server rejects timestamps older than two minutes or more than 30 seconds in the future. APNs expiration is the original posting time plus two minutes; retries never extend it. Keep the phone and relay server clocks synchronized.

watchOS peripheral callbacks are bound to the currently selected peripheral and characteristic. Callbacks from a prior phone, superseded scan deadlines, and stale local-notification completions cannot modify a new session.

An ACK means the watch accepted the notification's local scheduling request or already knew that revision. It does not certify screen rendering, vibration or user attention. Notifications have a stable local identifier; recent revisions are remembered to avoid replay. APNs and local notification display are different OS paths, so route switching cannot claim exactly-once display while the app is suspended.

APNs delivery is optional. A paired watch sends its APNs device token through the authenticated link. The Android app calls only a configured HTTPS endpoint with a bearer token. The private server signs APNs HTTP/2 requests with its own P-256 `.p8` key. Alert pushes use priority 10, a two-minute expiration and the notification ID as collapse ID. The relay deduplicates recently accepted revisions and bounds input and retry sizes. Its token authorizes push sending and must remain private.

The BLE path encrypts contents between devices. The APNs path sends the body to the owner's server and Apple for OS-level display. It is not end-to-end encrypted. No Apple account password or APNs provider key is placed on the phone or watch.
