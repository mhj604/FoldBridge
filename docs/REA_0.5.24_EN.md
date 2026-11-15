# WatchBridge 0.5.24 — read delivery while locked

[한국어](REA_0.5.24_KO.md) · [Earlier REA investigation](REA_0.5.23_EN.md)

2026-11-15. Candidate: Android **0.6.18-local / code 40**, Watch/widget **0.5.24 / build 58**. Android code 40 and Watch build 57 were installed in place, retaining registration, keys and vehicle settings. Build 58 was also installed on 2026-11-16 KST, followed by locked phone-only authentication. [Download APK](https://github.com/mhj604/WatchBridge/releases/download/watchbridge-v0.5.24-build58/WatchBridge-0.6.18.apk).

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


### Build 57 preparation

After installation the owner prepared the location session once and passcode-locked the watch again. The new build-57 process reported actual background state, eligible location activity, authentication and read delivery. Authentication itself took about **147ms on the watch / 121ms on the phone**. This foreground-assisted preparation is not used as evidence for automatic range return.

Native lock Evidence: `ev_44c4ab56b993a5cbc8ac203faa3b459ab4577636dc4b4de81f596e963513b139`. Subsequent background app record: `ev_50f2f1b45355fb1cd07d6066f3e50eef624938500268e4b7a09cf914b910f2f4`.

A second physical departure on this build changed the phone to `centralPresent=false`, `authenticated=false`, and `advertising=true`. Return without opening apps or refreshing is recorded separately. Departure Evidence: `ev_eeacd036d30903708545856c9956b964852f295b1f868b0ee03f0895f450c91b`.


### Build 57 return failed; additional build 58 change

After the second physical return, the phone remained advertising and unauthenticated. The same background/eligible watch process had started recovery discovery but remained native `connecting` after `CBErrorDomain:6`, without another connection callback. **Physical return on build 58 remains unresolved.** Watch Evidence: `ev_80f641ed29a344e6ee2f9982bfd61ecd47545cfebe4736b1625070eed1fd19ed`; phone: `ev_5e5b12d3361ed659e62f27ac8a965b6e1a5d9a2ce060360934c4239dffa6546f`; app events: `ev_83ec845d7a87db99983fca33ed3dfc608641509179c8cdd157304ecb0d47acf5`.

Build 58 no longer suppresses a fresh native request solely because the peripheral object says `connecting` when the disconnect callback did not report an OS-owned reconnect. A real proximity recovery that stays pending for 45 seconds is re-armed once per episode. This cancels/resubmits the stalled pending request while retaining registration; it never cancels a healthy authenticated link merely for silence. Discovery-callback counts were added to app records. This is an implementation change, not evidence of successful physical return.


### Build 58 installation and locked phone-only start

On 2026-11-16 KST, the REA-wrapped Apple install completed successfully. Phone app records first confirmed the owner had stopped its service (`bridgeRunning=false`, no authentication or advertising). After one-time location-session preparation, native state confirmed passcode lock, and watch app records confirmed background/eligible state. Only the phone **Connect watch** button was pressed. Authentication and read delivery completed: **114ms phone / 159ms watch**, measuring authentication rather than total button-to-connection latency.

The installed package has **CFBundleVersion 58**, and the new process exposes the new proximity-rearm fields. The app-owned JSON still contains a hard-coded `build:57` diagnostic value; it must not be treated as proof of a build-57 reinstall. Using actual bundle metadata for this diagnostic is a recorded follow-up item.

Representative Evidence: installation `ev_246507f6d2a640c0d3ad92b4a76841bd2658e4491772953cdbaecffa2f495681`; native lock `ev_798f67e36cabb47d1e63777560a64a9f69b6857370d1ed50285b4c3b38af7b21`; phone start `ev_6f317f0b8092600122ac0ae8cb49ad1de4f27e9030930bff45b2eae97cdbc59f`; watch result `ev_224a62af68a7c82e11b2d93f13ea39e672b4ed31e5ae238e4e999f2244209486`. The Korean report lists phone/service Evidence as well.

The private renewal source was aligned to installed build-58 commit `f33d91e`. No schedule change or signing renewal was run. Physical return and prolonged lock remain separate observations.


### Handoff on 2026-11-16 KST

Work stopped at the owner's request. **Build 58 installation and passcode-locked phone-only authentication/read resumption were recorded. Physical departure/return on build 58 has not been performed.** Multi-hour/overnight lock remains unobserved. Continue these two conditions with registration retained. The failed build-57 return must not be presented as a successful build-58 result.
