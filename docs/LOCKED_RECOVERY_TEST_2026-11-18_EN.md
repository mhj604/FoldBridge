# Repeated radio recovery during passcode lock — November 18, 2026

[한국어](LOCKED_RECOVERY_TEST_2026-11-18_KO.md) · **English** · [Current status](CURRENT_STATUS_EN.md)

Tested installed Android **0.6.20-local / code 42** and Watch **0.5.28 / build 62** (`f0983e8`). No application code was changed in this session.

## Directly controlled conditions and results

After the owner passcode-locked the watch, REA CLI disabled and re-enabled Galaxy Bluetooth. Registration was retained. Neither the watch app nor either device's refresh/connect button was used. An actual authenticated-link loss was observed in every cycle before restoring the radio.

| Bluetooth interruption | Automatic authentication/delivery recovery | Enable request to first responsive sample | Phone native disconnect total |
| --- | --- | --- | --- |
| 30 seconds | Recovered | About 11 seconds | 0 → 1 |
| 60 seconds | Recovered | About 5 seconds | 1 → 2 |
| 90 seconds | Recovered | About 10 seconds | 2 → 3 |

Times include approximately five-second polling and tool overhead. They are not precise connection-completion timestamps or guaranteed latency.

- Watch-owned state recorded actual background execution and authenticated recovery. During the 60/90-second interruptions, elapsed time without advertisements caused zero connection cancellations.
- After the final recovery, one explicitly labeled test notification was posted. Phone forwarding and acknowledgement each increased by one, with zero pending afterward. Watch received/scheduled counters each increased from 2771 to 2772. This establishes delivery and an OS presentation request, not visual confirmation of a popup on the passcode-locked screen.
- Bluetooth was restored after every cycle. Registration and vehicle settings were retained.

## Continuous locked observation

All **21 samples at 30-second intervals over ten minutes (600.89 seconds)** retained authenticated-link and delivery-responsive state. The phone native disconnect total stayed at 3, reads increased from 1732 to 2147, the ten-second read-resume-gap counter stayed at zero, and the final pending queue was empty.

A mid-observation watch lock query again reported `passcodeRequired=true`. The final watch event-file copy failed because the Mac–Watch development tunnel timed out. The result therefore relies on continuous phone authentication/read records and previously collected watch background records; it does not claim a complete final watch-event cross-check. Phone BLE delivery remained responsive during the development-tunnel failure.

## Remaining scope

All three cycles recovered without opening the watch app. Disabling Bluetooth differs from physically moving out of range. **Multi-hour/overnight lock, repeated physical range returns, and restoration after OS process termination** are not established by these results.

`proximityRearms` and connection cancellation counters remained zero during these cycles. Native reconnection succeeded, so the tests do not establish execution coverage of every 0.5.28 switch-completion/rearm branch. Unexpected main-screen presentation remains deferred.

## REA evidence

REA CLI controlled the Galaxy and collected app-owned files. Watch files and lock state were read by a separate Apple `devicectl` command through REA `capture-process`; REA did not directly operate the watch. Raw evidence stays local, without publishing notification contents or device identifiers.

| Observation | Evidence ID |
| --- | --- |
| Initial watch passcode lock | `ev_66c945363988bd25e391370d8234ff25e22aa29baef1590671a98d905d47c48b` |
| First responsive sample after 30-second interruption | `ev_10891f7ef50fbf78950fc0d5f2d609735309807bc7d7a3c9196e71ce288847b4` |
| First responsive sample after 60-second interruption | `ev_ce59968677dc3d9affddf14a7e9f77c3ad99c3aa1785de398d2b6ab98f0c84ba` |
| First responsive sample after 90-second interruption | `ev_f2f54b08d8dbf372af86dd4931afc40825e8afde4678f1e1581f553a70dd717d` |
| Watch state about 75 seconds into interruption | `ev_b302f09b4c492ae8d1d9ac7e1cb1ff92a0b55a5bf4eab9b706f84d8be2c97a1d` |
| Watch background authentication after final recovery | `ev_c9605558a7c407d8b7a34ff08cbe962ec034cc567b5d8ea026cbcde3b50ad699` |
| Phone forwarding/acknowledgement after test notification | `ev_92cfee70bc6a559493fdb7d9a79d0d15cc6e936f8a950c03a6a8ef49fdd6fb08` |

| Additional observation | Evidence ID |
| --- | --- |
| Watch receipt/presentation request after test notification | `ev_6b8db1654910aa16ef678d922f5dae0ecf096c749561b92627ddb9810d0589e9` |
| Mid-observation passcode lock | `ev_cce19099a7262bd22e80435fa98091ccf39e130e84cbd97bd250281ad67a1c58` |
| First ten-minute observation sample | `ev_01824d2a4b270567a018ef8305239e1266b08675e3ea9d7f95f3bec9c7d3fd39` |
| Last ten-minute observation sample | `ev_0277f17a1fc5d4a9254e1b6aec6d07b9793d7156d8bbb6a94cbe82aadaa8fcc1` |
| Final watch-file copy failure | `ev_ae8cc55a6b3c94484c835c35cfcbda441d81e9a8ffe4101f030d0956243a320d` |
