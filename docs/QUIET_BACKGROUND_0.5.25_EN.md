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


## Follow-up investigation and display preference — 2026-11-18 KST

REA acquired app-owned records from the same installed Android code 41 and Watch build 59. Both reported authentication and read delivery. Watch events show earlier GATT-service waiting followed by authentication with `active=false`. Acquisition occurred after the initial failure report; the records do not establish whether the phone service had been stopped or service discovery was delayed at that exact time. They also do not establish that opening the Watch app was necessary for authentication.

The display issue was investigated separately. The same Watch process reported `active=false` and native `applicationStateName=inactive`, which differs from actual background. Existing `lifecycle.background` events are emitted whenever SwiftUI is not active, so their names alone cannot distinguish inactive/frontmost from background. Likewise, the phone's `watchActive` includes continuous runtime availability and is not a literal visibility flag.

Watch UI interaction, unsupported directly by REA, used Mac Device Hub separately:

- **Return to Clock → WatchBridge → Custom → Always** was already selected. **Return to App** was absent on this device; the earlier conditional instruction must not imply that this switch exists for every app/device.
- **Smart Stack → Allow Live Activities** was already off.
- **Accessibility → App Switcher → Auto-Select Focused App** was on. The system explains that focusing an app for one second opens it without a tap. This was changed to **off**, then the watch was returned to its clock face. This is a system-wide App Switcher preference, not a WatchBridge-only setting. Registration, connection-keeping preference, keys and vehicle configuration were retained; no new app build was installed.

This removes an observed system route for opening the app without tapping it. It does not establish the sole cause of every reported foreground transition or prove that none can recur. Location-session presentation and automatic App Switcher selection are separate. [Apple's Auto-Select guide](https://support.apple.com/guide/watch/apd081746d24/27/watchos/27).

The phone also reported `suppressedBatteryProtection=20`, providing an actual instance of the new filter suppressing notices. No personal notification content is published. Evidence IDs are listed in the Korean report.

This work used app-owned diagnostic records and applied a display preference. No broad QA, synthetic notifications, forced-disconnection or range experiments were performed. Multi-hour lock and physical range return after build 58 remain unfinished.
