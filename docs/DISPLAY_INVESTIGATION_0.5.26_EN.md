# Watch 0.5.26 — display-entry investigation

[한국어](DISPLAY_INVESTIGATION_0.5.26_KO.md)

2026-11-18 KST. Watch/widget 0.5.26 / build 60 improves app-owned display records. Android 0.6.19 / code 41, registration, encryption, location runtime, and BLE authentication/delivery/recovery remain unchanged. The build is complete; deployment is recorded separately below.

## Corrected inference

The owner reported automatic reconnection after physical departure/return **without the app appearing**, and identified the unwanted screen as the main connection/refresh screen rather than vehicle controls. This does not establish 0.5.21 location restoration as the direct cause. A general session-presentation policy is distinct from causality in this reported event. Location-only rollback is no longer the preferred action without additional evidence.

New REA records show authentication and read delivery with `active=false` at 17:31:27–28 KST. The next retained `lifecycle.foreground` is at 17:35:48, about four minutes twenty seconds later. These events do not support immediate foreground activation by authentication. At 17:40:14, the same build-59 process reported actual background, eligible/enabled location runtime and an authenticated connection. Acquisition used REA process capture around Apple devicectl app-file copies, without an app launch or activation command. Evidence IDs appear in the Korean report.

These are app records plus the owner's screen report, not a contemporaneous screen recording or a trace of the OS activation reason. One successful return does not establish all range or prolonged-lock outcomes.

## Observability defect and change

Previously, `setActive(false)` labeled both inactive and background phases `lifecycle.background`. It could not distinguish wrist-lowering/inactivity from leaving the app. GATT retries could also evict display events from the general 128-event ring.

Build 60 records distinct SwiftUI active/inactive/background phases with native app state, renames the ambiguous event to `lifecycle.nonactive`, and keeps a separate 256-event `watchbridge-display-events.json`. Fixed entry markers distinguish notification response, in-app vehicle panel, widget panel and legacy quick-control Intent. The journal includes app start, authentication and location eligibility changes, but no notification text, sender, vehicle button or coordinates.

This is an observability change, not a claimed automatic-display fix. Public callbacks do not expose every external wrist/Crown/OS activation reason; unknowns must remain unknown. A view's onAppear alone is not proof of visible presentation. Interpret background→active separately from inactive→active and use explicit entry markers when present.

The working location/read-delivery/range-recovery behavior was retained. No diagnostic notifications, vehicle commands, system logs, administrator authentication, forced range/lock experiment or QA/test run was performed. The precise unwanted main-screen entry remains unresolved.


## Deployment

Build 60 was installed in place (`ev_5b2ab52ba8f3be95bb2f8c599718085b524c9e7c80a0a1b76ac450c5db74c718`). The subsequent `--no-activate` launch request succeeded (`ev_c58b2d9469a9a92b7f87fbb8254101f9bb489fd473114363f8bf3f460b8a8572`). Command success is not proof of actual screen state or resolution of automatic presentation.
