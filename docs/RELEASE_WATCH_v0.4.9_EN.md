# Watch 0.4.9 / Android 0.5.4 — new notifications after connection and automatic recovery

[한국어](RELEASE_WATCH_v0.4.9_KO.md) · **English** · [All guides](README.md)

- Watch **0.4.9 / build 23**
- Android **0.5.4-local / versionCode 15**

## Notification policy

Only notifications posted after **authentication completes for the current connection** are forwarded. This applies to initial registration and every reconnection. Earlier active notifications and notifications posted while offline are not replayed in a burst. Filtering uses Android's original post time, including delayed callbacks.

Unacknowledged items retry in memory only within the current connection and are discarded on disconnect or process restart. Starting the updated service also removes the previous encrypted outbox. The watch drops unscheduled receipts and stale display callbacks from an older connection. Notifications already presented in watchOS Notification Center remain available.

## Connection maintenance and recovery

- Android stops advertising when connected and resumes it on disconnect with the same GATT server. Advertising retries no longer recreate the server and disrupt a healthy link.
- The watch retains OS automatic reconnect requests and service-filtered recovery scanning without a foreground requirement or a 20-second scan expiry.
- Background disconnect callbacks submit a native connection request immediately. A disconnected cached peripheral no longer causes every later reconnect attempt to return early.
- Refresh on a healthy connection retains the link and encrypted session. Registration, language, app filters, source icons, and expanded notification layout remain unchanged.

Radio range, interference, power, and watchOS runtime limits can still interrupt a physical connection or delay recovery. This release removes unnecessary cancellation paths and preserves recovery requests; it cannot promise an uninterrupted or immediate connection.

## Update

Update in place with the existing Android signing key and watch Bundle ID/team. No new code comparison is needed.

- [Android APK](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-Local-0.5.4.apk)
- [Watch source ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-watch-0.4.9-source.zip)
- [Korean/English guide ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-0.4.9-guides-ko-en.zip)
- [Cable-free Galaxy updates](WIRELESS_INSTALL_EN.md)
