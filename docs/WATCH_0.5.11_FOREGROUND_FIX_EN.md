# Watch 0.5.11 / build 35: foreground reconnection regression fix

[한국어](WATCH_0.5.11_FOREGROUND_FIX_KO.md) · **English**

Keep Android 0.6.8-local / code 24 and update Watch to 0.5.11 / build 35. Registration, keys, and vehicle settings are retained.

## Why did opening the app become slower?

Version 0.5.10 added `nextConnectAttempt` backoff for repeated failures, but `setActive(true)` did not clear it. Both `reconnect()` and advertisement recovery could remain blocked after opening the watch app. The watch's Refresh connection action did clear that delay before restarting the link. This introduced a code regression between foreground resume and manual refresh; deleting registration is not a remedy.

The actual 0.5.10 records also included an approximately 18-second interval between foreground activation and connection/authentication. These records do not establish the cause of every reported disconnect.

## Changes

- Clear scheduled retries and backoff **before** resuming the saved connection on foreground entry.
- Clear a stale automatic-reconnect flag for an already disconnected peripheral so a saved-peer connection can be submitted again.
- Immediately resume discovery if a connected physical link is waiting for the phone service when the app opens.
- Do not cancel a healthy authenticated link merely because the app opens. Keep backoff for repeated background failures.
- Include remaining retry delay in diagnostics.

This removes the foreground-backoff regression path. Phone-only background recovery, prolonged locking, and physical range loss/return remain [unfinished goals](WATCH_0.5.10_CANDIDATE_EN.md#unfinished-work-and-next-implementation-goals--2026-11-07); they are not declared resolved.

## Installation record

Installed over the existing app on 2026-11-07. The new process reported build 35, an authenticated connection, zero watch refreshes, and zero remaining retry delay. An app launch command was used after installation; this does not establish recovery after prolonged locking or physical range loss/return.
