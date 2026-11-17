# WatchBridge 0.5.25 — background presentation and charging protection

[한국어](QUIET_BACKGROUND_0.5.25_KO.md)

2026-11-17 KST. Android **0.6.19-local / code 41**, Watch/widget **0.5.25 / build 59**, on `fix/watch-background-reconnect`. Build-58 connection recovery, registration, keys, vehicle settings and stable installation IDs are retained.

## Exclude charging-protection notices

The previous rule recognized `charging_state` or ongoing system notifications in channel `CHR`. The reported Samsung charging-protection/percentage-limit notice can fall outside those conditions if it uses other metadata. Its fresh metadata has not yet been acquired, so a changed tag/channel is not asserted as the established device-level cause.

The new rule only applies to **`com.android.systemui`**, matching Korean/English battery-protection or charging-limit meaning across title, body and expanded text. It excludes forwarding regardless of percentage, tag, key or the separate charging-status preference. Both new posts and active-notification lookup apply the rule, and matching pending entries are discarded. Only a suppression count is recorded in app state; notification text is not retained by this diagnostic.

Other apps, unrelated SystemUI alerts and Samsung's original phone charging UI remain. Additional languages or changed wording may need additional matching.

## Background execution versus visible app

REA initially observed the watch in actual background, with eligible location runtime and authentication. That does not establish the cause of every screen transition reported by the owner.

The discovered foreground-launch path was the Mac's post-install/renewal command, whose CLI defaults to `--activate`. It now requests **`--no-activate`**, without a foreground fallback. This request succeeded on the owner's watch. User taps on the vehicle widget still open its control panel.

Wrist-raise app restoration is controlled by **Watch Settings → General → Return to Clock → WatchBridge → Custom → Always**. Disable Return to App if available. The app adds accurate guidance rather than a fake toggle that changes a system-owned preference. The location-activity system glyph is not hidden. [Apple display-settings guide](https://support.apple.com/guide/watch/adjust-the-display-settings-apd127ec93ac/27/watchos/27).

## Deployment and remaining scope

Build 59 was installed and launched with `--no-activate`. Android 0.6.19 was built with the existing signing key; subsequent entries record device installation. Both diagnostic build numbers now use installed metadata rather than hard-coded values. Evidence IDs are listed in the Korean report. REA CLI Android operations and process capture around Apple `devicectl` were used. No system logs, administrator authentication, registration reset, vehicle commands, broad QA or diagnostic notifications were used.

Multi-hour/overnight lock and physical departure/return after build 58 remain unfinished. Presentation/filter changes do not establish those outcomes. [Earlier connection report](REA_0.5.24_EN.md).

The post-install `--no-activate` request succeeded, but acquiring the subsequent app state failed with a Mac–Watch tunnel timeout (`ev_d0df01e753ba4d6d865cef2fad83b7a54fff1ac87163495b2ecb68be5a7ce422`). Command success is distinguished from observing the resulting screen/new-process state. Android device installation is waiting for the debugging port.


## Final deployment — 2026-11-17 KST

Restarting the ADB server restored access to the same Galaxy address/port without changing network or device registration. Android **0.6.19 / code 41** was installed in place, and app-owned state reported authentication and read delivery. The charging-protection suppression count was 0 at acquisition, so no claim is made that a real instance of that notice was observed being filtered. The matching implementation and deployment are complete.

Watch acquisition subsequently succeeded: the new **build-59** process reported actual background state, eligible location activity, authentication and read delivery. The owner also reported completing the Return to Clock preference. Installation/state Evidence IDs appear in the Korean report. The private renewal snapshot was aligned to installed build 59; no renewal or scheduling change was performed.
