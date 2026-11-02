# Build, signing, and device settings

[한국어](BUILD_AND_SETUP.md) · **English** · [All guides](README.md)

Current release: Android **0.5.4-local / code 15**, Watch **0.4.9 / build 23**. For installing the distributed APK and signing the watch app, start with [the setup guide](QUICK_START_EN.md).

## Android build

Install **SDK Platform 36**, **Build Tools 36.0.0**, and a full **JDK 17+**. The lightweight script compiles Java, creates DEX, packages, aligns, and signs an APK without Gradle. A Gradle configuration is also included; distributed APKs use the script.

```sh
python3 android/build_android.py \
  --sdk /absolute/path/to/android-sdk \
  --java-home /absolute/path/to/jdk \
  --keystore /absolute/path/to/foldbridge-local.keystore \
  --output /absolute/path/to/FoldBridge-Local-0.5.4.apk
```

Retain the signing key outside the repository and reuse it for updates. A different key cannot update an existing installation in place. The distributed app ID is `dev.foldbridge.local`.

For cable-free deployment from a Mac, see [wireless ADB installation](WIRELESS_INSTALL_EN.md). You can also download and install the APK directly on the Galaxy.

After installation, grant Nearby devices and notifications, then separately enable the **FoldBridge Local notifications** in notification-access settings. Stop the older FoldBridge connection if present. Register the watch once by comparing both codes; use **Connect watch** for normal operation.

## Watch build and installation

Use a Mac with full Xcode and your Apple signing account. Personal Team values are not committed to the project.

```sh
python3 watch/build_watch.py --team YOUR_TEAM_ID --bundle-id com.yourname.foldbridge.watch
```

The script generates the project and builds a watchOS app. To install, open `watch/FoldBridge.xcodeproj`, select your team and physical watch, then press **Run**. Keep the chosen Bundle ID/team for future updates. The default ID is `dev.foldbridge.watch`; choose a unique one if unavailable to your account. Omitting `--team` builds for the simulator without signing.

Enable developer mode and complete Mac development pairing before installation. The paired iPhone may be needed by USB during initial development setup. Actual notification delivery uses Galaxy–Watch BLE. Free development signing can require rebuilding after provisioning expires.

On the watch, use **Connect phone → Find phone**, choose the Galaxy, compare codes on both devices, and allow notifications. Select the **FoldBridge Local** profile if migrating from the old app. Optional **Settings → Keep connection** requests location runtime and can increase battery consumption.

## Diagnostic tools

Earlier device diagnosis used **REA 6.8.0** and Android platform-tools/ADB. They are development tools, not app runtime dependencies or relay servers. See the [REA repository](https://github.com/morluto/rea) for its installation instructions.

```sh
export REA_ADB_PATH=/absolute/path/to/adb
rea read-adb-setting DEVICE_SERIAL secure enabled_notification_listeners --format json
rea inspect-adb-package DEVICE_SERIAL dev.foldbridge.local --format json
rea read-adb-logcat DEVICE_SERIAL --pid APP_PID --count 200 --format json
```

Phone status is at `/sdcard/Android/data/dev.foldbridge.local/files/foldbridge-status.json`. Watch status is at `Documents/foldbridge-status.json` inside its app container. Current watch builds also keep a bounded `Documents/foldbridge-events.json` with connection stages, counters, and error codes. These files do not contain notification bodies, private keys, or location coordinates. Keep personal device logs out of public issues and commits.

## Sensitive notification content

This is optional, for owners who want full message contents relayed on their own Android device. Notification access and lock-screen visibility alone may not remove Android's sensitive-content redaction. On the development phone, `RECEIVE_SENSITIVE_NOTIFICATIONS` was set to `ignore`; changing the per-app AppOp and rebinding the listener allowed full content.

With your phone connected to ADB and USB debugging authorized:

```sh
adb shell cmd appops set --user 0 dev.foldbridge.local RECEIVE_SENSITIVE_NOTIFICATIONS allow
adb shell cmd notification disallow_listener dev.foldbridge.local/dev.foldbridge.NotificationRelay 0
adb shell cmd notification allow_listener dev.foldbridge.local/dev.foldbridge.NotificationRelay 0
```

The example uses Android user **0** and the distributed app ID. The command may be unavailable or restricted by a different OS/device policy. To restore the earlier blocked setting, set the AppOp to `ignore` and rebind the listener again. This is a device setting, not a permission the APK grants itself; reinstalling or policy changes may reset it. Content withheld by the original app remains unavailable. [Android implementation](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/android16-release/services/core/java/com/android/server/notification/NotificationManagerService.java)

Watch preview expansion is separate: **Settings → Notifications → Tap to Show Full Notification**. FoldBridge cannot change that system setting. [Apple notification settings](https://support.apple.com/108369)

## Restarts and recovery

Registration keys and the phone's connection-enabled preference persist. Unlock both devices once after reboot and leave Bluetooth enabled. Android resumes its foreground service after the supported boot/update/Bluetooth/listener events. The watch reconnects when watchOS gives it restoration or runtime opportunities; open it once if needed.

The watch requests background refresh with a preferred date 30 minutes later. This is neither a boot-launch hook nor a guaranteed schedule. Location keepalive resumes during an allowed foreground launch. Explicitly stopping the phone service or forgetting registration is respected. [watchOS background tasks](https://developer.apple.com/documentation/watchkit/using-background-tasks) · [Android foreground-service restrictions](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start)

## Shared icon and translations

Regenerate the project's own icon on a Mac:

```sh
xcrun swift tools/generate-app-icon.swift \
  watch/FoldBridge/Assets.xcassets/FoldBridgeIcon.appiconset/FoldBridgeIcon.png \
  android/app/src/main/res/drawable/foldbridge_icon.png
```

Third-party app icons are read from the user's phone at runtime; an icon collection is not bundled in the APK/repository.

Translations are maintained in `localization/en.json`, keyed by Korean UI strings. After editing:

```sh
python3 tools/generate-localization.py
python3 watch/generate_project.py
```

Generated resources are committed, so first-time users do not need to regenerate them. Android uses per-app locale settings; the watch stores its own language selection. Notification content and source app names are not translated, and changing UI language preserves the session.
