# Android 0.6.13 / Watch 0.5.17 — less recovery scanning, separate status channels

> Historical version-specific investigation/change record. “Current/complete/unresolved” refers to that snapshot, not the latest installation instructions. [Current versions and work status](CURRENT_STATUS_EN.md).

[한국어](CONNECTION_0.5.17_KO.md) · [Documentation](README.md)

Installed Android **0.6.13-local / code 31** and Watch/widget **0.5.17 / build 43** in place on November 15, 2026. Registration, keys and vehicle settings remain intact. [Download APK](https://github.com/mhj604/WatchBridge/releases/download/connection-v0.5.17/FoldBridge-Local-0.6.13.apk).

## Observed app state

The Galaxy still had 0.6.11 / 29, so the preceding 0.6.12 changes had not reached it. This session installed 0.6.12, then 0.6.13. Watch build 42 app events showed background subscription/authentication starts followed by error-free disconnect/reconnect callbacks about every 2–3 seconds. Explicit app cancellation count was zero. The phone repeatedly restarted authentication without a physical GATT server disconnect. This does not establish a range problem.

Launching the watch app once led to authenticated phone state. This implicates background execution conditions but does not identify every error-free disconnect's cause. No system logs were collected.

## Watch changes

Previously, recovery discovery accompanied the native pending connection to a saved peer. Apple documents that background discovery and BLE alert wakeups share a budget; exceeding it restricts background connections. [Apple BLE explanation](https://developer.apple.com/videos/play/wwdc2022/10135/).

Prefer the saved peer's native pending connection in the background. Do not scan again while waiting for services on an already-connected peer. Keep discovery for stale/missing addresses, but only after a cached connection attempt has lasted 30 seconds and no more than once per 30 minutes per app process. The native connection is requested immediately; the 30 seconds gates only supplementary discovery. Foreground discovery remains available. Add `backgroundRecoveryScans` to app state.

Retain the 0.5.16 reductions in app-induced cancellation. This does not eliminate OS/radio disconnects or guarantee indefinite locked reception. Sustained operation, prolonged locking and physical range-return completion remain open.

## Show phone notifications only when connected

Retain the persistent service and separate its channels:

- **Authenticated connection** (`connection_online`): requires a peer, subscription and completed encrypted authentication.
- **Waiting for connection** (`connection_waiting`): used while awaiting the peer; independently disable it in Android settings.

Disabled only the waiting channel on this Galaxy; app state reported `waitingNotificationHidden=true`. The foreground service, overall app notifications and notification-listener access remain enabled. Android may still list the service in its separate active-apps UI.

Other users can choose **WatchBridge → Settings → Connection notifications → Open settings**, then turn off **Waiting for connection**. Keep the authenticated connection channel enabled. Automatic reconnection and watch notification forwarding remain enabled. Korean/English resources are updated on both platforms.

## Deployment and handoff

Both installations succeeded and the watch app was launched once. Phone app state reported `build=31`, `authenticated=true`, `subscribed=true`, zero queued frames/messages and zero app cancellations. This is an immediate deployment result, not a prolonged stability result. No vehicle commands were executed.

Selected **Settings → Stop connection** on the phone. Subsequent app state reported `bridgeRunning=false`, `centralPresent=false`, `subscribed=false`, `authenticated=false` and stopped status. Registration, keys and vehicle settings were not deleted/reset. Closing Mac diagnostics is distinct from stopping Galaxy–Watch transport.

## Signing priority

Free automatic renewal using Watch internet alone remains unresolved. [Additional research](WATCH_ONLY_RENEWAL_2026-11-15_EN.md) records newer projects and exclusion reasons. The weekly Mac schedule remains only a fallback, aligned with committed source and actual installed profile dates. The earliest profile expiration is **November 20, 2026, 17:10:54 KST**; the existing schedule is Friday 16:00 Mac local time. This build did not extend validity by another seven days.
