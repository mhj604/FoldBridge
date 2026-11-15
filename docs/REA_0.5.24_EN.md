# WatchBridge 0.5.24 — read delivery while locked

[한국어](REA_0.5.24_KO.md) · [Earlier REA investigation](REA_0.5.23_EN.md)

2026-11-15. Candidate: Android **0.6.18-local / code 40**, Watch/widget **0.5.24 / build 57**. Both were installed in place, retaining registration, keys and vehicle settings. [Download APK](https://github.com/mhj604/WatchBridge/releases/download/watchbridge-v0.5.24/WatchBridge-0.6.18.apk).

## Narrowing the failure

With build 55, native device state confirmed passcode lock before only the phone's **Connect watch** button was pressed. Authentication/subscription completed without opening the watch app. Authentication itself took approximately 104ms on the phone and 161ms on the watch; this is not discovery-to-connection latency.

An idle link remained up for more than two minutes. Sending one diagnostic notification then triggered native nil-error disconnection and reauthentication before the watch's receipt/display counters increased. The phone recorded forwarding but no acknowledgement. This isolated a failure condition in the **incoming indication delivery path**, beyond copy or authentication speed. It does not establish a specific watchOS internal bug or exhausted budget.

## Read delivery

After saved-peer fast authentication, supporting peers negotiate **read delivery** inside encrypted messages when watch location keepalive is requested. The watch reads existing encrypted frames from an additional characteristic instead of subscribing to TX indications for notification content.

Available frames are drained immediately; an empty value schedules another app read about two seconds later while runtime is available. Existing source icons, framing, assembly, cryptographic validation and per-notification acknowledgements remain. Vehicle catalogues/results use the same transport. Existing UUIDs and keys remain unchanged; one read characteristic is added. Initial new registration and older peers retain indications. [Protocol details](PROTOCOL_EN.md#0524--android-0618-read-delivery).

In read mode, the phone's connected indicator additionally requires a read in the past ten seconds. Runtime stalls show a waiting-for-response state; resumed reads discard old pending messages/frames rather than replaying a backlog. A new authentication also clears the old queue. Phone refresh supports this mode and preserves registration.

## Observations

After one-time preparation of read-delivery build 56, the watch was passcode-locked again. Native state showed `passcodeRequired=true`; app state showed **`applicationState=2 / background`**, with eligible location activity. This is distinguished from earlier inactive-state records.

Both peers used read delivery. One diagnostic notification arrived in **29 frames** and completed the watch notification-display request. Watch receipt/scheduling counters increased **2448 → 2449**; the phone's acknowledgement increased **0 → 1**, with **0 pending**. The same authenticated session remained, with no observed disconnection, app cancellation, discarded frames or verification failure in that interval. A nearby idle result is not treated as proof for every prolonged-lock or physical-return condition.

Representative REA Evidence IDs appear in the [Korean report](REA_0.5.24_KO.md#실제-관측). REA's Android operations and `capture-process` around Apple `devicectl` were used. No system logs, administrator passwords, registration resets or vehicle commands were used. Full raw Evidence remains private because it contains device identifiers and local paths.

## Conditions and remaining scope

The polling timer cannot create watchOS runtime. It depends on runtime actually granted by the user-enabled location keepalive, with additional battery use. It does not promise delivery through every process termination, suspension or denied-runtime condition. [Apple background execution documentation](https://developer.apple.com/documentation/watchkit/using-background-tasks).

Physical departure/return and longer locked observations are recorded separately. Multi-hour/overnight lock and OS process termination are not marked solved. An explicitly stopped phone service is not an automatic-reconnection case. At handoff, preserve registration and stop only the actual connection as requested.

## Physical departure found an additional recovery gap

The user carried the passcode-locked watch out of range. Phone records transitioned from waiting for watch response to `centralPresent=false`, `authenticated=false`, and advertising again. After return the watch remained in actual background with eligible location activity and native `connecting`, without a new authentication. Idle continuity therefore did not establish successful range return.

Build 54's scan suppression also blocked this real-timeout recovery path. Build 57 permits one service-filtered discovery monitor per recovery episode after a real connection timeout/disconnection or restoration of a pending connection, while retaining the native pending request. It does not restore repeated scan restarts for nil-error indication losses. A newly discovered peripheral still must authenticate with the saved peer key; registration is retained.

The previous records do not prove that the phone's advertising address changed. The established gap is that recovery discovery was blocked while the phone was advertising and the watch kept only the old pending connection. Build 57 installation/observation results are added below.
