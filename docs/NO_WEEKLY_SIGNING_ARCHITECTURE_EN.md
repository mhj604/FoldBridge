# Avoiding weekly renewal: distribution and Watch-client alternatives

[한국어](NO_WEEKLY_SIGNING_ARCHITECTURE_KO.md) · **English** · Research date: **2026-11-13**

Further research: [signing bypass on the current watchOS target](WATCHOS_27_SIGNING_BYPASS_RESEARCH_EN.md), covering historical permasigning, Calif's original posts, the Brotli PoC, virtual Watch execution, and missing implementation stages.

## Follow-up decision: no permanently attached USB adapter

The user selected the system-protocol direction, then excluded the USB option after clarification that the adapter must remain attached during normal operation, not just initial setup. The no-root USB PR below is therefore research history, not an adopted implementation plan.

Upstream source and PR #8/#12 were fetched locally for source inspection. The main source revision is `3af14e0226113d465d3ab84a9d30a16f84c968c0`. [`RootBluetoothHalHost`](https://github.com/LordixDemon/apple_watch_connector/blob/3af14e0226113d465d3ab84a9d30a16f84c968c0/apple-watch-bridge/hal/src/main/java/dev/applewatchandroid/bridge/RootBluetoothHalHost.java) requires UID 0 and OnePlus CPH2653. [`AndroidBluetoothController`](https://github.com/LordixDemon/apple_watch_connector/blob/3af14e0226113d465d3ab84a9d30a16f84c968c0/apple-watch-bridge/hal/src/main/java/dev/applewatchandroid/bridge/AndroidBluetoothController.java) exchanges raw HCI commands and ACL packets through `IBluetoothHci`. Removing the model restriction does not grant ordinary-app access, nor establish rooted Fold7 support.

No implementation replacing this transport with ordinary Android Bluetooth APIs or CompanionDeviceManager was established. In particular, companion association does not itself create the communication link. [Android documentation](https://developer.android.com/develop/connectivity/bluetooth/companion-device-pairing)

**A native transport meeting the selected conditions—unrooted Fold7 built-in Bluetooth, no custom Watch app, and no permanently attached external device—has not been obtained.** No APK build, installation, or protocol integration was performed. Existing apps and registrations remain intact. Progress would first require another implementation or a new transport providing Apple protocol access under those conditions. Weekly renewal is not solved, and USB development is not proceeding.

## Result

Moving development to Windows or VS Code does not remove watchOS signing requirements. This investigation considers changing distribution or eliminating the custom Watch executable. No ready-to-use replacement was established that satisfies every condition: free, no manual renewal, no iPhone during normal use, local Bluetooth notifications without an external server, and vehicle control.

The strongest direction for preserving existing features is **App Store distribution of FoldBridge**. It can be free for users, but a publisher must maintain membership or qualify for a fee waiver. An Android implementation of Apple's system protocol is a separate possibility. A no-root USB proposal exists, but current Fold7 / watchOS 27.2 operation is not established.

The research covered 65 search-result slots, including duplicates, and primary documentation and source. Proposals are not device results. No apps, registrations, device connections, or canceled renewal schedules were changed. No system logs or vehicle commands were used.

## Comparison

| Direction | Weekly user renewal | Cost | Feature boundary |
| --- | --- | --- | --- |
| FoldBridge on the App Store | Removed | Free to users; publisher membership or waiver needed | Retains the app/widget design, subject to publication work and review |
| Android system-protocol implementation | No custom Watch app to renew | Free software; no-root proposal requires USB Bluetooth hardware | Current-device support unestablished; vehicle widget needs replacement |
| Built-in Shortcuts → Galaxy local HTTP | No custom Watch binary for this path | Built-in Shortcuts is free | Vehicle-control proposal only; local networking needed; no background notification replacement |
| Existing free Bluetooth Watch client | No user development-profile renewal | Free candidate exists | Berkanan Lite receives only in the foreground on Watch |
| Merge | No user development-profile renewal | Subscription required | Excluded by the free requirement; current vehicle-widget integration unestablished |

## Distribution while retaining FoldBridge

Apple supports [watch-only App Store distribution without an iOS companion](https://help.apple.com/xcode/mac/current/en.lproj/devaba4602fd.html). This can remove the user's weekly Personal Team profile refresh without adding an iPhone runtime relay. Apple signing still exists. Distribution alone does not fix watchOS background execution or Bluetooth reconnection behavior.

An enrolled partner could publish FoldBridge free to users, retaining publisher costs and responsibilities. No partner has been secured. Alternatively, [Apple's fee waiver](https://developer.apple.com/help/account/membership/fee-waivers/) covers qualifying nonprofit legal entities, accredited educational institutions, and government entities. Individuals, sole proprietors, and single-person businesses are excluded. Open-source status alone is insufficient. Annual eligibility confirmation still requires publisher operation.

[TestFlight](https://testflight.apple.com/) builds expire after 90 days. [Unlisted distribution](https://developer.apple.com/support/unlisted-app-distribution/) still requires App Store review and is not free personal permanent signing.

## Removing the custom Watch client

[`apple_watch_connector`](https://github.com/LordixDemon/apple_watch_connector) implements system communications on Android, offering a direction toward system notifications without a FoldBridge Watch app. Its main device evidence concerns Ultra 2 / watchOS 26.2. Its built-in Android Bluetooth path requires root and restricts supported hardware. This is not evidence for the current unrooted Fold7 / watchOS 27.2.

[PR #8](https://github.com/LordixDemon/apple_watch_connector/pull/8) proposes an external USB Bluetooth transport using Android USB Host APIs. It is **open and unmerged** as of the research date; the author reports no hardware confirmation. It does not make Shizuku an alternative to root for the built-in controller. Software is free, but purchasing an adapter would violate a zero-total-cost condition.

The [setup document pinned at `aa8578202e3ca4e5384aacf36f482d2272f54449`](https://github.com/intragalactic-stranger/apple_watch_connector/blob/aa8578202e3ca4e5384aacf36f482d2272f54449/docs/NO_ROOT_USB.md) requires an erased Watch in system pairing mode. This is not an update preserving current system pairing. No such operation was performed.

[PR #12](https://github.com/LordixDemon/apple_watch_connector/pull/12) addresses discovery events failing to populate the setup list. It is also open and unmerged without the author's hardware confirmation. A discovery fix does not establish pairing, notification delivery, or watchOS 27.2 support.

A proposed vehicle integration could expose Galaxy vehicle actions as actionable notifications and return Watch notification actions to the existing Galaxy control code. This would be new work, not retention of the current WidgetKit widget or interception of the installed MyHyundai Watch app.

## Separating vehicle control with Shortcuts

```text
Watch shortcut complication → vehicle-action menu
  → local HTTP over the same Wi-Fi or Galaxy hotspot
  → Galaxy control code → official MyHyundai widget
```

[Apple supports Watch shortcuts and complications](https://support.apple.com/guide/shortcuts/run-shortcuts-from-apple-watch-apd5888b0858/ios), with initial visibility configured on iPhone/iPad. [Apple's execution model](https://developer.apple.com/videos/play/wwdc2020/10190/) distinguishes locally supported actions from actions delegated to the paired iPhone. A custom intent extension would itself still be custom signed Watch code.

A [firsthand implementation example](https://github.com/iamsupersocks/siri-watch-repod-hermes-on-the-go) uses HTTP requests in Watch shortcuts. It does not establish this Galaxy-hotspot vehicle path on watchOS 27.2. A Galaxy local listener and authenticated requests would need implementation; they were not added here.

This could avoid an external relay server, but changes Bluetooth-only operation to local Wi-Fi. It addresses user-triggered vehicle control, not unattended notification reception while locked.

## Existing clients

- [Berkanan Messenger Lite](https://apps.apple.com/us/app/berkanan-messenger-lite/id1479731429) is a free, open-source, independent Bluetooth Watch app. Its publisher limits Watch send/receive to foreground operation, excluding the required locked/background path.
- [Merge's official listing](https://play.google.com/store/apps/details?id=com.mergecorp.mergeandroid&hl=en) requires a subscription after a seven-day trial. It is not permanently free.
- [wrist/off](https://wristoff.com/) provides direct Watch HTTP actions, but only one button is free. It is not a complete free multi-button replacement.
- [Home Assistant](https://companion.home-assistant.io/docs/apple-watch/) adds a server architecture. [ntfy's Apple client](https://docs.ntfy.sh/subscribe/phone/) does not establish an independent Watch receiver. Neither establishes the required serverless, iPhone-free Bluetooth replacement.

## Direction

For retaining existing features, pursue an App Store publisher. For eliminating custom Watch code, treat the native-protocol no-root USB proposal as separate research. For vehicle control alone, consider Shortcuts and a Galaxy local endpoint.

No immediately deployable path was established that preserves zero cost, no additional hardware, existing system pairing, Bluetooth-only operation, background notifications, and vehicle controls. This is an architecture report, not an implementation or migration completion claim.
