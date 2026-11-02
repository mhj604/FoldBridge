# Notification appearance and supported scope

[한국어](NOTIFICATION_DISPLAY_LIMITS_KO.md) · **English** · [All guides](README.md)

Current presentation: **Watch 0.4.8/build 22**. The Korean document also preserves earlier investigations. Full system-icon replacement was excluded from the subsequent layout work; the current approach retains a small source icon in expanded content.

| Area | Renderer | Current appearance |
| --- | --- | --- |
| Initial short-look popup | watchOS | FoldBridge system icon/name and notification title |
| Notification Center system card | watchOS | Notification belonging to FoldBridge |
| Expanded notification's system header | watchOS | FoldBridge icon/name |
| Expanded content body | FoldBridge SwiftUI when an icon is available | Original app name, message, and 24pt source icon |

Without source icon data, FoldBridge uses the system text layout. Source icons are not media attachments. They therefore do not create the oversized media preview or recycled thumbnail seen in older builds. Previously delivered notifications are not deleted or resent just to change presentation.

## Layout control

Apple describes short-look as system-generated and long-look as a separate scrolling presentation whose content can be customized. Changing a SwiftUI body does not replace the whole system template. Watch 0.4.8 retains the layout adjustments from 0.4.7, which shortened only the lower spacing by 4pt on watchOS 27+. [Layout examples](NOTIFICATION_LAYOUT_COMPARISON_EN.md) · [Apple notification presentation](https://developer.apple.com/documentation/watchos-apps/presenting-notifications-on-apple-watch)

## Earlier alternatives investigated

- **Image attachment:** tried in Watch 0.4.1, removed in 0.4.2. The system treated the icon as media, making it large or reusing it as a thumbnail. Reducing PNG dimensions did not control the system's media region.
- **Communication notifications:** sender avatars for supported person-to-person messaging/call intents are a different mechanism from replacing arbitrary source-app icons. The earlier account/capability review did not establish a usable path under the project's free-team conditions. No such implementation was adopted. [Apple communication notifications](https://developer.apple.com/documentation/usernotifications/implementing-communication-notifications)
- **Accessory Notifications / ANCS:** these describe other device roles and are not an implemented Android-to-watchOS system-icon replacement path in FoldBridge. [Accessory Notifications](https://developer.apple.com/documentation/accessorynotifications) · [ANCS specification](https://developer.apple.com/library/archive/documentation/CoreBluetooth/Reference/AppleNotificationCenterServiceSpecification/Introduction/Introduction.html)
- **Native-protocol research:** the previously reviewed `apple_watch_connector` Android path required root and a specific OnePlus model. It was not installed on the unrooted Galaxy used here. This investigation did not produce an adopted implementation for this project. [Research project](https://github.com/LordixDemon/apple_watch_connector)

These are historical investigation results, not instructions to replace the current working setup. The [Korean archive](NOTIFICATION_DISPLAY_LIMITS_KO.md) includes detailed references and REA evidence IDs.

## What REA established

REA 6.8.0 inspected the earlier build's plist, Mach-O files, and compiled assets. It identified the FoldBridge app icon and custom notification-scene/local-notification dependencies. This was analysis of local build artifacts, not observation or modification of the watchOS notification system process. Separate signing observations were made using `codesign`.

Those observations support the implementation description; they do not grant additional OS capabilities or prove identical rendering in every system view. Current setup, source icons in expanded content, and system FoldBridge branding are described above.
