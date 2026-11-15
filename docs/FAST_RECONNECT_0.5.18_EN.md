# Android 0.6.14 / Watch 0.5.18 — automatic recovery and fast authentication

[한국어](FAST_RECONNECT_0.5.18_KO.md) · [Documentation](README.md)

Android **0.6.14-local / code 32** and Watch/widget **0.5.18 / build 44** were installed in place on 2026-11-15. Registration, identity and peer keys, and vehicle settings are retained. [Download APK](https://github.com/mhj604/FoldBridge/releases/download/connection-v0.5.18/FoldBridge-Local-0.6.14.apk).

## Execution-state correction (2026-11-15)

`active=false` means the app was not active. The accompanying `applicationState=1` is SDK `inactive`, not `background=2`, and does not prove passcode lock. Read background-success wording below as **authentication completed while inactive without a Watch app launch command**. It is not evidence of prolonged-lock or actual range-return completion.

## Delay paths and changes

Previous Watch events showed service discovery approximately every 31 seconds while the phone service was absent. Version 0.5.17 retained the native pending connection but delayed supplementary background scanning by 30 seconds and limited scan restarts to once per 30 minutes. This reduced opportunities to discover a returning service promptly. A prior authenticated state also retained `recoveryScanning=true`. The session at the start of this task was already connected, so these findings do not establish one cause for every reported disconnect.

Version 0.5.18:

- Retains the native automatic reconnect request and the same peripheral; immediately resubmits from background disconnect callbacks without adding repeated cancellations.
- Keeps one service-filtered recovery scan through connection, discovery and authentication. Removes the 30-second/30-minute gates and stops scanning after successful authentication. Callbacks do not repeatedly stop/restart the scan.
- Retries absent service discovery after 1, 2, 4 and 8 seconds, capped at 8 seconds thereafter. A supplementary pending-connection scan is requested after 3 seconds; an existing scan is retained.
- Ignores late duplicate discovery callbacks outside discovery stages. Separates the outstanding ATT write callback from a new session's send queue during same-link reauthentication.
- Uses fast authentication for pinned peers; initial code-comparison registration is unchanged.

The scan restrictions in the 0.5.17 notes are historical. Healthy-link refresh, notification cutoff, vehicle controls and notification layout are retained.

## Fast saved-peer authentication

The existing pinned P-256 identities and fresh nonces prove both peers. Public-key reveal fragmentation is skipped, reducing authentication messages before `ready` from six to three. The phone authenticates only after encrypted Watch confirmation. Failure with an older phone falls back to commit/reveal. [Protocol derivation and messages](PROTOCOL_EN.md#fast-saved-peer-authentication-android-0614--watch-0518).

## Actual app state after installation

Both installations succeeded. **No Watch app launch command was sent during this task.** The new Watch process reported build 44, `active=false`, `connected=true`, one fast authentication attempt/completion, zero app cancellations, no errors and `recoveryScanning=false`. Phone build 32 reported authenticated, `watchActive=false`, and one completed fast authentication. Approximately three minutes after phone authentication, its state still reported authenticated with `disconnectCount=0`.

The authentication phase measured **2,362ms on Watch** and **3,002ms on Android**. The apps use different measurement start points; these exclude discovery and OS waiting and do not measure total reconnection time. No overall speedup ratio over older releases is claimed.

This background relaunch reported `continuousRequested=false`. Location keepalive restoration is not claimed: this result used BLE restoration. Location-session startup requires foreground execution, and the Watch app was not opened to start it. Saved settings were not erased.

No system logs, administrator authentication, real vehicle commands or separate QA scenarios were used. Evidence is limited to app-owned state; notification content, keys and device identifiers are not published.

## Remaining conditions

Prolonged lock, process suspension/relaunch, real out-of-range return and all causes of error-free disconnects still need observation. Physical proximity cannot eliminate OS scheduling, radio or power-related disconnections. A successful short observation is not proof of indefinite connectivity.

Watch-only free signing renewal remains a separate unfinished goal. The existing once-weekly Mac fallback is aligned with this build's committed source and profiles. Earliest expiry is **2026-11-20 17:10:54 KST**; this build did not extend validity by seven days.

## Handoff

After the user selected phone **Settings → Stop connection**, app state reported `bridgeRunning=false`, `centralPresent=false`, `subscribed=false`, `authenticated=false`, and stopped status. The actual Galaxy–Watch transport is stopped; registration, keys and vehicle settings are retained. Mac diagnostic connections are also closed.
