# Reconnection without buttons: changes and remaining conditions

> Latest installed candidate: [Android 0.6.10 / Watch 0.5.13](WATCH_0.5.13_AUTOMATIC_RECOVERY_EN.md). Actual range return and process restoration succeeded. Earlier candidate descriptions below are historical; use the latest notes for prolonged locking and reboot scope.

[한국어](AUTO_RECONNECT_KO.md) · **English**

See the **[Android 0.6.8 / Watch 0.5.10 record](WATCH_0.5.10_CANDIDATE_EN.md)** for the latest candidate and unfinished work. Next goals are to fully resolve interrupted background authentication, recovery after prolonged locking, and automatic reconnection after physical range loss/return. All remain unfinished.

The goal is reconnection after unlocking the watch, without refreshing either device or opening FoldBridge on the watch. Current versions: Android **0.6.7 / code 23**, Watch **0.5.8 / build 32**.

## Android 0.6.7-local · code 23 (Watch 0.5.8 unchanged)

Android GATT server connection callbacks can include links used by other BLE traffic. Previously the first physical link claimed the watch slot and stopped advertising, allowing an unrelated device to occupy connection waiting. Select the peer only when it subscribes to FoldBridge's own TX CCC descriptor. Existing pinned-key encrypted authentication remains required. Retain MTU values per device until subscription; unrelated connections and disconnections no longer reset the watch session or trigger cancellation of the other device.

While running, the phone service checks the local Bluetooth stack every 15 seconds. Clear a stale app connection and resume advertising when the physical link is gone. This check sends no periodic heartbeat to the watch. Add advertising, observed-link, subscription-claim and local-check fields to diagnostics.

Device records showed authentication without refresh after APK replacement, and again after stopping the phone process and explicitly reopening only the phone app. The agent did not launch FoldBridge on the watch. The Mac–watch developer tunnel remained unavailable, so the watch screen and a physical lock/unlock cycle could not be checked directly. This does not establish reliable automatic recovery after every unlock or extended idle period. [Scope and remaining investigation](AUTO_RECONNECT_EN.md)

## Watch conditions still to distinguish

- Saved-peer connections, service-filtered discovery and Core Bluetooth restoration already exist.
- Starting the optional location keepalive session requires the app to be active. Unlocking the watch and activating the app are different events.
- Some stalled-authentication timeouts run only in foreground. Watch records are needed to determine whether the reported failure stops there.
- watchOS manages background BLE runtime and delivery budgets. [Apple's explanation](https://developer.apple.com/videos/play/wwdc2022/10135/). The specific watchOS 9 count is not assumed to apply unchanged to current OS versions.

Mac–watch developer connectivity is needed for the remaining investigation, independently of ordinary Galaxy–watch BLE use. This work did not execute vehicle commands, reset peer registration or change signature-renewal schedules.
