# FoldBridge Local BLE protocol

[한국어](PROTOCOL.md) · **English** · [All guides](README.md)

Current behavior: Android 0.5.4 / Watch 0.4.9. Android is the GATT server/peripheral; watchOS is the central/client. Initial registration happens inside FoldBridge rather than through a separate manual Android Bluetooth-settings step.

## GATT and framing

| Purpose | UUID / transport |
| --- | --- |
| Service | `c62d0200-7de5-4c34-a432-7c838e687a40` |
| Phone → watch | `c62d0201-7de5-4c34-a432-7c838e687a40`, indication |
| Watch → phone | `c62d0202-7de5-4c34-a432-7c838e687a40`, write with response |

The CCC descriptor is `0x2902`; indication enable and notification disable values are handled. The original FoldBridge profile uses the `c62d0100/0101/0102` family.

Each ATT value starts with an 8-byte big-endian header: message ID (`uint32`), fragment index (`uint16`), and fragment count (`uint16`). Fragments fit the negotiated ATT value limit and a 200-byte cap. Maximum assembled message size is 16,384 bytes, with a 120-second assembly timeout. Assembly is ordered and resets with the session.

## Registration and encryption

Each endpoint retains a P-256 ECDH identity key. Android uses Android Keystore and watchOS uses device-local Keychain storage.

1. The watch generates a fresh 32-byte nonce and sends `SHA256(SPKI_DER_public_key || nonce)` as a commit.
2. The phone generates its own fresh nonce and commit.
3. The watch reveals its public key/nonce; the phone checks the commit and reveals its own values.
4. The watch checks the phone commit. Both reject a peer public key that differs from the pinned key.
5. Derive a 32-byte key using ECDH and HKDF-SHA256, salt `watch_nonce || phone_nonce`, info `FoldBridge/v1`.
6. For the comparison code, hash `key || UTF8("compare")`, read the first four bytes as a big-endian uint32, reduce modulo 1,000,000, and display six digits.
7. On first registration, the user compares and confirms on both devices. Saved matching peer keys allow automatic confirmation later.

Messages use AES-256-GCM with AAD `FoldBridge/v1`. Directional nonce prefixes are `FBP1` for phone and `FBW1` for watch, followed by a 64-bit sequence number. Repeated/decreasing sequences are rejected. New authentication always uses fresh nonces; process-lost session keys are not restored.

The encrypted envelope is `{type:"sealed", seq:1, data:"base64(ciphertext || tag)"}`. Current messages include `confirm`, `ready`, `state`, `sync`, `notification`, `ack`, `refresh`, and `refreshed`. Legacy `reconnect`, `ping`, and `pong` are accepted for compatibility. Local does not send APNs tokens or contact a relay.

## Notifications, icons, and acknowledgment

Notification fields include a hashed Android notification ID, content revision hash, app name, title, body, and posted time. Optional fields are `app_id`, `icon_key` (PNG SHA-256 hex), and `icon_png` (base64 PNG). PNG data is limited to 3,072 bytes and decoded dimensions to 64×64; the watch checks its hash and caches it. Icon metadata is not part of the content revision.

Within a session, the phone omits PNG bytes after an icon-bearing notification has been acknowledged. A new session clears that optimization. Text delivery takes priority if the combined message approaches size limits.

The phone retries notifications in memory only during the current authenticated connection, bounded to 24 hours / 1,024 entries with the latest revision per ID. One item waits for an application ACK, with up to three 90-second attempts before deferring it to a live-session wake/sync. Missing app ACKs alone do not cancel BLE. Disconnect and process restart discard the queue. Active-notification replay retains original post times and excludes items predating the current connection.

The watch checks notification authorization, registers a local notification, then ACKs accepted requests. Known revisions are ACKed without being displayed again. An ACK is not a guarantee of sound, visibility, or user reading. The watch stores up to 512 ID/revision hashes, not a separate title/body inbox.

Source-icon notifications use `FOLDBRIDGE_COMPACT_ICON_ALERT` for a compact long-look body with a 24pt icon. Notifications without icons use `FOLDBRIDGE_NATIVE_ALERT`. Neither attaches icons as media. Grouping uses the source app identity. The system sender remains FoldBridge.

## Refresh and restoration

- Every successful authentication, including reconnects, sets a new posted-time cutoff and clears prior pending items. Offline callbacks are ignored and old persisted outboxes are removed. The watch discards unscheduled receipts from the old session while preserving notifications already in Notification Center.
- Connections to a saved peer use watchOS 10+'s `CBConnectPeripheralOptionEnableAutoReconnect`. When Core Bluetooth reports that it is reconnecting, the watch retains that same `CBPeripheral`; after it returns, the watch rediscovers GATT and authenticates with fresh nonces. Android stops advertising when connected and resumes it after disconnect using the same GATT server; advertising retry never tears down a healthy server. This requests automatic recovery, but cannot prevent radio loss or guarantee an immediate reconnect under range, interference, power, or watchOS scheduling constraints.

- Healthy refresh sends encrypted `refresh` while retaining the link/session. Phone replies with `refreshed`; watch replies with `state`/`sync`.
- `ready.liveness` is 0. The app generates no periodic ping and does not treat background wall-clock silence as proof of link failure. Foreground maintenance runs every 15 seconds with foreground recovery grace.
- Process restoration reuses the OS-retained link where possible, explicitly restores CCC subscription, and performs a fresh pinned-key handshake. An authenticated service-change event can instead rebind characteristics without replacing a healthy crypto session.
- Saved-peer pending connects are retained. Recovery scanning stays service-filtered without a foreground-only timeout. Background disconnect callbacks submit native reconnection immediately; repeated foreground failures can back off. A disconnected cached object cannot block all later reconnect attempts.
- If the phone lost its crypto state but retains a subscription, plaintext `wake`/v1 requests fresh authentication only. It does not authorize any notification. Saved-peer authentication waiting does not trigger the previous fixed 120-second link cancellation; first-time registration still has a deadline.
- In-place reauthentication separates old ATT completion callbacks from the new session's packets. Accepted ordinary ATT write lengths also restore a lower bound for the phone MTU.
- Control messages such as state/sync/refresh do not create user notifications. Charging filters run before protocol delivery.

## Scope and older behavior

This protocol does not expand OS runtime budgets or bypass force-quit, first-unlock, Bluetooth, or range conditions. Static identity-key ECDH does not provide a claim of forward secrecy after identity-key compromise. [watchOS background tasks](https://developer.apple.com/documentation/watchkit/using-background-tasks)

Android 0.5.1 / Watch 0.4.6 used forced reconnect requests and periodic ping deadlines; those behaviors were replaced in 0.5.2 / 0.4.7. The Korean document retains that historical section. Initial APNs design notes remain under `legacy/docs/PROTOCOL-0.1.0.md`.

## Vehicle controls (Android 0.6.0 / Watch 0.5.0)

Use only the existing authenticated encrypted channel.

| Message | Direction | Fields |
| --- | --- | --- |
| `vehicle_list` | Watch → phone | `type` |
| `vehicle_catalogue` | Phone → watch | `status`, `revision`, `actions:[{id,label}]` |
| `vehicle_command` | Watch → phone | UUID `id`, `revision`, `action` |
| `vehicle_result` | Phone → watch | Request `id`, `status` |

The catalogue contains at most 12 owner-selected labelled official widget controls. The phone requires an enabled current selection and revision, stores the request ID, then invokes the widget once. The last 64 IDs suppress duplicates. Minimum dispatch spacing is 3 seconds. `widget_invoked` reports widget invocation, not vehicle success. Other results are `duplicate`, `invalid`, `not_ready`, `stale`, `busy`, and `unavailable`. The watch marks an unanswered request unknown after 30 seconds without automatic resend. Reconnection does not restore pending vehicle commands.

### Dismiss a result notice (Android 0.6.1 / Watch 0.5.3)

Catalogue statuses distinguish `loading`, `busy`, `auth_required`, `result_pending` and `no_controls`. The observed previous-request-incomplete notice with a unique OK button yields `result_pending`. An explicit recovery tap sends the existing `vehicle_command` envelope with `action:"dismiss_notice"`, the current revision and a new UUID. The phone invokes only that acknowledgement once and returns `notice_dismissed`; the watch requests a fresh catalogue. This does not dispatch a vehicle command. A subsequent vehicle action requires a separate tap.

### Stable control identifiers (Android 0.6.2 / Watch 0.5.4)

Action IDs are URL-safe Base64 of `SHA256(widgetID + ":label:" + exact displayed label)`. Multiple clickable targets with the same label are excluded. Internal View IDs and screen order are not persistent identities. Dispatch still requires the current revision and a currently selected target.
