# Watch 0.4.7 / Android 0.5.2 — session-preserving refresh and card spacing

[한국어](RELEASE_WATCH_v0.4.7_KO.md) · **English** · [All guides](README.md)

- Watch **0.4.7 / build 21**
- Android **0.5.2-local / versionCode 13**

## Changes

On a healthy link, **Refresh connection** on either device sends an encrypted update/sync request and keeps the Bluetooth connection/session. The previous phone-side 1.5-second forced cancellation and watch periodic ping/short-response deadlines are removed.

Android apps/system services share the GATT database. Device records showed a Samsung service registration change at the same time as watch service invalidation. An authenticated watch now rebinds characteristics/subscription without dropping its crypto session merely because of that event. Repeated physical disconnects use backoff.

Actual watch process restoration still uses pinned peer identity and fresh nonces rather than restoring old session keys. CCC re-subscription, old ATT completion separation, and MTU recovery were improved. Missing display ACKs remain pending instead of cancelling a healthy BLE link.

Expanded notification text and the small source icon keep their previous positions. Only lower spacing is reduced by **4pt**. Font, line height, and icon size are unchanged. [Layout examples](https://github.com/mhj604/FoldBridge/blob/local-ble/docs/NOTIFICATION_LAYOUT_COMPARISON_EN.md)

## Recorded physical-device observations

Galaxy Z Fold7 and Apple Watch Ultra 2 / watchOS 27.0.1 were updated with the existing signing identities. Optional location keepalive was enabled; the watch was not force-quit.

| Action or record | Result |
| --- | --- |
| User locked the watch and pressed refresh only on the phone | Watch remote-refresh count increased once with `active=false` |
| Watch session before/after | Same process and session generation |
| Phone session before/after | Same generation; zero app-requested link cancellations |
| Watch records about 90 seconds after refresh | Same process/session; no additional recorded disconnect or error |
| After refresh | Both authenticated, zero recorded errors, zero pending items |

Earlier candidate builds reproduced the locked-state failure. This table records the later build 21 result. REA phone logs/status were compared with watch connection-stage records. Private notification content, device identifiers, and raw personal logs are not published.

## Updating and runtime scope

Update with the same Android signing key and watch Bundle ID/team. Registration, filters, and pending items are retained; uninstalling/re-registering is not required for an ordinary update.

A phone refresh does not unconditionally force-launch a watch app. It uses characteristic changes on an available BLE link and the background runtime watchOS permits. Force-quit, the period before first unlock after reboot, Bluetooth off, range, and exhausted runtime/notification budgets can prevent immediate recovery. Open the watch app once if a limit message appears or restoration stalls. [Apple background tasks](https://developer.apple.com/documentation/watchkit/using-background-tasks)

## Korean and English guides

Current setup, FAQ, troubleshooting, build/signing, architecture, protocol, notification appearance, and contribution guides are available in both languages. [Documentation index](https://github.com/mhj604/FoldBridge/blob/local-ble/docs/README.md) · [English overview](https://github.com/mhj604/FoldBridge/blob/local-ble/README.en.md)
