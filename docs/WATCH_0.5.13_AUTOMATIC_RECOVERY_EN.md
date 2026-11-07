# Android 0.6.10 / Watch 0.5.13: automatic recovery paths

[한국어](WATCH_0.5.13_AUTOMATIC_RECOVERY_KO.md) · **English**

This rollback branch restores preceding code after the reported need to open the watch app on 0.5.13. See [reason and deployment state](ROLLBACK_0.5.12_EN.md). The content below records the previous candidate.

Candidate branch: `fix/watch-background-reconnect`. Android **0.6.10-local / code 26**, Watch **0.5.13 / build 38**. [APK](../artifacts/android/FoldBridge-Local-0.6.10.apk). Registration, encryption keys and vehicle button settings are retained.

## Changes

1. Background `didFailToConnect` recovery submits the next native connection and service scan immediately instead of relying solely on a delayed app timer.
2. Foreground retry delays no longer block recovery after background transition. New background execution opportunities also clear stale app-timer delays.
3. A restored `.connecting` link registers discovery synchronously rather than waiting only for a 20-second app timer. A new execution opportunity also resumes pending service discovery.
4. Completed cancellations release stale transition state. Connection callbacks with the saved identifier adopt the current peripheral object.
5. Successful authentication stops recovery scans and cancels leftover retry work. Healthy links are not periodically cancelled or sent empty heartbeat messages.
6. On the phone, disabling the watch's CCC monitor releases the app transport claim and resumes advertising without cancelling the shared physical LE connection. An interrupted resubscription cannot suppress discovery indefinitely.
7. Build 38 retains a `CLBackgroundActivitySession` for the already-enabled location keepalive mode and recreates it immediately on background relaunch. Previously, location keepalive resumed only in the foreground, leaving it off after process restoration. Restoration uses the existing permission and enabled intent; it does not request new Always location permission. Core Location diagnostics disable the continuous-processing flag when the session is unavailable. [Apple session API](https://developer.apple.com/documentation/corelocation/clbackgroundactivitysession).

The bootstrap/authentication sequence from Android 0.6.9 / Watch 0.5.12 remains. Offline backlogs are not replayed: notification delivery starts from the new authentication cutoff.

## Physical-device observations — November 8, 2026 KST

Bluetooth interruption, range return and initial process restoration were recorded on build 37. Final build 38, with location session restoration, was also installed in place.

| Situation | Recorded outcome | Scope |
| --- | --- | --- |
| Phone Bluetooth off/on | Actual disconnect followed by automatic connection, subscription and authentication; zero refreshes on both apps | Phone in Settings; watch app in background |
| Watch process termination | A new process recorded `launch → restore.2 → authenticated`, without an agent launch command | Process recovery, not a device reboot |
| Actual range departure/return | User moved away with the watch and returned. Watch recorded a connection timeout (`CBError` 6), then automatic connection and authentication; zero refreshes | No watch foreground transition after return |
| Locked watch process termination/restoration (build 38) | New process resumed the location session, restored its saved connection and authenticated with `active=false` throughout; zero watch refreshes and no foreground transition | User left watch locked; remote screen sharing was also stopped |
| Phone refresh while watch locked | User reported successful recovery on 0.5.12 without unlocking the watch | User observation; lock duration not measured |

The range-disconnect event and authentication were approximately 16 seconds apart. This includes time away and is not a measured latency from the instant of physical return. All new-process events were `active=false`. Device identifiers, personal notifications and raw local logs are not published.

## Unresolved drop during locked observation

After successful locked-process restoration and authentication on build 38, a disconnect was recorded approximately 95 seconds later. Two further automatic connections reached subscription but disconnected again while awaiting bootstrap. The phone remained advertising with no selected central. Those watch disconnect callbacks reported no error; app cancellation count was zero and no background-limit warning was recorded. Neither a system budget nor location authorization is established as the cause. **Sustained locked connection and notification delivery remain unresolved.** An empty phone delivery queue alone does not establish successful post-restoration notification receipt.

## Next implementation priorities — November 8, 2026

Implementation work has stopped for now. All items below remain unfinished. The existing source changes and APK are committed on this candidate branch.

1. **Resolve locked-state drops and stalled reconnection.** Find and fix the disconnect after automatic restoration/authentication and the subsequent bootstrap wait. Removing the dependency on opening or refreshing the watch app is the first priority, including recovery initiated only from the phone.
2. **Maintain connection and new-notification delivery during hours of locking/idle time.** A short restoration success does not establish sustained operation. After a drop during prolonged locking, authentication and delivery of newly posted notifications must resume without bringing the watch app to the foreground.
3. **Recover automatically after repeated physical range departure/return.** One range-return observation reached automatic authentication; repeated departures and extended time away remain unfinished. Improve saved-peer reconnection on return without opening or refreshing either app.
4. **Complete automatic recovery after actual device reboots.** After rebooting either device and performing its initial unlock, resume the previously enabled connection service and saved registration without separately opening the app. Process-restoration success is distinct from device-reboot recovery.

Further changes must retain registration, encryption keys and vehicle button settings, and must not replay notifications accumulated while disconnected. Preserve the existing local transport without a server or iPhone; do not use workout or audio sessions.

At the end of this session, phone **Stop connection** was applied and Mac screen sharing, mirroring and diagnostic tools were closed. Pressing **Connect watch** in the next session re-enables the explicitly stopped service; it does not create a new registration.

## Prolonged locking and reboot scope

The same native connection requests, filtered scans and background execution opportunities handle prolonged lock recovery. Elapsed lock time does not itself cancel a healthy link. A short observation is not presented as hours-long or overnight completion.

Android retains existing recovery on `BOOT_COMPLETED`, package replacement, Bluetooth enablement and notification-listener reconnection when the connection service is enabled. Watch recovery uses Core Bluetooth state restoration and system-granted background refresh. Neither device was rebooted during this work.

Before the first unlock after reboot, the protected storage and keys used by this app are unavailable: the watch uses `AfterFirstUnlockThisDeviceOnly`, and Android settings use credential-protected storage. Ordinary relocking after the first unlock is a different state and does not require unlocking for every connection. [Apple key accessibility](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlockthisdeviceonly) · [Android Direct Boot](https://developer.android.com/privacy-and-security/direct-boot).

watchOS imposes background Bluetooth runtime and repeated-reconnection limits. Recovery runs within granted opportunities; the app cannot guarantee immediate execution or remove those limits. [Apple's explanation](https://developer.apple.com/videos/play/wwdc2022/10135/).

Remaining items are **diagnosing and fixing the drop after locked restoration**, **hours-long locked operation/recovery**, and **automatic recovery after an actual device reboot and initial unlock**. Actual range return and locked process restoration succeeded under the recorded conditions. An explicit user force-stop differs from OS process reclamation.

## Use and cleanup

- During normal use, leave the phone service enabled and allow automatic recovery after returning within range. Do not delete registration.
- Phone **Stop connection** explicitly disables the service. Press **Connect watch** once to enable it again.
- At work completion, stop the actual connection and Mac diagnostic sessions while preserving registration.
