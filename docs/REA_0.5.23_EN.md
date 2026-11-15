# WatchBridge 0.5.23 — REA investigation and rename

[한국어](REA_0.5.23_KO.md) · [Documentation](README.md)

2026-11-15. Candidate: Android **0.6.17-local / code 39**, Watch/widget **0.5.23 / build 55**. **Repeated disconnections remain unresolved; this is not a stable release.**

## Branding and compatibility

Visible app, widget, notification-listener, connection notification, navigation and settings branding is WatchBridge in Korean and English. The repository is [mhj604/WatchBridge](https://github.com/mhj604/WatchBridge).

In-place updates retain registration. Android `dev.foldbridge.local`, Watch `dev.foldbridge.watch`, widget identifiers, keychain/preferences keys, BLE UUIDs, cryptographic contexts and widget kind remain unchanged. Existing source/build paths such as `watch/FoldBridge.xcodeproj` and historical release filenames remain for compatibility. They do not determine the visible app name. Git history, tags and old binaries are not rewritten.

## Incorrect status copy

The old Android `renderState()` used “Open FoldBridge on your watch” as its fallback for every disconnected state, including an explicitly stopped service, initial registration and automatic recovery. The UI now distinguishes stopped service, initial setup, saved-key authentication, automatic recovery, connected state and notification-listener availability. Refresh reports a request, rather than claiming success.

The watch publishes connected only after receiving `ready` and completing the notification subscription, rather than exposing authentication alone as complete connectivity. Copy no longer implies that a reconnection will replay all earlier notifications. Real location permission/setup conditions and an actual watchOS Bluetooth-budget exhaustion warning remain conditional instructions.

## REA acquisition

The installed [REA](https://github.com/morluto/rea) CLI was used because no REA MCP tools were exposed. REA ADB operations acquired Android device/package data and app-owned state, and installed replacement APKs. REA has no direct watchOS runtime provider here; `capture-process` recorded Apple `devicectl` app-file acquisition and installation. This is not presented as a REA watch-screen-control feature.

Only app-owned `foldbridge-status.json` and `foldbridge-events.json` metadata were used. No system logs, administrator passwords, message contents or real vehicle commands were collected or executed. Full Evidence remains private on the owner's Mac because it contains device identifiers and local paths. Representative Evidence IDs are listed in the [Korean report](REA_0.5.23_KO.md#rea-사용-범위).

## Observations and changes

Build 53 repeatedly authenticated and subscribed in the background, then received a native nil-error disconnection about four seconds later. Some subsequent connections ended during authentication. App cancellation count was zero and location activity was `eligible`. Successful locked authentication therefore did not establish sustained connectivity.

The source started another background scan even while a native saved-device connection was pending. Build 54 suppresses this redundant scan and leaves the pending reconnection with Core Bluetooth. Apple documents a shared finite budget for background scans and Bluetooth alert execution. [Apple background-task documentation](https://developer.apple.com/documentation/watchkit/using-background-tasks).

After that change, build 54 reported zero background scans and 48 suppressed redundant scans, but still had 43 authentication attempts and 22 completions. After one-time preparation it also disconnected in actual `background` state with eligible location activity. One captured failure was `CBErrorDomain:6` timeout: approximately 18.5 seconds after connection, 7.2 seconds after subscription, with two pending writes, zero background tasks and zero app cancellations. Background-task completion/expiration counters were zero. This shows the redundant scan was not the sole cause and that this captured failure was not an app prematurely completing its background task. It does not prove an exhausted OS budget or a particular system bug.

Build 55 separates authentication from publicly connected state and removes automatic vehicle-catalogue, state and sync traffic on idle background reconnection. Vehicle views/widget flows still request a fresh catalogue when used. Notification receipt/acknowledgement, peer authentication and stored registration remain. This change is not described as a confirmed cure for native disconnections.

## Remaining conditions

- Narrow the conditions causing native termination after authentication/subscription and repeated reauthentication.
- Sustained delivery through prolonged passcode lock is not marked complete.
- Physical out-of-range departure/return without opening the watch app or refreshing is a separate field condition; nearby authentication cannot substitute for it.
- Mac development-tunnel timeouts are a different connection. An Evidence capture succeeding does not mean its captured device command succeeded; inspect the inner command exit and file timestamps.

For regular automatic recovery the phone service must remain enabled. At the end of work on the owner's devices, use **Settings → Stop connection**, preserving registration, then close Mac debugging. Use **Connect watch** to enable it again.

## Reusing the acquisition workflow

With REA and Android Platform-Tools available, substitute your own device ID and private output path:

```sh
rea list-adb-devices --format json
rea inspect-adb-package DEVICE dev.foldbridge.local --format json
rea pull-adb-file DEVICE /sdcard/Android/data/dev.foldbridge.local/files/foldbridge-status.json --output-directory ./private-evidence --format json
```

For watch data, a REA `capture-process` scenario can run `xcrun devicectl device copy from --device DEVICE --domain-type appDataContainer --domain-identifier dev.foldbridge.watch --source Documents/foldbridge-status.json --destination OUTPUT --timeout 25`. Retain full Evidence, file hashes, the captured command's exit status and the timestamp inside each file privately. Do not commit raw device records.
