# Android 0.6.22 — State mismatch and refresh recovery

[한국어](CONNECTION_RESYNC_0.6.22_KO.md) · **English** · [Current status](CURRENT_STATUS_EN.md)

November 20, 2026 KST. Android **0.6.22-local / code 44**. Watch **0.5.28 / build 62**, saved registration/settings, keys and UUIDs are retained.

## Observations and cause scope

The owner reported a connected watch while the phone waited for its registered peer despite refreshing. By the time REA collected files, watch internals were also retrying after authentication failed; simultaneous evidence of the initial conflicting UI is not claimed.

- Phone build 43 was running/advertising without a claimed authenticated peer. It recorded 36 shared LE connection callbacks and three refreshes, but zero service subscriptions, saved-peer authentication requests or rejected writes.
- Watch build 62 retained a physical connection but had zero completed authentications, approximately 14,000 fast-authentication attempts, and repeated service waits. Events recorded successful service/characteristic discovery → authentication write → service wait roughly every second.
- One temporary phone-process restart restored authentication/reads using the same registration and watch process. That was pre-change recovery, not evidence that the code fix itself resolved the stall.

This is consistent with requests not reaching the phone's app GATT service. The exact OS-internal reason/write error cannot be established from existing watch records. Lost registration keys or physical distance are not asserted as the cause.

## Changes

Automatic recovery was also added. With a saved peer and observed shared LE presence, but no claimed/authenticated peer or app ATT requests for 90 seconds, maintenance reopens its own GATT server. Repeated attempts back off to 180/360/720 seconds. Shared LE presence is not peer authentication; healthy authenticated links, recent requests and ordinary waiting without observed presence are excluded. Checks run with existing phone maintenance, so 90 seconds is not a connection-completion guarantee including OS scheduling.

1. **Refresh without an authenticated peer:** Reopen WatchBridge's own GATT server instead of only toggling advertising. No whole-app restart, Stop connection button or unpair is required. Healthy authenticated links retain encrypted soft refresh.
2. **Refresh during read-first authentication:** Preserve a reply from the preceding fifteen seconds rather than erasing the live exchange. Abandoned old replies are not retained indefinitely under this exception.
3. **Phone-session-loss hint:** With a registered peer but no phone authentication, a PULL read may return the existing public `wake`/v1 frame instead of repeated ATT errors. Existing watch code starts fresh-nonce, pinned-key verification and encrypted confirm/ready. The hint authorizes no data or connected state and contains no notification/vehicle data.
4. App-owned diagnostics add `refreshGattReopens`, `automaticGattReopens`, `reauthenticationHints`, `observedGattLinks` and `gattRequestIdleMillis` to distinguish recovery execution and request silence.

## Deployment and limits

Installed in place with the existing Android key/app ID. Post-install records showed phone build 44 authenticated/reading, and unchanged watch build 62 authenticated with read delivery. No watch launch command or registration reset was used.

The final APK including automatic recovery was also installed in place. Final phone state was build 44, authenticated/responsive with zero refreshes; `automaticGattReopens`, `refreshGattReopens` and `reauthenticationHints` were all zero. Unchanged watch build 62 was authenticated/reading. **Execution of the new automatic/manual server-reopen/read-hint branches against the original stalled condition has not been established**. That stall had already cleared during temporary restart. No additional multi-hour lock or repeated-range test was performed.

## REA evidence

| Observation | Evidence ID |
| --- | --- |
| Phone before changes: three refreshes, zero auth requests | `ev_238190d39fe8928ae93e9446ffdc27a46eafe4d046887c087822eb69e0f68b5a` |
| Watch before changes | `ev_c33ba3aafd26690f788946486f6a3a5860ca85e4f13b0f90be5095a6b39a3c66` |
| Approximately one-second watch auth/service retries | `ev_f97b0ff4633fc73ba359ae1cecc7cd78a8200e099c44c40142991aa7d7805366` |
| Recovery after temporary phone-process restart | `ev_7eb0e66f296cab0a745d783bc03de20fed06ce521f6fc3efb65d961f329e77f3` |
| First build-44 sample: authenticated/responsive | `ev_841017b70afa0b42983f737b9252acc11e76623737c4d530678e38342aa24df3` |
| Existing watch authenticated/reading after phone update | `ev_0fe81234f071a657dabad7c4dfb97834924843d57994b51451b34e4728bcc680` |
| Final APK including automatic recovery installed in place | `ev_b6081dcee06a2b6eae4320f359408804c63dfbb78063afa9b2d7797776d94622` |
| Final phone authentication/delivery/recovery counters | `ev_e172fb1b7f75f73916fa7f20659ee09a2f2b6e489f9196ee00d8f279a0f36d03` |
| Final watch authentication/read delivery | `ev_052bff1adbbdfa01b52eaf3d522afd2759f44a9e5ac115cff5f32a2cdae8f11a` |

REA CLI collected app-owned files; watch copying used a separate Apple `devicectl` command through REA `capture-process`. Raw records remain local. No system logs, administrator passwords or vehicle commands were used.
