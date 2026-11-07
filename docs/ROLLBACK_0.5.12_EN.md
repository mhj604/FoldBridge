# Restore the preceding connection code — Android 0.6.9 / Watch 0.5.12

[한국어](ROLLBACK_0.5.12_KO.md) · **English**

Branch: `fix/watch-background-reconnect`. Restore the Android 0.6.9 / Watch 0.5.12 connection code from `c3f3f53`. Only installation numbers advance to Android **27** and Watch **39**. [Rollback APK](../artifacts/android/FoldBridge-Local-0.6.9-rollback-27.apk).

## Reason and established scope

The user reported needing to open the watch app to connect after installing 0.5.13. App-owned records showed an enabled phone connection service and repeated watch connections/subscriptions, but the watch disconnected while awaiting bootstrap and did not finish authentication. This differs from a discovery failure or a disabled phone service.

The watch recorded zero app cancellations and no counted app failures. The new Android 0.6.10 subscription-release path also had zero executions in that phone process, so it is not established as the direct cause. Whether a 0.5.13 change in reconnection resumption, scan cleanup or location-session restoration directly caused the behavior remains unresolved. Restoring previous code is a mitigation and an isolation step, not a claim of sustained connection being fixed.

## Post-rollback cause analysis — November 8, 2026

The user reported that phone-only connect/refresh still fails while the watch is locked after rollback. Restoring source code does not restore the previously running location keepalive session.

The restored app has these concrete recovery-path defects:

- `LocationKeepAlive.start()` returns unless the app is foreground `.active`. A saved enabled intent therefore does not resume the location keepalive session on background relaunch. Starting the restored app once from the Mac without activating its screen was insufficient preparation for this code path.
- For a restored `.connecting` peripheral, `willRestoreState` schedules discovery in a 20-second app timer. `reconnect()` returns for that same `.connecting` object. This restoration path omits immediate native recovery-scan registration, and a delayed app timer cannot wake a suspended app.
- Opening the app runs recovery discovery and pending authentication resumption through `setActive(true)`, and resumes location keepalive through the SwiftUI foreground handler. App entry therefore combines several recovery operations.

The last saved watch record read on build 39 had `active=false`, `continuousRequested=false`, `recoveryScanning=false`, and a `.connecting` peripheral, with no newer execution events. This is a saved record, not a live process-state measurement. Subsequent events reached subscription/authentication immediately after a foreground transition. The user confirmed direct app-entry or connection-stop interaction, so this interval is not evidence of recovery without interaction.

A separate diagnostic defect can leave a stale phone record reporting a running bridge after the service has stopped. `BridgeService.onDestroy()` changes the in-memory state but does not rewrite its status file. Actual service enumeration was used to distinguish saved state from the running service. No spontaneous phone-service termination is established from this observation.

These findings explain **specific app-entry-dependent paths in the restored code**. The individual change responsible for the initial repeated disconnects on 0.5.13 remains unresolved; prolonged locking and repeated range-return recovery are not declared fixed.

## Data retention and installation

Install over the existing apps with the same application IDs and signing keys. Retain registration, encryption keys and vehicle button settings. Do not uninstall or create a new pairing.

Android rejected installation of the previous code-25 APK over code 26. The previous feature code is therefore rebuilt with installation number 27. The watch uses previous feature code with installation number 39 and display version 0.5.12. Diagnostic build numbers are also 27 and 39.

## Deployment state — November 8, 2026

- Watch 0.5.12 / build 39: installed over the existing app.
- Android 0.6.9-local / code 27: installed over the existing app; installed display version and code match.
- The phone app's post-install state reported its connection service stopped and advertising disabled. Use phone **Connect watch** to enable the service again. This state establishes neither a connection failure nor successful automatic recovery after rollback.
- The restored watch app was started once from the Mac without foreground activation for installation preparation. This is distinct from a system-initiated background relaunch.
- No system logs are collected or included in this change. No actual vehicle commands are executed.

## Still unfinished

1. Finish connection/authentication without opening the watch app, including recovery after another locked-state drop.
2. Maintain connection and new-notification delivery over hours of locking/idle time.
3. Reconnect after repeated physical range departure/return without opening or refreshing either app.
4. Recover the saved connection after actual device reboot and initial unlock without separately opening the app.

Phone **Connect watch** enables an explicitly stopped connection service. **Refresh connection** requests recovery while it is enabled. The button changing to Refresh does not establish successful watch authentication.
