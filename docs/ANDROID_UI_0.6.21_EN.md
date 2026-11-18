# Android 0.6.21 — Diagnostic version and connection prompt

[한국어](ANDROID_UI_0.6.21_KO.md) · **English** · [Current status](CURRENT_STATUS_EN.md)

November 18, 2026 KST. Android **0.6.21-local / code 43**. Watch **0.5.28 / build 62** is unchanged.

- Opening connection diagnostics reads the installed package version/build. This installation displays `WatchBridge 0.6.21-local (43)`.
- The phone's introductory text is now **“Connect your phone and watch.”**, with the corresponding Korean prompt.
- Installed in place using the existing Android signing key and app ID `dev.foldbridge.local`. No uninstall, registration/settings reset or new pairing was performed.
- After REA installation, app-owned state reported actual build **43**, notification access and a bound notification listener. Connection, encryption and watch code are unchanged; no separate range or multi-hour-lock test was performed.

[Download APK](https://github.com/mhj604/WatchBridge/releases/download/android-v0.6.21/WatchBridge-0.6.21.apk). Existing users should update without uninstalling.

REA evidence: replacement install `ev_5870520e329a137dc1c2b1bda18ca4db06fd1ca81be33ad7b2b8213a02e11cf6`, launch `ev_13318131405b69c17c88e1bedcbf6fb06808ed7c95d185f183dee2cfe24afdac`, post-install build 43 `ev_362c45d341a7973d6939134291cc84074a1583d91b6759d75dd5dd78d4b64fd4`. Raw records and the signing key remain local.

The saved peer also automatically restored authentication/read delivery after installation, with zero phone refreshes and no error. Evidence: `ev_df5c592042ec4be77c3c4acf0d72862576c76c902f0855d622ad77084a4ec710`.
