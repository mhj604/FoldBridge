# Update the Galaxy app without a cable

[한국어](WIRELESS_INSTALL_KO.md) · **English** · [All guides](README.md)

Normal notification delivery uses Galaxy–Watch Bluetooth. The Wi-Fi connection below is only for installing APKs or reading app status from a Mac.

## Install the APK directly

Download the APK from the [latest release](https://github.com/mhj604/FoldBridge/releases/latest) on the Galaxy and open it in **My Files → Downloads**. Update the existing FoldBridge Local installation. No Mac connection or developer options are needed. Use an APK signed with the same key as the installed app.

## Install wirelessly from a Mac

Android 11 and later support ADB pairing and installation without USB. Connect the Mac and Galaxy to the same Wi-Fi and install current Android SDK Platform Tools.

One-time registration:

1. On the Galaxy, enable **Settings → Developer options → Wireless debugging**.
2. Open **Pair device with pairing code** and use the IP and port from that dialog:

   ```sh
   adb pair PHONE_IP:PAIRING_PORT
   ```

3. Enter the one-time six-digit code when prompted.
4. Close the pairing dialog and use the IP and port on the **main Wireless debugging screen**. The connection port may differ from the pairing port.

   ```sh
   adb connect PHONE_IP:CONNECT_PORT
   adb -s PHONE_IP:CONNECT_PORT install -r /absolute/path/to/FoldBridge-Local-0.5.4.apk
   ```

## Later updates

Enable wireless debugging on the same Wi-Fi. If automatic connection does not occur, run `adb connect` with the current endpoint from the main screen. An address or port change does not require another pairing code while the Mac remains registered. No USB cable is needed.

A reboot or network change may require enabling wireless debugging again. If `adb mdns services` is empty, connect directly to the current IP and connection port. Repeat initial pairing only if the Mac registration was removed or debugging authorizations were revoked.

`install -r` updates the app while retaining its data. For a signature mismatch, use an APK built with the original signing key. Removing the app to resolve a connection issue also removes its saved watch registration.

This Mac development pairing is separate from the code comparison inside FoldBridge for Galaxy–Watch registration. Keep personal pairing codes and ADB keys out of public guides and issues.

[Official Android wireless ADB instructions](https://developer.android.com/tools/adb#connect-to-a-device-over-wi-fi)
