# Android 0.6.9 / Watch 0.5.12: background authentication recovery

[한국어](WATCH_0.5.12_BACKGROUND_AUTH_KO.md) · **English**

Candidate on `fix/watch-background-reconnect`: Android 0.6.9-local / code 25 and Watch 0.5.12 / build 36. In-place updates preserve registration, peer keys and vehicle settings. [Candidate APK](../artifacts/android/FoldBridge-Local-0.6.9.apk).

## Observed failure

Watch build 35 repeatedly discovered services, subscribed and sent `handshake.commit` in the background, then received disconnect callbacks. The phone also recorded repeated links and subscriptions. This differs from never discovering the watch. A Bluetooth encryption timeout was recorded once, but was not established as the cause of every disconnect.

The Mac and phone were also on different Wi-Fi subnets, preventing diagnostic access. This was separate from the Galaxy–Watch BLE path. Normal app use does not require the Mac or shared Wi-Fi.

## Changes

- The phone sends a bootstrap indication immediately after answering a saved peer's subscription instead of waiting 750ms. No periodic empty wake messages were added.
- A background watch establishes the monitor before starting authentication from the bootstrap receive callback. A bootstrap racing an existing handshake does not reset its state.
- Background disconnect callbacks submit the next native connection request immediately rather than relying solely on a delayed app timer.
- Phone refresh actually restarts advertising when no subscriber is available. Healthy authenticated links retain the encrypted soft-refresh path without cancellation.
- Bootstrap is a preparation signal, not authentication. Saved peer-key verification and encrypted confirmation remain required before notification or vehicle data transfer.

This changes authentication scheduling; it does not establish that the previous 750ms delay caused every disconnect.

## Physical-device observations — November 8, 2026 KST

Both apps were built and updated in place. The new watch process was initialized once and sent to the watch face. The watch app was not reopened during the following observations.

1. Phone process restart followed by launching only the phone app: service rediscovery, bootstrap and reauthentication completed with watch `active=false` throughout.
2. Phone **Refresh connection**: phone `refreshCount=1`, `softRefreshCount=1`, authentication retained. This covered a healthy link.
3. Phone **Stop connection**, then the user pressed **Connect watch** only on the phone: subscribe → `handshake.await.bootstrap` → `remote.wake` → `handshake.commit` → `authenticated` completed in approximately one second. All events had `active=false`; watch refresh count and recorded errors were zero. Registration was retained.

The third case uses **Connect watch** to re-enable an explicitly stopped service. It does not prove every disconnected physical-link case using **Refresh connection** alone. Android diagnostic `watchActive` includes continuous-processing availability; it does not necessarily mean the watch UI is in the foreground. Watch `active` and lifecycle events establish the UI state.

## Remaining scope

Prolonged locking, OS termination followed by unlock, actual range departure/return, and phone-only refresh after physical-link loss remain open. Short service-restart success is not declared a universal fix. Keep the [existing unfinished goals](WATCH_0.5.10_CANDIDATE_EN.md#unfinished-work-and-next-implementation-goals--2026-11-07).

Apple describes retained Bluetooth connections and background runtime for subscribed characteristic changes, subject to runtime budgets: [official session](https://developer.apple.com/videos/play/wwdc2022/10135/) and [background tasks](https://developer.apple.com/documentation/watchkit/using-background-tasks).

At the end of work, use phone **Stop connection** without deleting registration. Next use requires **Connect watch** once to re-enable the service. Ordinary range loss differs from an explicit stop.
