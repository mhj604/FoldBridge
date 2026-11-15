# Android 0.6.15 / Watch 0.5.19 — retain background recovery requests

[한국어](BACKGROUND_RECOVERY_0.5.19_KO.md) · [Documentation](README.md)

Candidate dated 2026-11-15: Android **0.6.15-local / code 33**, Watch/widget **0.5.19 / build 45**. [Download APK](https://github.com/mhj604/WatchBridge/releases/download/connection-v0.5.19/FoldBridge-Local-0.6.15.apk). Registration, identity and pinned peer keys, and vehicle settings are retained.

## Execution-state correction (2026-11-15)

`active=false` means the app was not active. The accompanying `applicationState=1` is SDK `inactive`, not `background=2`, and does not prove passcode lock. Read background-success wording below as **authentication completed while inactive without a Watch app launch command**. It is not evidence of prolonged-lock or actual range-return completion.

## Evidence and missing recovery paths

The phone service was stopped at task start as requested at the preceding handoff; registration was retained. Watch events showed a service refresh stuck in `rediscovering`, 29 discarded fragments and a later Bluetooth connection timeout. These do not prove the device was in prolonged lock or physically out of range.

Code paths could lose recovery work:

- A connection failure left only an app-timer retry, which may not execute after background suspension.
- A scan-only restoration without the saved peripheral stopped scanning and did not explicitly resume. Another Bluetooth state callback was not guaranteed.
- A second service invalidation during rediscovery was ignored, leaving obsolete service/characteristic callbacks outstanding.
- Accepting phone CCC unsubscribe retained the claimed peer and could prevent advertising while Android's shared physical LE link remained.

## Changes

Transient background connection failures immediately submit a native saved-peer request. A pending foreground retry is also transferred to native connection work on background transition. Immediate, nontransient failures such as invalid arguments, system connection limits, unsupported operations or exhausted background budget await a later OS state/refresh event instead of creating a fast failure loop.

Scan-only restoration keeps the service-filtered scan and explicitly resumes. A replacement peripheral object for the same UUID is adopted with its delegate. Repeated service invalidation triggers current discovery; callbacks for invalidated service objects are ignored. Post-disconnect diagnostics now record the updated state instead of retaining an obsolete final `connected=true` snapshot.

Phone CCC removal releases the app subscription/session and restarts advertising without erasing the pinned identity or cancelling the shared physical LE link. A new subscription authenticates with the saved key.

Fast authentication, healthy-link refresh, notification cutoff, vehicle command handling and notification layout are retained.

## Installation and observation scope

Android 33 and Watch 45 were installed in place. Without a Watch launch command, a new background process reported `active=false`, `connected=true`, one completed fast authentication and zero errors/discarded fragments. The phone reported authenticated and `watchActive=false`. Immediately after the first installation, authentication measured **226ms on Watch** and **173ms on phone**, excluding discovery and OS waiting.

State after final installation: Build 45 reported a background authenticated link with zero errors/discarded fragments. Two real notifications increased Watch scheduling count by two, with two phone ACKs. This confirms acceptance of notification scheduling, not viewing or vibration. New recovery-branch counters remained zero and do not demonstrate all failure conditions occurred.

Added diagnostics: `backgroundConnectResubmissions`, `scanOnlyRestorations`, `repeatedServiceChanges`, and phone `subscriptionReleases`. A zero counter does not demonstrate that a changed recovery path was exercised. No system logs, administrator password, actual vehicle commands, separate QA scenarios or physical-range requests were used.

## Remaining conditions and OS behavior

This closes app paths that could fail to retain recovery requests. **Unconditional automatic recovery after prolonged passcode lock and actual out-of-range return is not declared complete.** Separate field QA was not run as requested; physical device movement was not performed.

Apple describes resubmitting connection from the out-of-range disconnect callback so the system reconnects when the peripheral returns. Repeated edge-of-range losses can reduce reconnection range, and background scanning shares a limited budget with timely alerts. This code does not remove budget exhaustion, force-quit behavior, power or radio conditions. [Apple: Bluetooth reconnection and limits](https://developer.apple.com/videos/play/wwdc2022/10135/) · [Background tasks](https://developer.apple.com/documentation/watchkit/using-background-tasks).

Location sessions require foreground startup. Background BLE connection after installation is not reported as location-session restoration. [Apple: Background sessions](https://developer.apple.com/documentation/watchkit/enabling-background-sessions).

## Handoff and renewal source

Phone **Settings → Stop connection** was selected. The stopped state recorded `bridgeRunning=false`, `centralPresent=false`, `subscribed=false` and `authenticated=false`. Registration, keys and vehicle settings were retained. Mac wireless debugging is also closed.

The existing once-weekly Mac renewal source is aligned with committed build 45; renewal is not run now. Watch-only free automatic signing remains a separate unfinished goal.
