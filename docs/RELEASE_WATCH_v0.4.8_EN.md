# Watch 0.4.8 / Android 0.5.3 — first-pair queue reset and automatic reconnection

[한국어](RELEASE_WATCH_v0.4.8_KO.md) · **English** · [All guides](README.md)

- Watch **0.4.8 / build 22**
- Android **0.5.3-local / versionCode 14**

## Changes

When a new watch registration succeeds for the first time, Android clears notifications queued before that point. It stores the registration-time cutoff in encrypted storage and applies it again when the service restarts and replays active notifications. Forwarding therefore starts with notifications posted after registration completes. Recovery of an already registered peer keeps its pending queue.

Connections to a saved peer request Core Bluetooth automatic reconnection. When watchOS reports that it owns a reconnect attempt, the watch retains the same peripheral object so app maintenance does not replace the system attempt. After the link returns, it rediscovers GATT and authenticates with fresh nonces. Android retains its existing BLE advertising, retry, and discovery paths.

## Installation

To update in place, keep the Android signing key and application ID, plus the watch Bundle ID and Apple team used by the existing installation. Registration is not required again. New users receive notifications posted after first registration completes.

- [Download Android APK](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.8/FoldBridge-Local-0.5.3.apk)
- [Watch source ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.8/FoldBridge-watch-0.4.8-source.zip)
- [Korean/English guide ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.8/FoldBridge-0.4.8-guides-ko-en.zip)

## Connection scope

The saved connection attempts to recover when the devices return within range. A physical Bluetooth link can still drop because of distance, radio interference, battery or power state, and watchOS may delay recovery while limiting app or Bluetooth activity. This release requests automatic reconnection and retains retry paths; it cannot prevent every disconnect or promise an immediate connection.

For ordinary recovery, press **Refresh connection** once on either device and wait for the status to change. See [troubleshooting](TROUBLESHOOTING_EN.md) and the [BLE restoration flow](PROTOCOL_EN.md).
