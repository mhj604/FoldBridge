# Watch 0.5.10 / Android 0.6.8: background reconnection candidate

[한국어](WATCH_0.5.10_CANDIDATE_KO.md) · **English**

This is a candidate on `fix/watch-background-reconnect`: Android **0.6.8-local / code 24**, Watch **0.5.10 / build 34**. Updates retain registration, keys, and vehicle button mappings. This is not a claim that every background condition is resolved.

## Observed causes and changes

1. The watch had background runtime but cancelled its connection immediately when the phone's FoldBridge GATT service was temporarily missing. It now retries full service discovery and waits for the service on the existing physical link with 2–30 second backoff. Service changes, matching advertisements, and maintenance callbacks can resume discovery.
2. After a phone process restart, the watch sometimes retained its old crypto session while the phone waited for a new handshake. If a saved peer exists and no handshake starts within 750ms of subscribing, Android sends one authentication restart request. Healthy idle connections receive no periodic wake traffic.
3. Android can restore transport ownership from a bounded fresh `commit` when watchOS retains the indication monitor without rewriting CCC. Saved public-key verification and encrypted confirmation still must succeed. Ordinary data and shared physical connections do not select a peer.
4. Repeated connection failures use 2–30 second backoff. Immediate failure/cancel/retry loops and unnecessary cancellation of already disconnected links are removed. The first disconnect still submits an immediate pending connection, and OS-owned automatic reconnection remains intact. Delayed retries after repeated failures depend on OS-granted runtime.
5. Diagnostics include service waits and the actual connection error. Message bodies and private keys are not logged.

## Device observations and limits

Both updates were installed over the existing apps with the same signing identities on 2026-11-07. The watch app was launched once to initialize the new code, then sent to the watch face. Installation is not evidence of a completely unattended launch.

An initial candidate authenticated in the background, but repeated disconnects also occurred after restarting the phone process. App cancellation and OS disconnect callbacks were distinguished. Unlock-only recovery is therefore not declared completely fixed. Long idle and physical out-of-range/return cases remain separate conditions.

With the final candidate showing the watch face, the phone process was stopped and only the phone app reopened. The same watch process retried discovery, subscription, and handshake approximately every 32 seconds with `active=false`, but disconnect callbacks interrupted authentication. There were no app cancellation or protocol failure records. Background reauthentication after the phone restart did not succeed in this case; these records do not establish the final OS-level disconnect cause. The new retained-subscription Android path had zero observed executions and is not claimed as exercised. No vehicle commands are executed. Raw device logs, identifiers, and signing keys are not published.

## Button labels and cleanup

**Refresh connection** means the phone connection service is enabled. **Connect watch** appears when that service is stopped; the labels describe different states.

At the end of device work, **Settings → Stop connection** stops the actual link while retaining registration. Do not use either app's unregister command. Explicit stop disables automatic connection until **Connect watch** is tapped once on the phone. This differs from normal range loss.

## Unfinished work and next implementation goals — 2026-11-07

All items below are **unfinished**. “Fully resolve” describes the next implementation goal, not an achieved result.

| Priority | Remaining problem | Intended behavior |
| --- | --- | --- |
| 1 | Connections end during authentication while the watch app is in the background | Retain registration and automatically authenticate/connect when the watch is merely unlocked, without launching either app or refreshing. Also recover after restarting the phone service. |
| 2 | Connection maintenance/recovery after a prolonged locked state remains unresolved | Maintain or restore the link and notification delivery when runtime is available during prolonged locking; automatically reconnect after unlocking without opening the app or refreshing. |
| 3 | Automatic recovery after physically leaving and returning to Bluetooth range remains unresolved | Reconnect to the saved peer on return without launching apps, refreshing, or registering again. Resolve repeated disconnects and prolonged authentication stalls. |

After recovery, preserve the existing policy: forward only new notifications posted **after fresh authentication completes**; do not replay the disconnected backlog. Continue with the interrupted-authentication cause first, then resolve prolonged locking and physical range return. Existing evidence does not establish that watchOS runtime limits caused the issue or have been removed.

The installed versions are Android 0.6.8-local / code 24 and Watch 0.5.10 / build 34. At the last session end, registration, keys, and vehicle mappings were retained; only **Settings → Stop connection** on the phone and Mac device connections were stopped. Explicit stop requires **Connect watch** on the phone to enable the service again. Distinguish this from failure to reconnect during ordinary use. Do not unregister or reset either app as a recovery step in the next change.
