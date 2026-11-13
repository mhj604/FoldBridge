# Automatic renewal with a free Apple account

[한국어](AUTO_RENEW_KO.md) · **English** · [Documentation](README.md)

This automates re-provisioning, signing and in-place installation from a Mac. It does not remove the seven-day Personal Team limit. Existing registration/settings are retained; the app is never uninstalled.

## November 13, 2026: once-weekly native macOS scheduling

Follow-up [Windows and profile-only renewal research](SIGNING_WINDOWS_RESEARCH_EN.md) found free Windows Watch installation code, but its automatic renewal excludes Watch. Direct application without an iPhone remains unresolved. SideStore's iOS refresh can replace profiles without a full reinstall, so a full reinstall must not be described as universal across platforms. The procedure below describes this repository's Mac/Xcode tool.

The latest request explicitly selects **one renewal every seven days using macOS native scheduling**. The default is **Friday at 16:00 in the Mac's local time zone**. With the November 13 setup, the first run is **November 20 at 16:00 KST**, before the recorded current expiry. The old Codex schedule stays stopped; Codex does not need to be running. Unlike the previously requested watch-internet-only approach, this selected method uses the Watch's wireless development connection to the Mac during renewal.

Installed Watch **0.5.15 / build 41** profiles expire on **November 20, 2026 at 17:10:56 KST** for the app and **17:10:54 KST** for its vehicle widget. The local renewal record, previously left at version 0.5.2, was backed up and updated from this installed build's signed artifact. Recording these dates does not renew the app or enable a schedule.

This investigation did not establish an available free, watch-only, internet-based automatic renewal and installation path. [SideStore](https://github.com/SideStore/SideStore) uses an iOS app and local VPN. [Sideloadly v0.71.0](https://sideloadly.io/changelog) documents Watch processing for paid accounts, with free-account support planned. A [Windows Watch installation experiment](https://github.com/pookjw/HermesEnabler/issues/54) still requires a PC and USB-connected iPhone. None establishes watch-only automatic renewal.

The [Korean Apple Developer app](https://apps.apple.com/kr/app/apple-developer/id640199958) lists **KRW 129,000** for membership; [Apple's enrollment page](https://developer.apple.com/kr/programs/enroll/) specifies an annual term. The checkout price controls. Membership alone does not automatically refresh the existing development installation or convert it to an App Store app.

The official route for internet installation and updates without a Watch–Mac connection is [App Store distribution of an independent watchOS app](https://developer.apple.com/documentation/watchos-apps/creating-independent-watchos-apps). It requires membership, distribution preparation and Apple review; this project has not received approval. [TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) builds last up to 90 days and are not permanent releases. This setup makes no purchase or review submission.

## Operation when a Mac connection is acceptable

- Tool: [`tools/watch-auto-renew.py`](../tools/watch-auto-renew.py), using Python's standard library and Xcode.
- Schedule installer: [`tools/install-watch-weekly-renew.py`](../tools/install-watch-weekly-renew.py), registering a per-user macOS LaunchAgent. The default is **Friday at 16:00**; no six-hour polling or retry job is created.
- Installation sets the renewal threshold to 168 hours. This is not a polling interval: it lets the one weekly run renew without skipping the week. Recurring runs do not use `--force`.
- The Mac must be awake with its user logged in and Xcode signed in; the unlocked watch must be on the same Wi-Fi and reachable through its paired wireless development connection. No cable or running Codex app is required.
- An unavailable/locked watch leaves the app intact and records a waiting status. There is no separate short-interval retry schedule. Seven days is the owner's explicitly selected interval; if a scheduled renewal fails, another pre-expiration attempt is not guaranteed.
- `caffeinate -i` prevents idle sleep only while renewal runs. No permanent process or power-setting change is installed.

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

Run this command **once** to register the weekly schedule. Registration does not immediately renew or connect to the watch:

```sh
python3 tools/install-watch-weekly-renew.py --weekday 5 --hour 16 --minute 0
```

Weekdays run from Monday=1 to Sunday=7. The runner and an independent Git copy of committed source are staged in the local state folder, so scheduled runs do not read the Documents worktree. Bundle ID, Team, registration and expiration records are retained; personal settings and device identifiers are not added to this repository. When deploying a new app version, rerun the installer from its committed source to update the staged copy too.

The agent is `~/Library/LaunchAgents/dev.foldbridge.weekly-renew.plist`. Run `python3 tools/install-watch-weekly-renew.py --remove` to remove only this schedule, retaining apps, registration and local settings. [Apple launchd documentation](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

Results stay in local `state.json`, `weekly.stdout.log` and `weekly.stderr.log`. These are renewal task outputs, not collected Watch system logs. This LaunchAgent does not create Codex notifications.

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
