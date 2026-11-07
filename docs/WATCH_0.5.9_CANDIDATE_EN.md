# Watch 0.5.9 / build 33: pending installation

[한국어](WATCH_0.5.9_CANDIDATE_KO.md) · **English**

This branch adds watch background-restoration changes on top of Android 0.6.7. The build completed, but installation on the physical watch is pending because the Mac–watch developer network tunnel times out. Distinguish this candidate from the default branch and the currently installed Watch 0.5.8.

## Changes

- Preserve an already active TX characteristic subscription when restoring in background, and authenticate over it. Avoid disabling the last monitoring source merely to re-enable it. Retain explicit resubscription in foreground.
- Allow stalled-authentication and transfer recovery while the OS is actually executing a connection-keepalive callback. Previously the foreground guard returned before those timeouts despite the callback already running.
- Start a new recovery-time window after callback gaps longer than 45 seconds. Time spent suspended must not immediately become an authentication/transfer timeout on resume.
- Record actual application state, whether the in-memory identity is available, and foreground/background transitions. These additions do not record keys or message bodies.

This does not remove watchOS runtime/BLE budgets or arbitrarily launch a suspended app. The foreground requirement for initially starting the location session is unchanged. Reliable immediate recovery on unlock has not been established before installing and observing that condition.

See [Reconnection investigation](AUTO_RECONNECT_EN.md) for two observed Android 0.6.7 reconnection cases and remaining conditions. This branch does not execute vehicle commands.

## Physical-device evidence and limits

- After the Android 0.6.7 update, phone records showed automatic authentication without the agent launching the watch app.
- After force-stopping the phone process and explicitly reopening only the phone app, authentication completed with refresh count 0.
- Subsequent records retained session generation 1 and showed 2 notification receipts with no pending items.
- These observations used the installed Watch 0.5.8. **Watch 0.5.9 installation, direct watch-screen observation, physical lock/unlock, extended idle and phone-only refresh comparison remain incomplete.**
- Review identified a possible false timeout after suspension; that handling was revised and rebuilt. A successful build is distinct from passing the physical watch conditions.
