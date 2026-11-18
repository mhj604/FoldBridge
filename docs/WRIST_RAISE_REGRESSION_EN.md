# Wrist-raise presentation — change-history investigation

> Historical version-specific investigation/change record. “Current/complete/unresolved” refers to that snapshot, not the latest installation instructions. [Current versions and work status](CURRENT_STATUS_EN.md).

> Follow-up correction: automatic return/reconnection without app presentation and new REA records do not establish location restoration as the cause. Rollback is not the preferred action without evidence. [Current investigation](DISPLAY_INVESTIGATION_0.5.26_EN.md).


[한국어](WRIST_RAISE_REGRESSION_KO.md)

2026-11-18 KST. Installed Android 0.6.19 / code 41 and Watch/widget 0.5.25 / build 59 remain unchanged. This was an investigation of existing source, app-owned records and Apple documentation. The owner's stopped service and saved registration were retained; no device reconnection or new deployment was performed.

## Most likely change

The strongest candidate is **Watch 0.5.21 / build 47, commit `1087ab9` on November 15**. It replaced foreground-started `CLLocationManager.startUpdatingLocation()` with a retained `CLBackgroundActivitySession` plus `CLLocationUpdate.liveUpdates()`, and added immediate activity rejoining on app launch. The intended benefit was preserving location runtime after relaunch. More persistent runtime can also keep session-related presentation relevant for longer.

The activity class first appeared in `a3f245d` on November 8, was reverted in `bb7751b` that day, then reintroduced with the new live-update implementation in `1087ab9`. Background location capability predates the November 15 change; its plist diff changed version numbers only.

This is a leading hypothesis, not a demonstrated single triggering event. Both old and new implementations support continuous background location, so changing the API alone cannot be assumed to eliminate presentation. Previously acquired build-44 and build-46 app-state samples reported `continuousRequested=false`; current REA build-59 samples report an eligible, enabled location activity. The old samples do not establish the state at all prior times and were not newly acquired through REA in this investigation.

On November 17, build 59 reported actual background; on November 18, it reported inactive with the same process identifier. A new process launch is therefore unnecessary to explain the sampled transition. This does not trace the exact watchOS event that brought it onscreen. REA Evidence IDs and acquisition limitations are in the Korean report.

Other paths were separated: post-install/renewal launching already uses `--no-activate` since `0a29976`; user-triggered vehicle widget opening was not newly added in this period. Auto-Select Focused App is a separate route and disabling it does not establish a wrist-raise fix.

## Concrete remedies considered

| Candidate | Scope and limitation |
| --- | --- |
| Restore only the pre-0.5.21 location implementation | Keep current authentication, read delivery, range recovery, notification filters and registration format. This isolates the location-lifetime change instead of rolling back the entire app. The old implementation also uses background location, so presentation may persist and relaunch recovery may weaken. It is a candidate, not a completed fix. |
| Remove location dependence and use native Bluetooth background events | Requires redesigning the current two-second read-polling delivery, which cannot run while suspended. Native subscriptions/background tasks have a shared five-opportunity rolling 24-hour budget for scans/timely alerts. This is not an established unlimited immediate-delivery substitute. |
| Keep runtime but suppress session presentation | Custom/Always is already set and Return to App is absent on this device. `showsBackgroundLocationIndicator` is unavailable on watchOS in the current SDK. An Always On toggle or obsolete frontmost-timeout setter does not solve wrist-raise restoration. Terminating the session/process would conflict with the connection goal. |

The narrowest implementation candidate is a location-only rollback, not a full app downgrade. No candidate was installed or made the default during this investigation. No QA, forced disconnect/range experiment, system logs, administrator authentication or vehicle commands were used. Simultaneously preserving connection reliability and preventing automatic session presentation remains unresolved.

References: [background sessions](https://developer.apple.com/documentation/watchkit/enabling-background-sessions), [location activity](https://developer.apple.com/documentation/corelocation/clbackgroundactivitysession-3mzv3), [background location and relaunch](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background), [Bluetooth background tasks and budget](https://developer.apple.com/documentation/watchkit/using-background-tasks).
