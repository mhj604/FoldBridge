# Restore the preceding connection code — Android 0.6.9 / Watch 0.5.12

[한국어](ROLLBACK_0.5.12_KO.md) · **English**

Branch: `fix/watch-background-reconnect`. Restored the original Android **0.6.9-local** / Watch **0.5.12** apps from `c3f3f53`. The watch uses the **original build-36 installation artifact** directly. Android retains the original executable code and resources, advancing only its in-place installation number to **28**. [Original-code APK](../artifacts/android/FoldBridge-Local-0.6.9-original-code-28.apk).

## Reason and established scope

The user reported needing to open the watch app to connect after installing 0.5.13. App-owned records showed an enabled phone connection service and repeated watch connections/subscriptions, but the watch disconnected while awaiting bootstrap and did not finish authentication. This differs from a discovery failure or a disabled phone service.

The watch recorded zero app cancellations and no counted app failures. The new Android 0.6.10 subscription-release path also had zero executions in that phone process, so it is not established as the direct cause. Whether a 0.5.13 change in reconnection resumption, scan cleanup or location-session restoration directly caused the behavior remains unresolved. Restoring previous code is a mitigation and an isolation step, not a claim of sustained connection being fixed.

## Earlier build-39 rollback cause analysis — November 8, 2026

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

Android rejected installation of the original code-25 APK over installed code 27. To retain app data, the APK was rebuilt with the original executable code and resources and Manifest installation number 28 only. Gradle and the direct build tool use that installation number. No Java code, resources or connection behavior were changed. The app-owned diagnostic `build` value intentionally remains 25, distinct from Android package installation number 28.

The original and new APKs have byte-identical `classes.dex`, SHA-256 `0b6a5afd8556c96394b7a54bc5dc649cd18487e8a3e4ec907b6af42e1fce88b1`. Excluding signature files, `AndroidManifest.xml` is the only differing APK entry. The watch uses the preserved original build-36 artifact rather than rebuilt build 39. Repository app code and watch version metadata are restored as well. Installation cannot recreate the exact previous process and OS Bluetooth runtime state.

## Deployment state — November 8, 2026

- Watch 0.5.12 / **original build 36**: installed in place using the original artifact.
- Android 0.6.9-local / **installation code 28**: installed in place with original executable code and resources. Diagnostic build 25 is intentional original-code metadata.
- Saved watch registration and keepalive intent remained present. After unlocking for installation preparation, the original watch app was activated. Both screens showed completed connection/authentication, then the watch was returned to its clock face.
- Background preparation initially showed repeated disconnects after subscription while awaiting bootstrap. Authentication completed after foreground activation. Original-app restoration therefore does not establish full recovery without watch app entry. No additional prolonged-lock, range or reboot tests were performed.
- Per the standing cleanup request, phone **Settings → Stop connection** was selected. Its screen returned to **Connect watch**. Registration, keys and vehicle settings were retained. Use phone **Connect watch** to enable the service next time.
- Mac watch screen sharing and Galaxy mirroring were closed. No system logs were collected or included. No actual vehicle commands were executed.

## Additional original-app comparison — November 8, 2026

The APK actually installed on the phone was retrieved and compared. Its executable code (`classes.dex`) and resources match the original. Only the Manifest installation number and the resulting signature files differ; the signing certificate is unchanged. The installed APK is byte-identical to the original-code restoration APK. Repository Android/watch app source matches `c3f3f53`; only the two Android build files specifying the installation number differ.

A separate, uncommitted Xcode launch-scheme difference remains in the Mac work folder: updated scheme formatting and launch/test/profile metadata. The restored watch app was installed from the preserved original artifact, without rebuilding through that scheme. This user-owned work file is neither modified nor committed. This does not represent a fresh hash comparison of the installed watch executable extracted from the device.

The previous phone-button-only success and the current failed restoration records differ as follows:

| Item | Previous success | Failure after original restoration |
| --- | --- | --- |
| Watch UI state | Background | Background |
| Keepalive request | Enabled | Enabled |
| Recovery scanning state | Enabled | Disabled |
| Phone bootstrap receipt | `remote.wake` recorded | Absent in the compared repeated-failure interval |
| Authentication | `handshake.commit` → `authenticated` | Repeated disconnects at `awaitingBootstrap` |

Phone records show repeated subscription claims and bootstrap-send-path execution. Watch subscription completes, but the link ends before bootstrap reception is recorded. A disabled keepalive toggle or different installed app code therefore does not explain the observations. `bootstrapSent` counts entry into the phone send path, not proof of watch delivery. The scanning-state difference is observational, not an established cause. Why bootstrap is not delivered/processed on the watch, and which component initiates termination, remain unresolved. No complete historical settings snapshot exists, so full settings equivalence is not established either.

This additional comparison did not open the watch app, refresh, unregister or change settings, and used no system logs.

## Still unfinished

1. Finish connection/authentication without opening the watch app, including recovery after another locked-state drop.
2. Maintain connection and new-notification delivery over hours of locking/idle time.
3. Reconnect after repeated physical range departure/return without opening or refreshing either app.
4. Recover the saved connection after actual device reboot and initial unlock without separately opening the app.

Phone **Connect watch** enables an explicitly stopped connection service. **Refresh connection** requests recovery while it is enabled. The button changing to Refresh does not establish successful watch authentication.
