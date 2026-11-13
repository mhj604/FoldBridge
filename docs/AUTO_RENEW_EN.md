# Automatic renewal with a free Apple account

[한국어](AUTO_RENEW_KO.md) · **English** · [Documentation](README.md)

This automates re-provisioning, signing and in-place installation from a Mac. It does not remove the seven-day Personal Team limit. Existing registration/settings are retained; the app is never uninstalled.

## Requirements and stopped schedule as of November 13, 2026

Follow-up [Windows and profile-only renewal research](SIGNING_WINDOWS_RESEARCH_EN.md) found free Windows Watch installation code, but its automatic renewal excludes Watch. Direct application without an iPhone remains unresolved. SideStore's iOS refresh can replace profiles without a full reinstall, so a full reinstall must not be described as universal across platforms. The procedure below describes this repository's Mac/Xcode tool.

The owner requires **free automatic renewal first, no Watch–Mac connection during renewal, internet on the watch only, and no manual renewal**. The Xcode tool below requires a development connection to a Mac and does not meet those requirements. The previous schedule has not been resumed.

Installed Watch **0.5.15 / build 41** profiles expire on **November 20, 2026 at 17:10:56 KST** for the app and **17:10:54 KST** for its vehicle widget. The local renewal record, previously left at version 0.5.2, was backed up and updated from this installed build's signed artifact. Recording these dates does not renew the app or enable a schedule.

This investigation did not establish an available free, watch-only, internet-based automatic renewal and installation path. [SideStore](https://github.com/SideStore/SideStore) uses an iOS app and local VPN. [Sideloadly v0.71.0](https://sideloadly.io/changelog) documents Watch processing for paid accounts, with free-account support planned. A [Windows Watch installation experiment](https://github.com/pookjw/HermesEnabler/issues/54) still requires a PC and USB-connected iPhone. None establishes watch-only automatic renewal.

The [Korean Apple Developer app](https://apps.apple.com/kr/app/apple-developer/id640199958) lists **KRW 129,000** for membership; [Apple's enrollment page](https://developer.apple.com/kr/programs/enroll/) specifies an annual term. The checkout price controls. Membership alone does not automatically refresh the existing development installation or convert it to an App Store app.

The official route for internet installation and updates without a Watch–Mac connection is [App Store distribution of an independent watchOS app](https://developer.apple.com/documentation/watchos-apps/creating-independent-watchos-apps). It requires membership, distribution preparation and Apple review; this project has not received approval. [TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) builds last up to 90 days and are not permanent releases. No purchase, review submission or new schedule was performed.

## Operation when a Mac connection is acceptable

- Tool: [`tools/watch-auto-renew.py`](../tools/watch-auto-renew.py), using Python's standard library and Xcode.
- **Six-hour** scheduling below is an optional configuration; the owner's previous schedule remains stopped. Cloning this repository does not install a schedule.
- Rebuild only when the earliest app/extension expiration is within **72 hours**.
- The Mac and Codex app must be running, Xcode signed in, and the watch available through its paired development connection. The tool waits until the watch is unlocked before starting installation.
- An unavailable/locked watch is retried on a later run. A powered-off Mac or prolonged separation from the watch can still result in expiration.

The tool compares the installed build number with committed source, extracts committed `watch/` files into a separate folder, backs up only the matching FoldBridge profiles, and requests new profiles through `xcodebuild -allowProvisioningUpdates`. Uncommitted changes are not built. It never automatically replaces an installed app with a different source version.

A build counts as renewed only if its actual earliest expiration advances. Pending builds are retained for later installation. `devicectl` installs the same app in place and launches it to resume its connection; no vehicle command is sent.

Sources: [Apple profile renewal procedure](https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles), [Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account).

## Set up another Mac

First build with your own team and install that signed app on the physical watch. Seed the configuration from that exact `.app` and watch UDID:

```sh
python3 tools/watch-auto-renew.py \
  --setup-from-app /absolute/path/to/FoldBridge.app \
  --device YOUR_WATCH_UDID
```

Team and Bundle ID are read from the signed app. Configuration, state, profile backups and logs stay in `~/Library/Application Support/FoldBridge/AutoRenew/`. The configuration records paths, Team/device/Bundle IDs and expiration dates, not account passwords or certificates. Do not publish the local state directory.

Ask Codex to schedule this command every six hours:

```sh
/usr/bin/python3 /absolute/path/to/FoldBridge/tools/watch-auto-renew.py
```

The schedule should stay quiet while nothing needs action, report completed renewal or required authentication, and notify if expiration is imminent and installation still cannot finish. The Mac and Codex must remain running. [OpenAI scheduled-task documentation](https://learn.chatgpt.com/docs/scheduled-tasks)

Use `--force` only for initial application or an intentional immediate renewal, not on recurring runs. Use `--config PATH` for an alternative local configuration.

## Status

| Status | Meaning |
| --- | --- |
| `not_due` | Enough validity remains; no changes |
| `renewed` | New profiles, installation and app launch completed |
| `waiting_watch_connection`, `waiting_watch_unlock` | Wait for the watch |
| `renewed_waiting_watch`, `install_pending` | Built app retained for installation retry |
| `renewed_waiting_app_launch`, `waiting_app_launch` | Installed app needs a later launch attempt |
| `build_failed`, `renewal_not_extended` | Inspect local `build.log` for provisioning/build problems |
| `source_version_differs` | Installed and committed source versions differ; no replacement |

Apple sign-in, two-factor authentication and keychain approval may still require the owner. Renewal does not change watchOS background execution limits or MyHyundai authentication requirements.

The initial application renewed, installed and launched Watch 0.5.2. Merely rebuilding does not necessarily extend validity; the tool reads actual expiration dates from the signed results.
