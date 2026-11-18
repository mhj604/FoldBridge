# Watch 0.5.28 — locked recovery callbacks and physical return

[한국어](RANGE_RECOVERY_0.5.28_KO.md) · **English** · [Current status](CURRENT_STATUS_EN.md)

2026-11-18. Watch app/widget **0.5.28 / build 62**, Android **0.6.20 / code 42**. Retain registration, keys, UUIDs, location activity and display policy. Unsolicited presentation stays deferred pending everyday-use observations.

## Observations and cause scope

REA app-owned records before this change showed an authenticated watch reading in actual background with no cancellation/failure. The phone reported an authenticated responsive link, with native disconnections and read-resumption gaps at zero. This nearby observation does not establish reliable prolonged lock or every range return.

Earlier REA events show a range timeout at 17:30:05 KST, pending-request cancellation at 17:31:02, phone discovery at 17:31:26 and authentication/read recovery at 17:31:27–28. Elapsed time could cancel a request before an advertisement had been observed. These timestamps do not establish the exact physical return time or internal watchOS cause.

Source inspection found three recovery gaps:

- Switching cleared the current peripheral before cancellation. Disconnect callbacks completed the switch, but a failure callback could return at the current-peripheral guard, leaving only the three-second app fallback.
- Discovery of the same phone returned immediately while its existing object was `connecting`. That background callback could be the only execution opportunity before the next location/maintenance timer.
- A failed one-shot rearm could prevent further recovery until authentication succeeded.

These are source gaps addressed alongside observed pending-connection patterns, not proof that every current-device failure has the same cause.

## Changes

1. Both failure and disconnect callbacks match the switching peer UUID and submit the next native request in that callback. Keep the existing three-second fallback for missing/delayed completion.
2. Rearm only an unauthenticated request stuck `connecting` for at least 45 seconds during proximity recovery, with **phone discovery since that pending request began**. Do not apply to a healthy link or cancel solely because time passed without discovery.
3. Process recovery directly from the matching discovery callback. Keep its evidence when background discovery coalesces duplicates; a second immediate advertisement is not required.
4. Allow another rearm after failure only with discovery since the new request and a 60-second interval. Successful authentication clears recovery state for the next range departure.
5. On Core Bluetooth restoration, request stalled-stage repair as well as saved-peer recovery. Record completion type and discovery age separately.

This does not make watchOS execute a suspended timer. Native connection and filtered discovery remain pending; actual callbacks/execution opportunities drive recovery. Location behavior, delivery mode, vehicle commands and notification-backlog policy stay unchanged.

## Deployment and remaining scope

Build/signing and in-place installation of final build 62 completed. Installation Evidence: `ev_710cdca5c173be31a16e00c08a69cbad5d4feb99e76751a85d238c307afb3fd4`. The no-activation launch and app-owned state are recorded in follow-up below.

Multi-hour/overnight lock and repeated physical range-return conditions are not marked complete. No forced lock/range trial, synthetic notification, vehicle command or system log was used. Investigate actual radio loss from both peers' disconnect records, separately from read-runtime gaps in Android 0.6.20.

Before-change Evidence: watch `ev_d5d613706cd679a8bb36bb5d1852835a0ca2f8cc2aba935465e1412d847a1e2d`, phone `ev_3f87a05fc14b3c8d023f91b6dd1dcbcdd42361e021c98d5f7aa05b180950757b`. Earlier range events: `ev_048ac71e32cf4ca1bdaa4c5a140fe6477972f0f2704d6f819f8ca8a8276f80c0`. Used REA CLI and Apple devicectl app-file copies wrapped by `capture-process`; raw records remain local.


## App-owned state after installation

The `--no-activate` launch succeeded (`ev_09d7cb707a95778718108a2849136c09d8dcd3d6178634d1b4cfe138e996d32d`). Actual state reported build 62, native/SwiftUI `background`, authenticated read delivery, zero cancellations and no failures (`ev_ec4bbf87317a33fde9b4b87e28924d8621e440dab1548d6b52a02e371fc1afb2`). Phone code 42 reported an authenticated responsive link (`ev_6bb0dc1a70708beac4fb68e4f4dd1bd12a9b5dd338a40c2f9f6c0b7d399de8a8`). Location was `restore-requested`; this sample does not establish `eligible`. The new recovery branches did not execute during this nearby installation-recovery interval.
