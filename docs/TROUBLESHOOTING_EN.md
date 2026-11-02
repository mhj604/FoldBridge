# Connection and notification troubleshooting

[한국어](TROUBLESHOOTING_KO.md) · **English** · [All guides](README.md)

## Disconnected or “Authentication timed out”

1. Enable Bluetooth on both devices and bring them close together. After a reboot, unlock both once.
2. Press **Refresh connection** on either the phone or watch. You do not need to press both.
3. On a healthy link, refresh sends an encrypted synchronization request and retains the connection/session. When disconnected, recovery uses the saved peer key.
4. Once connected, pending notifications synchronize automatically.

Refresh preserves registration and pending items. Allow recovery to proceed instead of repeatedly pressing the button. Watch 0.4.7 removes the previous periodic ping and short background-response disconnects. Service changes rebind the GATT characteristics while preserving a healthy session; actual process restoration authenticates with fresh nonces.

Watch 0.4.8 requests Core Bluetooth automatic reconnection for saved peers. When the devices return within range, watchOS and the app retry path attempt recovery, but an immediate link is not guaranteed. The first successful new registration clears older queued alerts; recovery of an already registered peer keeps its pending queue.

A locked/background watch needs an OS-retained BLE connection and available watchOS runtime. The phone button cannot unconditionally launch a watch app. If a background-limit message appears or recovery stalls, open FoldBridge on the watch once. Force-quit, Bluetooth off, and being outside range need separate attention. [Background tasks](https://developer.apple.com/documentation/watchkit/using-background-tasks)

If the error says the **saved peer key differs**, check whether an app was removed/reinstalled or a device/key changed. That situation may require forgetting registration on both sides and comparing new codes. A simple timeout usually does not.

## Connected, but no notifications

- Android's own notification permission and **notification access to other apps** are separate. Enable **FoldBridge Local notifications** in notification-access settings.
- Check the selected apps, watch notification permission, and Focus settings.
- Phone diagnostics separate collected notifications, delivery requests, and watch acknowledgments. Watch settings show received/display-request counts. These cumulative counters need not match because duplicates can be acknowledged again.
- Acknowledgment means the watch accepted a local display request or recognized a revision. It does not prove the user saw, heard, or read it.
- If watchOS suspended delivery, open the watch app and synchronize. Optional location keepalive still depends on OS scheduling.

## “Sensitive notification” instead of message text

Android can redact content before the listener receives it. See [sensitive-content settings](BUILD_AND_SETUP_EN.md#sensitive-notification-content) for the device-specific, optional setting. Content withheld by the original app cannot be reconstructed. The watch's **Tap to Show Full Notification** setting separately controls preview expansion.

## Charging notifications repeat

Leave **Charging status alerts** off to exclude Samsung System UI charging updates. Battery-percentage changes can update their contents repeatedly. This filter does not exclude ordinary app notifications or every system notification.

## The original icon does not appear everywhere

The system popup/header and Notification Center system icon show FoldBridge. Source app icons appear only in the expanded body when available. Notifications without an icon use the system text layout. [Display scope](NOTIFICATION_DISPLAY_LIMITS_EN.md)

Old versions used source icons as attachments, which made them oversized media previews or card thumbnails. Current builds do not attach them as images. Previously delivered notifications keep their old attachments; updating does not delete or resend them.

## Expanded notification spacing looks different

Watch 0.4.7/build 21 uses a bounded-width SwiftUI body with a 24pt icon overlay. It keeps the text/icon position from 0.4.6 and trims the bottom spacing by 4pt on watchOS 27+. Text uses a 16pt baseline size, zero extra paragraph gap, and adjusted body line height on watchOS 26+. Long content uses system scrolling. System popup and expanded-body templates remain different. [Screenshots and layout history](NOTIFICATION_LAYOUT_COMPARISON_EN.md)

The FoldBridge app icon was also recentered in earlier releases. If the system still shows an older cached app icon, open the app again or restart the watch; uninstalling is not required solely to refresh an icon.

## Cannot install the watch app

Use your own Apple team, unique Bundle ID, and development-device registration. Keep the watch unlocked and maintain the Mac development connection during installation. A compatible full Xcode installation is required. Pairing with the Mac is separate from registering the Galaxy inside FoldBridge. [Installation steps](QUICK_START_EN.md#4-install-the-watch-app-with-your-account)

## Android update reports a signature mismatch

Use the same signing key as the existing APK. A self-built APK has a different key from a distributed one. See [updating](QUICK_START_EN.md#updating) before removing an app and losing its local registration/data.

## Asking for help

Open a [GitHub issue](https://github.com/mhj604/FoldBridge/issues) in Korean or English. Include both app versions, phone/watch models and OS versions, what you pressed, and whether the watch app was visible, backgrounded, or force-quit. Connection stage and error text are useful; private messages, device identifiers, signing keys, and raw personal logs are not needed.
