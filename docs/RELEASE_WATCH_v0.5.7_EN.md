# Current release · Watch 0.5.7 / Android 0.6.3

[한국어](RELEASE_WATCH_v0.5.7_KO.md) · **English** · [All guides](README.md)

## Versions and downloads

- Android: **0.6.3-local / code 19** — [Download APK](https://github.com/mhj604/FoldBridge/raw/refs/heads/local-ble/artifacts/android/FoldBridge-Local-0.6.3.apk)
- Apple Watch: **0.5.7 / build 31** — [Source and Xcode project](https://github.com/mhj604/FoldBridge/tree/local-ble/watch)
- Both `main` and `local-ble` contain the latest source and guides.
- Start with [Install and connect](QUICK_START_EN.md) or [Build and settings](BUILD_AND_SETUP_EN.md). Sign the watch app using your own Apple team.

## Notifications and connectivity

Notifications travel directly over encrypted Bluetooth LE without a server, internet connection or iPhone relay. Initial watch setup and developer installation are separate procedures. Titles, bodies and available original app icons are forwarded. Read them in watchOS Notification Center; there is no separate in-app message inbox. Original icons appear in expanded content; the initial system summary uses the FoldBridge name and icon. [Display scope](NOTIFICATION_DISPLAY_LIMITS_EN.md)

Repeated charging-percentage updates are filtered by default. Registration and reconnection forward new notifications posted after authentication, without replaying an offline backlog.

Saved peer keys are retained. Pending system connections and service-filtered discovery attempt reconnection on return to range. Location-session callbacks can also recover disconnected peers in background. A healthy manual refresh preserves the current session. Keep the Galaxy connection service and Bluetooth enabled. watchOS runtime budgets, force quitting and post-reboot lock conditions still apply. [Troubleshooting](TROUBLESHOOTING_EN.md)

## MyHyundai vehicle controls

The path is `Watch FoldBridge → BLE → Galaxy FoldBridge → official MyHyundai widget`. It does not redirect the original MyHyundai watch app. Actual remote vehicle service requires internet connectivity for Galaxy MyHyundai and the vehicle.

One **Vehicle controls** widget in Smart Stack or on the watch face opens the panel. Its four buttons match the current official Galaxy widget:

| Watch control | Official widget function |
| --- | --- |
| Start engine / climate | 시동/공조 켜기 |
| Lock doors | 문 잠금 |
| Turn on hazard lights | 비상등 켜기 |
| Unlock doors | 문 잠금 해제 |

The unsupported Stop action is removed. Old Stop assignments are never transferred to hazard lights. Unique exact labels preserve assignments across internal widget View ID changes.

### Acknowledgements and timing

1. A control tap automatically acknowledges completion, approval, failure or incomplete-result notices.
2. Once the acknowledgement response and a fresh ready catalogue arrive, the chosen control is submitted once immediately, without a fixed delay.
3. If necessary, the catalogue is requested at **one-second intervals**. Preparation expires **15 seconds** after the original tap and is cancelled on leaving the panel.
4. Vehicle commands have a **three-second minimum interval**. A request within that interval returns busy rather than being queued for later.

Opening the widget alone sends no command. Complete actual login/authentication prompts on Galaxy. Widget invocation is not vehicle success; MyHyundai provides the actual outcome. Lost vehicle-command responses never trigger automatic resend. [Setup and usage](VEHICLE_CONTROL_EN.md)

## Language and signing

The phone and watch independently offer Korean, English and system language settings. Forwarded third-party notification content is not translated.

Free-account signing renewal is separate from vehicle controls. Existing conditions and setup are documented in [Automatic renewal](AUTO_RENEW_EN.md). This release does not change the renewal schedule.

See the [changelog](../CHANGELOG.en.md) for layout, source icons, reconnection, widget, acknowledgement and control-matching changes. Older release notes describe historical behavior; use this guide and the current vehicle guide for everyday operation.
