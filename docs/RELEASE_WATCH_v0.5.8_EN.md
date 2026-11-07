# Watch 0.5.8 · build 32 / Android 0.6.7

[한국어](RELEASE_WATCH_v0.5.8_KO.md) · **English** · [Full usage guide](RELEASE_WATCH_v0.5.7_EN.md)

## Background connection investigation

Opening the app is not a required step in the ordinary reconnect path. The app submits a connection to the saved peer and uses OS auto-reconnect, service-filtered discovery and state restoration. watchOS controls background runtime and BLE delivery opportunities, so immediate reconnection is not guaranteed.

Device logs on 2026-11-06 showed both successful background connections and rapid disconnect/reconnect cycles. Galaxy reported that the remote device terminated the link, but the previous watch diagnostics could not distinguish app cancellation from system behavior. A disconnect without an error does not establish that the user manually disconnected.

This version improves diagnostics. **It does not claim a confirmed cause or permanent reconnection fix.** Logs read after installation showed successful background authentication; an immediate post-update result does not establish long-term reliability.

## Added records

- App cancellation count and reason: `cancellationCount`, `lastCancellation`
- Disconnect error domain, code and description: `lastDisconnect`
- Whether connection/disconnection callbacks refer to the current peripheral object
- Separate `cancel.*` app requests from ordinary `disconnect.ended.*` events

The watch app stores diagnostics in `Documents/foldbridge-status.json` and `Documents/foldbridge-events.json`. Events are capped at 128. These additions do not record message bodies or vehicle credentials. Diagnostics do not execute vehicle commands.

The watch diagnostic update originally used Android 0.6.4. Subsequent Android changes are listed below by version. Notification layout, vehicle controls, peer keys and control mappings are outside this change. [Build and install](BUILD_AND_SETUP_EN.md)

Apple explains background link retention, reconnection on return to range and runtime limits in [Get timely alerts from Bluetooth devices on watchOS](https://developer.apple.com/videos/play/wwdc2022/10135/). The specific watchOS 9 limit described in that presentation is not assumed to be a fixed limit on current OS versions.

## Android 0.6.5-local · code 21 (Watch 0.5.8 unchanged)

Forward Samsung System UI charging alerts (`charging_state` / `CHR`) and System UI notifications marked `ONLY_ALERT_ONCE` only once per active Android notification key. Even with charging alerts enabled, changes to battery percentage or time remaining do not alert the watch again. Charging alerts remain excluded when their setting is off. Existing indicators are baselined rather than replayed on listener reconnect or refresh. Removal followed by a new post can alert once again. Update the setting description in Korean and English; retain the existing Wattz/bring&T first-post policy.


## Android 0.6.6-local · code 22 (Watch 0.5.8 unchanged)

Galaxy records showed a real bring&T device-response notification with a title, plus an Android-generated `GROUP_SUMMARY` / `AUTOGROUP_SUMMARY` shell without title or body. Forwarding that empty shell caused FoldBridge's empty-notification fallback.

Exclude textless group summaries from initial collection, active-notification replay and forwarding, before recording first-post state. Summaries with text, text lines, custom layouts or action buttons, and individual notifications, are not excluded by this filter. Keep the existing bring&T numeric-update and charging-alert policies. Previously delivered watch Notification Center entries are not removed by the update.


## Android 0.6.7-local · code 23 (Watch 0.5.8 unchanged)

Android GATT server connection callbacks can include links used by other BLE traffic. Previously the first physical link claimed the watch slot and stopped advertising, allowing an unrelated device to occupy connection waiting. Select the peer only when it subscribes to FoldBridge's own TX CCC descriptor. Existing pinned-key encrypted authentication remains required. Retain MTU values per device until subscription; unrelated connections and disconnections no longer reset the watch session or trigger cancellation of the other device.

While running, the phone service checks the local Bluetooth stack every 15 seconds. Clear a stale app connection and resume advertising when the physical link is gone. This check sends no periodic heartbeat to the watch. Add advertising, observed-link, subscription-claim and local-check fields to diagnostics.

Device records showed authentication without refresh after APK replacement, and again after stopping the phone process and explicitly reopening only the phone app. The agent did not launch FoldBridge on the watch. The Mac–watch developer tunnel remained unavailable, so the watch screen and a physical lock/unlock cycle could not be checked directly. This does not establish reliable automatic recovery after every unlock or extended idle period. [Scope and remaining investigation](AUTO_RECONNECT_EN.md)

