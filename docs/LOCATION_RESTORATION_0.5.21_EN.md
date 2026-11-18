# Watch 0.5.21 — restore the location keep-connection activity

> Historical version-specific investigation/change record. “Current/complete/unresolved” refers to that snapshot, not the latest installation instructions. [Current versions and work status](CURRENT_STATUS_EN.md).

[한국어](LOCATION_RESTORATION_0.5.21_KO.md) · [Documentation](README.md)

2026-11-15: Watch/widget **0.5.21 / build 47**, retaining Android **0.6.15-local / code 33**. Registration, keys and vehicle settings remain. [Android APK](https://github.com/mhj604/WatchBridge/releases/download/connection-v0.5.19/FoldBridge-Local-0.6.15.apk).

## Missing location restoration

Through 0.5.20, location keepalive started `CLLocationManager` only in the foreground. A relaunched process did not immediately restore the saved feature intent. Earlier `continuousRequested=false` records relate to this missing execution path, not erased peer registration.

Use official `CLBackgroundActivitySession` with `CLLocationUpdate.liveUpdates()`. Prepare initially in foreground; rejoin the prior activity immediately on OS relaunch. Retain its object/tasks while enabled, invalidating when the user stops. [Apple rejoining explanation](https://developer.apple.com/videos/play/wwdc2023/10180/) · [Background location handling](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background).

## Conditions

Restore only for an enabled **Keep connection** preference and existing location authorization. Migration requires opening the Watch app once for initial preparation. No peer removal or new pairing is required. Normal reconnection then uses native activity restoration, BLE requests and location execution opportunities rather than requiring foreground launch.

A saved preparation marker is not proof of an active system session. If it no longer exists, background creation cannot force a new active span. `insufficientlyInUse` diagnostics show a preparation message; permission denial and globally disabled location are distinguished. No workout/audio session, server or iPhone relay is added.

Coordinates are not read, stored or sent. Only callback times/counts drive connection maintenance. The default location stream may pause/resume under OS control and battery use can vary. This is not a guarantee of continuous CPU execution.

## Implementation

- Rejoin the saved activity immediately on launch, before deferred setup; do not request undetermined location permission from background.
- Keep initial preparation separate from the feature preference. Stopping/revoking location changes the feature state, preserving peer registration.
- Foreground re-entry rejoins without explicitly invalidating the prior native span. Generation checks discard obsolete Task callbacks.
- Retry transient update-stream termination without clearing the preference. Its delay is not a watchOS wake mechanism.
- Add `locationActivityState`, `locationActivityCallbacks`, `applicationStateName`. `eligible` means Core Location session eligibility, not indefinite runtime or proof of prolonged-lock success. Distinguish `inactive` from `background` explicitly.
- Retain BLE automatic reconnection, fast authentication, notification cutoff, vehicle controls and notification layout.

## Deployment and initial preparation

Build and in-place installation succeeded. The first app record reported build 47, `locationActivityState=needs-foreground-setup`, `applicationStateName=inactive`. The Mac launch command timed out, so the user opened the Watch app once and then returned to the watch face. This task does not claim the app was never opened: this was first-time preparation after installation.

After preparation, native diagnostics reported `locationActivityState=eligible`, 36 location callbacks and an authenticated connection. After the user returned to the watch face, records showed `applicationStateName=background` (`applicationState=2`), `connected=true`, `continuousRequested=true`, and 130 callbacks. App cancellations, errors and discarded fragments remained zero. This demonstrates continuing actual background opportunities, not prolonged passcode lock or physical range departure. Phone `watchActive=true` includes the requested location runtime and does not mean Watch UI is foregrounded. Relaunch restoration was not artificially induced.

No system logs, administrator password, actual vehicle commands or separate prolonged-lock/range QA were used. Initial installation/connection is not proof of complete prolonged-lock or real range-return recovery. Loss of the native activity, force-quit/reboot, permission and OS execution policy remain relevant.

## Follow-up: user-requested passcode-lock observation — connection failed

On November 15, 2026, at 22:03–22:05 KST, the user confirmed the Watch was removed from the wrist and passcode-locked. Only the phone’s **Connect Watch** button was pressed once; the Watch app was not opened or refreshed. This is an additional observation, separate from the preceding unlocked-background result. App versions, code and registration were unchanged.

- Watch: `applicationStateName=background`, `continuousRequested=true`, and `locationActivityState=eligible`. Location callbacks increased from 358 to 425 after locking.
- Phone: the service started, the peer appeared and the subscription was present, but `authenticated=false` and **Authenticating Watch** persisted. Authentication did not complete.
- App-owned Watch events repeatedly showed `handshake.commit`, then `disconnect.ended.0.current.0`, reconnection, discovery and subscription approximately every 2–3 seconds. Between 22:03:34 and 22:05:01, the session generation rose from 53 to 86. The final state remained `connected=false`, `stage=commit`.
- The Watch app explicitly cancelled zero connections and the disconnect callback carried no error. The phone GATT server also recorded zero disconnects. Its peer-presence indicator must not be treated as proof that the Watch app’s Core Bluetooth connection lifetime was uninterrupted. These records do not establish the exact OS reason or prove that locking alone caused the failure.

**Result: the 0.5.21 location activity continued while locked, but phone-only authentication to the locked Watch failed. Prolonged-lock and range-return recovery remain unresolved.** The next repair should address the app-level BLE connection lifetime and repeated authentication resets around these callbacks, rather than merely adding another location session. Do not blindly ignore nil-error disconnects or delete registration.

No system logs, administrator password or vehicle commands were used. The Watch app was not foregrounded to obtain the locked-state result. The phone connection service is stopped for handoff as described below; registration is preserved.

## Handoff

Following the existing handoff preference, phone **Settings → Stop connection** was selected. Records show `bridgeRunning=false`, `centralPresent=false`, `subscribed=false`, `authenticated=false` and stopped status. Registration, keys and vehicle settings are preserved; Mac wireless debugging is closed.

For normal automatic connection, enable phone **Connect watch** once and leave its service enabled. **Stop connection** explicitly disables the service and automatic attempts; it is different from a temporary out-of-range Bluetooth loss. It does not mean opening the Watch app is required on every ordinary reconnection.

Align the existing once-weekly Mac renewal source with committed build 47; renewal is not run now. Watch-only free automatic signing remains separate unfinished work.
