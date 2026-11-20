# WatchBridge

[한국어](README.md) · **English** · [Current versions and remaining work](docs/CURRENT_STATUS_EN.md) · [All guides](docs/README.md)

Forward Galaxy notifications **directly to Apple Watch over Bluetooth LE**. Notification delivery needs no server, internet, iPhone relay, root access, or workout/audio session. Initial watch setup and app installation are separate.

## Install or update — as of 2026-11-20

| Component | Current version / location |
| --- | --- |
| Android | **0.6.23-local / code 45** — [Download APK](https://github.com/mhj604/WatchBridge/releases/download/android-v0.6.23/WatchBridge-0.6.23.apk) |
| Watch app and vehicle widget | **0.5.29 / build 63** — [Xcode project](watch/FoldBridge.xcodeproj); sign for your own team/device |
| New installation | [Step-by-step setup](docs/QUICK_START_EN.md) |
| Existing users | Update in place with the same signing key and watch Bundle ID/team. Preserve registration. |
| Connection problems | [Troubleshooting](docs/TROUBLESHOOTING_EN.md) · [Current status and unfinished scope](docs/CURRENT_STATUS_EN.md) |

The APK belongs to release bundle `android-v0.6.23`. Bundle tags, Android versions and Watch versions are different. Older artifacts remain in [Releases](https://github.com/mhj604/WatchBridge/releases).

```sh
git clone --branch local-ble https://github.com/mhj604/WatchBridge.git
cd WatchBridge
open watch/FoldBridge.xcodeproj
```

Initially use phone **Settings → Pair a new watch** and watch **Connect phone → Find phone**, then compare codes. Later connections use saved registration. Use **Connect watch** when the phone service is off, or **Refresh connection** while it is running. Notifications predating reconnection are not replayed.

Authentication and read delivery were recorded in locked/background conditions, and physical return has produced automatic reconnection. **This does not establish reliable multi-hour lock, repeated range recovery or uninterrupted connections.** Unexpected main-screen display is deferred pending everyday-use observations. [Current priorities](docs/CURRENT_STATUS_EN.md#priorities-and-unfinished-work).

Visible branding is **WatchBridge**. Installation IDs, keychain/storage keys, BLE UUIDs and source paths stay stable to preserve registration and vehicle settings. Source and guides are reflected in `main`, `local-ble`, and `fix/watch-background-reconnect`. `relay/`, `windows/`, and `legacy/` preserve older designs.

## MyHyundai through Galaxy

The current apps use **WatchBridge watch → BLE → Galaxy official MyHyundai widget**. It does not redirect the original MyHyundai watch app. Bind the widget, choose controls on Galaxy, then open **Vehicle controls** in WatchBridge on the watch. A single **Vehicle controls widget** in Smart Stack or on a watch face opens the control panel. Choose Start engine / climate, Lock doors, Turn on hazard lights or Unlock doors inside the panel. Actual vehicle service requires internet and MyHyundai authentication; widget invocation is not vehicle success. **[Setup and scope](docs/VEHICLE_CONTROL_EN.md)**

## Everyday use

- Forward app names, titles, bodies, and available source app icons over an encrypted BLE session. All apps are selected by default; you can choose individual apps.
- Read received notifications in **watchOS Notification Center**. The watch app keeps no separate message history.
- Unacknowledged notifications retry in memory only during the current connection. Disconnection clears this queue; notification payloads are not persisted on the phone.
- Every authenticated connection, including reconnections, starts with notifications posted after that connection completes. Earlier and offline notifications are not replayed.
- Samsung System UI charging updates are excluded by default. Enable charging notifications if you want them.
- **Refresh connection** preserves a healthy link and session while requesting synchronization. If disconnected, recovery uses the saved peer. **Sync now** retrieves pending notifications over an authenticated connection.
- Saved peers use Core Bluetooth's automatic reconnect request plus the app's retry path. If the devices leave Bluetooth range, the watch requests reconnection when the link drops and tries again when they return. Interference, power, and watchOS scheduling can still cause disconnects or delays; immediate recovery is not guaranteed.

### 한국어 / English

Each app has **Settings → Language / 언어 → System default / 한국어 / English**. The devices store their choices independently. System default uses Korean in a Korean environment and English otherwise. Received app names and message contents remain in their original language. Changing language preserves registration and pending notifications.

## What watch notifications look like

The initial system popup, Notification Center cards, and system header identify **WatchBridge** as the sending app. When a source icon is available, the **expanded notification body** shows it at **24pt**, alongside the original app name and message. Without an icon, the system text layout is used.

Source icons are not image attachments, so they do not become oversized media previews. The current build retains the compact expanded-body layout; Watch 0.4.7 kept the text/icon placement from 0.4.6 and reduced only the card's lower spacing by **4pt**. [Layout examples](docs/NOTIFICATION_LAYOUT_COMPARISON_EN.md) · [Display behavior and scope](docs/NOTIFICATION_DISPLAY_LIMITS_EN.md)

Android may redact sensitive notification content before the relay receives it. See [sensitive-content settings](docs/BUILD_AND_SETUP_EN.md#sensitive-notification-content) if you want full content on your own device. The APK does not grant itself this setting.

## Requirements and current scope

| Component | Requirement |
| --- | --- |
| Phone | Android 13+, BLE peripheral/advertising support, Nearby devices and notification access |
| Watch | Build target: watchOS 10+. Current physical-device observations: Ultra 2 / watchOS 27.0.1 |
| Watch installation | Mac with compatible full Xcode, developer mode, development pairing, your Apple signing team |
| Apple account | Free Personal Team supported; it need not match the watch's account |

The current release clears old notifications on every reconnection, restarts phone advertising after disconnect, and retains background recovery requests. Recovery still depends on Bluetooth range and watchOS scheduling. [Current scope](docs/CURRENT_STATUS_EN.md)

watchOS suspension, force-quit, runtime budgets, Bluetooth range, Focus, and notification permission affect delivery. Location keepalive can increase battery use. Development signing may expire and require rebuilding. Replies and bidirectional read/delete synchronization are not implemented. Notification text, private keys, device logs, and location coordinates are not published in this repository; location coordinates are not retained or transmitted by keepalive.


The free account's seven-day signing can be refreshed by a scheduled Mac task. See [automatic renewal and connection requirements](docs/AUTO_RENEW_EN.md).

## Build or contribute

- [Build, signing, and device settings](docs/BUILD_AND_SETUP_EN.md)
- [Architecture](docs/ARCHITECTURE_EN.md) · [BLE protocol](docs/PROTOCOL_EN.md)
- [Changelog](CHANGELOG.en.md) · [Development history](docs/DEVELOPMENT_HISTORY_EN.md)
- [Contributing](CONTRIBUTING.en.md) · [All documentation](docs/README.md)

The Android APK is available in Releases and `artifacts/android/`. To update an existing installation, keep the same Android signing key or the same watch Bundle ID and team. A self-built APK with a different key cannot update the distributed APK in place. [Updating without losing registration](docs/QUICK_START_EN.md#updating)


## Repeated live-status updates

For Wattz (`dubrowgn.wattz`) and bring&T (`com.bring.bringnt`), only the first post of an active Android notification key is forwarded to the watch. Updated numbers or text do not alert again; the watch retains the initial content. Removal of the phone notification allows a subsequent new post to be forwarded once again. Existing indicators are baselined during listener reconnects and are not replayed by refresh. Other apps and the original phone notifications are unchanged.
