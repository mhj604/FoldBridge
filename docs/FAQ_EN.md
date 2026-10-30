# Frequently asked questions

[한국어](FAQ_KO.md) · **English** · [All guides](README.md)

## Can I use it without an iPhone or internet?

App notifications travel directly between the Galaxy and watch over BLE. Normal delivery needs no iPhone relay, server, or internet. Initial Apple Watch setup still needs the paired iPhone. Watch installation uses a Mac/Xcode development connection, which is separate from everyday BLE delivery.

## Do I need a Mac or paid Apple membership?

Building/installing the watch app requires a Mac with compatible full Xcode. A free Personal Team can be used. Local does not use paid push features. Development signing may expire and require rebuilding/reinstalling.

## Can the Xcode account differ from the watch account?

Yes. The signing account need not match the Mac's or watch's account. Use your own team, a unique Bundle ID, and complete development-device registration.

## Can I just download a watch installer?

The Android app is distributed as an APK. Sign the watch source for your own team/device and install through Xcode. [Setup instructions](QUICK_START_EN.md) cover the process. A Windows/Linux-only build path for the watch app is not provided.

## What happens when the screen is off or the devices restart?

The apps attempt restoration using saved registration. Refresh on either device requests synchronization while retaining a healthy session. After reboot, unlock both once and leave Bluetooth on. watchOS runtime/budgets and force-quit can require opening the watch app once. Optional location keepalive does not guarantee unlimited background delivery.

## Does the app keep a message inbox?

Read messages in watchOS Notification Center. FoldBridge keeps no separate watch inbox. The phone encrypts only pending items for up to 24 hours / 1,024 entries. Replies and bidirectional read/delete synchronization are not implemented.

## Why does the system icon show FoldBridge?

FoldBridge is the sending app for the system popup, Notification Center, and system header. An available original app icon appears at 24pt inside the expanded body. [Display scope](NOTIFICATION_DISPLAY_LIMITS_EN.md)

## Why is a message replaced by “Sensitive notification”?

Android may redact contents before the listener receives them. Device owners who want full contents can follow the [per-app setting instructions](BUILD_AND_SETUP_EN.md#sensitive-notification-content). Content withheld by the original app cannot be reconstructed.

## Should I uninstall when updating or reconnecting?

Normally, no. Try refresh on one side for connection problems. Updates need the same Android signing key and watch Bundle ID/team. A self-built APK with a different key cannot update the distributed APK in place. [Updating](QUICK_START_EN.md#updating)

## How do I ask for help or contribute a translation?

Open a [GitHub issue](https://github.com/mhj604/FoldBridge/issues) in Korean or English. Include app/OS versions, device models, button actions, and whether the watch app was visible or backgrounded. [Contributing](../CONTRIBUTING.en.md) explains code and translation locations.
