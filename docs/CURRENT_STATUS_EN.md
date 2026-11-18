# Current versions and remaining work

[Watch 0.5.28 locked-callback and range-recovery improvements](RANGE_RECOVERY_0.5.28_EN.md). Phone remains 0.6.20.

[Android 0.6.20 retained-link/delivery-waiting change](CONNECTION_STATE_0.6.20_EN.md) · [Repeated radio recovery during passcode lock](LOCKED_RECOVERY_TEST_2026-11-18_EN.md). Installed Watch is now 0.5.28.

[한국어](CURRENT_STATUS_KO.md) · **English** · [Install and connect](QUICK_START_EN.md) · [All guides](README.md)

As of **2026-11-18 KST**. This page distinguishes current source, the owner's installation records, and published downloads. It does not report another user's installed version. “Current”, “failed”, and “complete” in version-specific investigations describe their historical snapshot.

## Downloads and source

| Component | Version / location |
| --- | --- |
| Android app | **0.6.20-local / code 42** — [WatchBridge-0.6.20.apk](https://github.com/mhj604/WatchBridge/releases/download/android-v0.6.20/WatchBridge-0.6.20.apk) |
| Watch app and vehicle widget | **0.5.28 / build 62** — [local-ble source](https://github.com/mhj604/WatchBridge/tree/local-ble), `watch/FoldBridge.xcodeproj` |
| Source branches | `main`, `local-ble`, and `fix/watch-background-reconnect`. Documentation-only commits may retain the same app version. |
| APK release tag | `android-v0.6.20` names the release bundle. Its Android APK is 0.6.20; it is not Watch 0.5.26. |
| Owner's installed Watch source | `f0983e8` — build 62 installed and launched with no activation requested. Later documentation commits do not alter app behavior. |

Sign the watch source for your own Apple team/device. There is no universal signed watch download. **Update existing installations in place; retain the watch Bundle ID/team and Android signing key.** Visible branding is WatchBridge; `dev.foldbridge.*`, source paths, BLE UUIDs and stored keys remain stable to preserve registration.

## Behavior and observation scope

- Notifications travel directly over Galaxy–Watch BLE, without an iPhone relay or server. Vehicle service separately needs Galaxy internet and official MyHyundai authentication.
- Notifications predating reconnection authentication are not replayed. The watch app has no message inbox.
- Wattz/bring&T revisions of the same notification key do not alert repeatedly. SystemUI battery-protection/charge-limit notices are excluded from forwarding. This does not remove the original phone notifications.
- Read delivery, a display request and phone acknowledgement were recorded during passcode lock in actual background. On November 18, the owner reported automatic reconnection after physical return without the app appearing; lock state for that return was unspecified.
- On November 18, the passcode-locked watch automatically authenticated and resumed delivery after all three Galaxy Bluetooth interruptions of 30, 60 and 90 seconds, without opening the app or refreshing. First responsive samples arrived about 11, 5 and 10 seconds after enable requests. [Controlled conditions and REA evidence](LOCKED_RECOVERY_TEST_2026-11-18_EN.md).
- The following ten-minute observation retained authentication/delivery in all 21 samples, with zero additional native disconnections. Passcode lock was reconfirmed mid-observation. The final watch-file read failed on the Mac development tunnel and is distinguished from phone BLE records.
- All three subsequent physical range-loss/return cycles automatically restored authentication and reads without opening the app or refreshing. Disconnect totals progressed 3 → 4 → 5 → 6; final watch state was authenticated in actual background. [Round results and collection scope](PHYSICAL_RETURN_2026-11-18_EN.md).
- These three successes do not guarantee every environment/future range return or OS process-termination recovery. Additional multi-hour lock testing was excluded from this session at the owner’s request.

## Priorities and unfinished work

| Item | Status / next direction |
| --- | --- |
| Documentation version drift | Current guides use this page; historical records are separate. |
| Connection persistence/recovery | **Physical returns: 3/3 succeeded.** Three controlled radio interruptions and a subsequent ten-minute observation also passed. Investigate any new symptoms using app-owned records while retaining registration. |
| Multi-hour passcode lock | **Added back to remaining work.** Check whether authentication and new-notification delivery persist or automatically recover after several hours/overnight passcode lock, without opening the app or refreshing. This differs from the ten-minute observation; no additional test has been performed yet. |
| Restoration after OS process termination | **To investigate.** If watchOS ends the WatchBridge process, for example because of memory reclamation or an app crash, check whether a subsequent system-granted execution opportunity restores saved-peer connection and delivery without manually opening the app. This differs from screen-off, passcode lock or suspension and is not an established current failure. |
| Free automatic signing renewal | **Active.** A configured weekly Mac task is different from watch-only renewal. A usable free renewal-and-application path using only watch internet has not been established. [Renewal conditions](AUTO_RENEW_EN.md). |
| Unexpected main-screen display | **Deferred at the owner's request.** Continue from app-owned display records after further everyday-use observations. Location activity has not been established as the cause. [Build 60 records](DISPLAY_INVESTIGATION_0.5.26_EN.md). |

**Stop connection** disables the phone service and automatic recovery. Press **Connect watch** to start using it again. **Refresh connection** requests saved-peer recovery while the service is enabled. **Unpair is not ordinary recovery.** Initial location-session preparation after installation is distinct from everyday reconnection.

Use REA and app-owned records for investigation. Do not collect system logs, request administrator passwords, issue vehicle commands or reset registration. Raw device records are not published.

## Reading history

The [changelog](../CHANGELOG.en.md) preserves version history. [0.5.24 read delivery](REA_0.5.24_EN.md), [0.5.25 charging filter](QUIET_BACKGROUND_0.5.25_EN.md), and [0.5.26 display records](DISPLAY_INVESTIGATION_0.5.26_EN.md) describe individual changes; their older APK links are not current installation instructions.
