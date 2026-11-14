# Connection maintenance — Android 0.6.12 / Watch 0.5.16

[한국어](CONNECTION_STABILITY_0.5.16_KO.md) · [Documentation](README.md)

Candidate dated November 14, 2026: Android code 30; Watch and vehicle widget build 42. Watch installation and launch completed. The Android APK built, but has not been installed on the Galaxy because its hotspot ADB connection is unavailable. Registration, keys and vehicle settings are retained.

## Changes

- Remove session resets based solely on adapter-wide GATT snapshots during Android's 15-second maintenance and refresh. Use the actual GATT server disconnect callback.
- A delayed 30-second Android indication or 45-second Watch write no longer cancels the physical link solely on a local timer. Retain the pending ATT operation until completion or an actual disconnect, recording wait counters in app state.
- Retry the same unsent fragment when Android returns BUSY without accepting it. Do not replay accepted vehicle commands on a timer.
- Discard incomplete, expired or out-of-order fragments without tearing down Bluetooth. Authentication and cryptographic checks on complete messages remain in place.
- Retain existing Watch notification subscriptions in the foreground too. Recover transient discovery/channel errors on the same physical link, and restart delayed trusted-peer authentication on that link when possible.

These address identifiable app-induced teardown paths. They do not establish that every observed device disconnect had these causes, or eliminate radio and operating-system disconnects.

## Phone status notification

Show **Watch connected** only when the peer exists and subscription/authentication have completed. Otherwise show a quiet **Waiting for watch connection**, without repeatedly alerting for an unchanged state.

Completely hiding the waiting notification is not implemented. The current persistent BLE architecture uses an Android foreground service, which requires a notification. Stopping it to remove the notification would stop automatic reconnection. [Foreground services](https://developer.android.com/develop/background-work/services/fgs/launch), [background BLE](https://developer.android.com/develop/connectivity/bluetooth/ble/background).

## Deployment and remaining work

- Android and Watch signed builds completed. Watch 0.5.16 was installed in place and launched once.
- Android 0.6.12 is provided as a public candidate APK. Wireless debugging did not expose an address while the Galaxy hosted a hotspot, and the available local ADB ports were closed. Install the APK directly in place, or use a shared Wi-Fi network/USB for remote installation. Do not uninstall first.
- Sustained connection with both new versions, prolonged locking and physical range departure/return remain unobserved. No system logs were collected and no vehicle commands were executed.
- At the end of work, retain registration and use only **Stop connection** in phone settings. If remote control is unavailable, the owner must perform this last step. Disconnecting ADB alone does not stop Galaxy–Watch transport.

## Priority signing goal

Free automatic renewal using only Watch internet, without a Mac, remains unresolved. Additional Exa research did not yield an applicable native watchOS implementation. [SideStore installation](https://docs.sidestore.io/docs/installation/install) targets iPhone/iPad/iPod touch; [iLoader automatic renewal](https://github.com/AndreySemjonov/iloader/blob/main/docs/automatic-renewal.md) explicitly excludes automatic Watch renewal. Apple documents the seven-day free Personal Team provisioning limit. [Apple account overview](https://developer.apple.com/help/account/basics/about-your-developer-account/).

The existing weekly macOS schedule remains a fallback, not Watch-only renewal. Local expiry records and committed scheduler source are aligned with the new Watch installation; registering the schedule does not run renewal immediately. Personal profiles, device identifiers and authentication material stay outside this public repository.
