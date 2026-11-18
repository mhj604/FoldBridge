# Three physical range-loss/return cycles

[한국어](PHYSICAL_RETURN_2026-11-18_KO.md) · **English** · [Current status](CURRENT_STATUS_EN.md)

November 18, 2026 KST. Tested existing Android **0.6.20-local / code 42** and Watch **0.5.28 / build 62** (`f0983e8`). App code, registration, keys and vehicle settings were retained.

## Procedure

The owner left the phone stationary and physically took the watch out of Bluetooth range and returned three times. Instructions were to avoid opening the watch app or pressing either connect/refresh button, and to retain passcode lock in rounds 2/3. The owner reported each return; REA CLI collected app-owned records. Physical movement was not automated.

| Round | Phone native disconnect total | Authentication/read delivery after return |
| --- | --- | --- |
| 1 | 3 → 4 | Automatically restored |
| 2 | 4 → 5 | Automatically restored |
| 3 | 5 → 6 | Automatically restored |

All rounds recorded an actual disconnect increment and new authentication. Final phone state had `authenticatedLink=true`, `deliveryResponsive=true`, `refreshCount=0`, `softRefreshCount=0`, and `pending=0`. Reads continued increasing after recovery.

The final watch lock query reported `passcodeRequired=true`. Final watch state recorded native/SwiftUI `background`, `active=false`, authenticated/connected state, empty `lastError`, `failureCounts={}`, and zero app-requested connection cancellations. Advertisement-based rearm/switch-completion branches were not exercised in these cycles, so full branch coverage is not claimed.

## Collection scope

- Rounds 1/3 recorded disconnected → authenticated/responsive transitions with roughly five-second samples.
- The initial fifteen-minute collector finished before the second disconnect. Newly collected app-owned cumulative counters, last-disconnect/authentication timestamps and current delivery state established round 2 recovery. Continuous sampling of that whole interval is not claimed.
- The physical instant of re-entering Bluetooth range was not measured. Disconnect-to-authentication intervals include time spent away and **are not return-to-connection latency measurements**.
- The earlier [30/60/90-second radio interruptions and ten-minute locked observation](LOCKED_RECOVERY_TEST_2026-11-18_EN.md) are separate conditions from these physical movements.

**All three physical return cycles succeeded.** No failure requiring another connection-code change was reproduced. Additional multi-hour lock testing was excluded from this session at the owner's request. These results do not guarantee every environment/future return or restoration after OS process termination. Unexpected main-screen presentation remains deferred.

## REA evidence

REA collected phone app-owned status files. Watch files were read using a separate Apple `devicectl` copy through REA `capture-process`. No system logs, administrator passwords or vehicle commands were used; raw records remain local.

| Observation | Evidence ID |
| --- | --- |
| Round 1 actual disconnect | `ev_24a9a35d61df6fcb92115600d69802d8d79dd2b8dc10485b6ba1a45e8360faac` |
| Round 1 authentication/delivery recovery | `ev_a29426a482682913fe804834b153fc65a0e2a64d6ed453c94b9b4fdf8a445e5e` |
| Round 2 counter increment/re-authentication/responsive state | `ev_43bca6957601ac53965d985e9744c8b439d34084e044f226fc774dcf5d6a5f48` |
| Round 3 actual disconnect | `ev_e0f501a3235acbc0210a28a7e1740101b00c1dca3bc3843133916e1e1f9ec1fa` |
| Round 3 authentication/delivery recovery | `ev_03941e3e08fe2cddb64131b4e5842fa3165e862a47269f694181838edc1dc713` |
| Final phone state/zero refreshes | `ev_07363caaa9646aca79ff13048e7ba8e5d10f7cf3749c4e97f06f7155ab494c9c` |
| Final watch actual background/authentication | `ev_770fb488cb9b7eaa233fec544c1bb43bdee6e7b873bde2a32fd28280e3bb1e69` |

| Final watch passcode lock | `ev_313bf438010ffb74bf4ba9ba4791632e85d0bf1f64fa252a20f9d838a3f52f54` |
