# Install and connect

[한국어](QUICK_START_KO.md) · **English** · [All guides](README.md)

For Android **0.5.4-local / code 15** and Watch **0.4.9 / build 23**. Notifications travel directly over BLE. No relay address, internet connection, or paid push setup is needed during use.

## 1. Prepare

- An Android 13+ phone with BLE advertising support. The current physical phone is a Galaxy Z Fold7.
- Apple Watch. The source targets watchOS 10+; support has not been established for every model/OS combination.
- A Mac with full Xcode compatible with the watch OS and your Apple signing account. A free Personal Team can be used.
- The paired iPhone for initial Apple Watch setup and, when needed, initial development-device preparation. It does not relay app notifications.

## 2. Get the files

Open [Releases](https://github.com/mhj604/FoldBridge/releases) for the Android APK and watch source ZIP. Extract the source ZIP before opening the project. Alternatively:

```sh
git clone --branch local-ble https://github.com/mhj604/FoldBridge.git
cd FoldBridge
```

The following paths are relative to this source folder. No setup is needed in `relay/`, `windows/`, or `legacy/`.

## 3. Install the phone app

1. [Download FoldBridge-Local-0.5.4.apk](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-Local-0.5.4.apk) and open it on the phone. Follow Android's installation prompt for the app that opened the APK.
2. Open **FoldBridge Local** and allow **Nearby devices** and notifications.
3. Tap **Allow notification access**. Enable **FoldBridge Local notifications** in the system list. This separate permission lets the app receive other apps' notifications.
4. If Android shows a restricted-settings notice, follow its device-specific instructions in App info, then return to notification access. Labels vary by OS version.
5. If the older **FoldBridge** app is installed, stop its connection. You can leave it installed.

You may select only the apps you want to forward. Notification access can include message content.

## 4. Install the watch app with your account

1. In Xcode **Settings → Accounts**, add your signing Apple account. It can differ from the Mac's or watch's account.
2. Enable developer mode on the watch and paired iPhone. Complete development pairing/device preparation in Xcode. If discovery fails, connect the paired iPhone to the Mac by USB for initial preparation.
3. On the watch, open **Settings → Privacy & Security → Developer Mode**, select the Mac if shown, and complete the displayed pairing/trust prompts. This is different from the top-level **Developer** menu.
4. Open `watch/FoldBridge.xcodeproj`. Under the FoldBridge target's **Signing & Capabilities**, choose your team.
5. If `dev.foldbridge.watch` is unavailable to your account, use your own unique Bundle ID, such as `com.yourname.foldbridge.watch`. The BLE service UUID does not change, so the distributed Android app can still connect.
6. Select the physical watch as the destination and press **Run ▶**. Keep it unlocked and connected to the Mac for installation. Same-network Wi-Fi may be needed for the development connection.

Handle Apple account, trust, and signing-keychain prompts directly on the devices. The watch source must be signed for your team/device; a universal pre-signed watch binary is not supplied.

For a command-line build:

```sh
python3 watch/build_watch.py --team YOUR_TEAM_ID --bundle-id com.yourname.foldbridge.watch
```

The script builds the app. Open the project, select the watch, and press Run to install. Regenerating the project may replace personal signing edits; keep using your chosen Bundle ID.

## 5. Register once

1. Phone: **Settings → Pair a new watch**. The window lasts two minutes. Initial registration and every later reconnection forward only notifications posted after authentication completes; earlier and offline notifications are discarded.
2. Watch: open **Connect phone**. A new installation uses the Local profile. If needed, choose **Choose phone app → FoldBridge Local**.
3. Tap **Find phone**, then select the Galaxy.
4. Compare the displayed codes and confirm on both devices only when they match.
5. Allow watch notifications. Both apps should show a connected state.

The peer keys are saved. Ordinary reconnection or restarting does not require registration again.

## 6. Everyday use

- Keep the phone connection service enabled and the devices within Bluetooth range.
- Optionally enable watch **Settings → Keep connection** and grant location permission. This requests background location runtime; coordinates are not inspected, stored, or transmitted. It can use more battery and does not guarantee continuous delivery.
- Read messages in **watchOS Notification Center**. FoldBridge has no separate message inbox.
- Press **Refresh connection** on either device when needed. A healthy connection synchronizes without replacing its session. If watchOS has stopped background execution, open the watch app once.
- **Sync now** retrieves pending notifications when already authenticated.
- After reboot, unlock both devices once. Open the watch app if it does not restore automatically.

## Change language

On each device, open **Settings → Language / 언어** and select **System default**, **한국어**, or **English**. To return to Korean, choose **한국어** in the same menu. Choices persist independently on the devices. UI/status messages change language; forwarded notification content is not translated. Language changes preserve registration.

## Updating

- If you installed a distributed APK, update with a later APK from the same repository/signing key.
- If you built Android yourself, retain and reuse your own key. A differently signed APK cannot update the existing installation. Uninstalling can lose registration and pending data; it is not the normal connection-recovery step.
- Keep the watch **Bundle ID and team** unchanged. Free development signing may require rebuilding when provisioning expires.
- **Refresh connection** preserves registration and filters. Healthy sessions synchronize current pending items; reconnection clears the previous queue. Use **Unpair** only to register again.

## Where the original icon appears

The initial popup, system header, and Notification Center system icon belong to FoldBridge. The expanded body shows an available source app icon at 24pt. Icons are not media attachments. Previously delivered notifications retain their original presentation; new presentation changes apply to newly received notifications.

[Troubleshooting](TROUBLESHOOTING_EN.md) · [FAQ](FAQ_EN.md) · [Build and device settings](BUILD_AND_SETUP_EN.md)
