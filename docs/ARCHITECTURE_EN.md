# FoldBridge Local architecture

[한국어](ARCHITECTURE.md) · **English** · [All guides](README.md)

This describes the current Android 0.5.3 / Watch 0.4.8 implementation. The Korean document also preserves older implementation notes; [English milestones](DEVELOPMENT_HISTORY_EN.md) summarize that history.

## Delivery path

On the first successful watch registration, Android clears the older pending outbox and stores an encrypted registration-time cutoff. After process restart, active-notification replay drops items posted before that cutoff. Recovery of an already registered peer retains the pending queue.

Connections to a saved phone use watchOS 10+'s Core Bluetooth automatic reconnect option. While the OS is reconnecting, the watch retains its `CBPeripheral` so app maintenance does not replace the system-managed attempt. Android keeps its GATT server advertising; existing retry and scan recovery remains the fallback. Radio range, interference, power, and watchOS runtime limits can still interrupt or delay reconnection.

```text
Other Android apps
       ↓ notification access
NotificationRelay → filters → encrypted pending outbox
       ↓ BridgeService: BLE GATT server/peripheral
       ⇄ framed, encrypted BLE messages
WatchLink: BLE central/client
       ↓ local notification request
watchOS Notification Center
       ↓ acknowledgment to phone
Remove acknowledged revision from pending outbox
```

The phone extracts the source app name/icon, title/body, hashed notification ID, and content revision. The watch reassembles/decrypts the message and requests a local notification. An ACK means that display registration was accepted or the revision was already known; it is not a read receipt. Both endpoints pin peer keys during the initial code comparison and derive fresh session keys for new authentication.

## Phone lifecycle

`BridgeService` runs as a `connectedDevice` foreground service. Nearby devices, the app's own notification permission, and access to other apps' notifications are separate permissions.

When connection is enabled, supported boot-after-unlock, package-update, Bluetooth-on, and listener-reconnection events resume the service. An existing service is reused. Server/service/advertising initialization failures retry with increasing delay up to 30 seconds. Bluetooth-off pauses retry; explicit **Stop connection** disables automatic start. Android restrictions and force-stop still apply.

## Watch lifecycle and refresh

Core Bluetooth retains the saved peripheral connection when the OS permits. A characteristic change can provide background runtime. The watch handles Bluetooth-alert/background-refresh tasks and completes them when transfer/display work is idle or the task expires.

Healthy manual refresh sends encrypted `refresh` without replacing the link or session. The phone replies with `refreshed`; the watch replies with state/synchronization. There is no generated periodic ping and no short disconnect deadline based only on time spent suspended.

If an Android system service changes the shared GATT database, an authenticated watch re-discovers characteristics/subscription while retaining its crypto session. Actual watch process restoration uses saved peer identity and fresh nonces, with explicit CCC re-subscription. Previous ATT completion callbacks cannot consume the first packet of a replacement session.

Pending connections remain with Core Bluetooth when possible. Missing-cache/foreground-stall discovery and repeated-disconnect backoff support recovery. A requested background refresh after 30 minutes is an opportunity, not a guaranteed schedule. [Protocol details](PROTOCOL_EN.md)

## Optional location keepalive

The user can explicitly request background location updates. The app records only callback time; it does not inspect, store, or transmit coordinates. Location callbacks may perform connection maintenance. The current maintenance timer runs every 15 seconds **only in the foreground**; it cannot wake the app. A location-session request is not proof that watchOS is continuously scheduling the app.

Location keepalive can increase battery consumption. No workout/audio session, root access, or APNs wake path is used in Local. Suspension, termination, runtime budgets, and Bluetooth range remain relevant. [Apple background tasks](https://developer.apple.com/documentation/watchkit/using-background-tasks)

## Filters and local storage

- All apps are selected by default, with an optional app selection list.
- The app's own connection notification is excluded. Samsung System UI charging-state updates are excluded by default and can be enabled separately.
- The phone encrypts undelivered items for at most 24 hours / 1,024 entries. A newer revision replaces the same ID; the oldest item is removed when capacity is exceeded.
- The watch stores no separate message inbox. It retains up to 512 ID/revision hashes for duplicate suppression in Keychain. Notification content is managed by watchOS Notification Center.
- Android identity/storage keys use Android Keystore. Watch identity and peer keys use device-local Keychain storage.
- Diagnostic files contain connection/permission state, counters, and bounded stage/error records; notification bodies, private keys, and coordinates are excluded.

The original and Local watch profiles have separate saved phone identities. Stop the older Android app's connection when using Local. Bidirectional read/delete synchronization and replies are not implemented.

## Source icons and notification layout

`AppIcons` extracts source app artwork using Android PackageManager and produces a bounded PNG, starting at 48px and reducing as needed. The PNG is limited to 3,072 bytes, identified by SHA-256, encrypted alongside notification data, and cached on the watch. Once an icon-bearing message is acknowledged during a session, later messages can send only its key.

The system owns the popup, cards, and header showing FoldBridge. Only the expanded body with an available source icon uses the compact SwiftUI layout. It has a 24pt overlay icon, a 16pt base font, zero extra paragraph spacing, and adjusted body line height on watchOS 26+. Watch 0.4.7 trims the lower spacing by 4pt on watchOS 27+ while retaining 0.4.6 text/icon placement. No media attachments or nested scroll views are used. [Presentation scope](NOTIFICATION_DISPLAY_LIMITS_EN.md) · [Layout examples](NOTIFICATION_LAYOUT_COMPARISON_EN.md)

## Source map

| Path | Responsibility |
| --- | --- |
| `android/app/src/main/java/dev/foldbridge/` | Listener, filters, GATT server, crypto, outbox, Android UI |
| `watch/FoldBridge/` | GATT client, identity/session, local notifications, keepalive, SwiftUI |
| `localization/en.json` | Shared English translations keyed by Korean strings |
| `tools/` | Translation and icon generation |
| `watch/generate_project.py` | Xcode project and Info.plist generation |
| `relay/`, `windows/`, `legacy/` | Archived earlier designs, outside Local runtime |

The current Local Android manifest has no `INTERNET` permission. Initial Apple Watch setup/development installation is separate from this offline notification-delivery path.
