# Watch 0.5.9 / build 33: installation and background restoration

[한국어](WATCH_0.5.9_CANDIDATE_KO.md) · **English**

This branch adds watch background-restoration changes on top of Android 0.6.7. On 2026-11-07, **Watch 0.5.9 / build 33** was installed over the existing app on a physical Apple Watch Ultra 2. Both the installed-app listing and the app's own diagnostics confirmed the build. The phone runs **Android 0.6.7-local / code 23**. Distinguish this branch's installation results from the default branch's Watch 0.5.8 instructions.

## Changes

- Preserve an already active TX characteristic subscription when restoring in background, and authenticate over it. Avoid disabling the last monitoring source merely to re-enable it. Retain explicit resubscription in foreground.
- Allow stalled-authentication and transfer recovery while the OS is actually executing a connection-keepalive callback. Previously the foreground guard returned before those timeouts despite the callback already running.
- Start a new recovery-time window after callback gaps longer than 45 seconds. Time spent suspended must not immediately become an authentication/transfer timeout on resume.
- Record actual application state, whether the in-memory identity is available, and foreground/background transitions. These additions do not record keys or message bodies.

This does not remove watchOS runtime/BLE budgets or arbitrarily launch a suspended app. The foreground requirement for initially starting the location session is unchanged. The observed background restoration below does not establish immediate recovery after every unlock or extended suspension.

See [Reconnection investigation](AUTO_RECONNECT_EN.md) for two observed Android 0.6.7 reconnection cases and remaining conditions. This branch does not execute vehicle commands.

## Physical-device evidence and limits

- After the Android 0.6.7 update, phone records showed automatic authentication without the agent launching the watch app.
- After force-stopping the phone process and explicitly reopening only the phone app, authentication completed with refresh count 0.
- Subsequent records retained session generation 1 and showed 2 notification receipts with no pending items.
- Those three observations used Watch 0.5.8.
- Review identified a possible false timeout after suspension; that handling was revised and rebuilt. A successful build is distinct from passing the physical watch conditions.

### Observations with the installed Watch 0.5.9

- At 06:48:21 UTC after installation, events recorded `restore.2 → subscribe.retained.background → handshake.commit`, then `authenticated` at 06:48:22. Every event had `active=false`: the new retained-subscription path ran on the physical device. A launch command was used once after installation, so this is not evidence of unattended cold-boot launch.
- The agent clicked **Refresh connection** once on the phone screen. At 06:51:50, the watch recorded `remote.refresh` with `active=false`. Phone `refreshCount=1`, watch `remoteRefreshCount=1`, both remained connected, and watch cancellation count stayed 0. This demonstrates request delivery over an existing connection.
- The phone app process was force-stopped and only the phone app was explicitly reopened. After handling the missing service at 06:52:20, the watch authenticated at 06:52:21, with all corresponding events showing `active=false`. Phone refresh count was 0. The agent did not launch the watch app during this sequence. This does not mean Android automatically restarts a force-stopped app.
- Stopping the phone also removes its GATT service: that last sequence recorded one service-discovery failure and one connection cancellation before automatic recovery. It must not be described as having zero errors.
- Device Hub displayed a black physical-watch screen. **Physical lock/unlock, recovery after extended suspension and actual out-of-range/return remain unobserved.** These results do not establish perfect operation under every condition.
- Registration, keys and settings were preserved. No vehicle commands were executed. Raw device records and identifiers are not included in the public repository.
