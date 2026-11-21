# Watch 0.5.30 — screen reappearance evidence

Watch and vehicle widget **0.5.30 / build 64**; Android remains **0.6.23 / code 45**.

## Observed incident context

REA obtained 256 app-owned display records spanning **2026-11-21 13:06:08–17:54:32 KST**, all from one process. Foreground-entry markers occurred at 13:39:44, 13:53:51, 13:54:11, 13:57:38 and 17:52:26, with the phone connected at each sample. There were no launch, notification-open or vehicle-widget entry markers in this retained interval.

The owner did not remember the incident time. We cannot identify which transition corresponds to the reported symptom or distinguish wrist raise, direct interaction and private OS policy from this evidence alone. Inactive-to-active transitions do not establish a new process launch or a reconnect-induced foreground launch.

Evidence: `ev_a5c7972349c13d5001a0b76849b2f6842951ccd1168e774b0897a5097ecdd624`. REA captured Apple devicectl reading the app container before launching anything. No system logs or private OS launch-reason tracing were used.

## Added observations

- Previous observed native state, SwiftUI phase, monotonic timing, activation-group ID, recent entry signal and age, rendered main/vehicle surface, authentication and location state. A rendered view alone does not prove visual presentation.
- Distinct notification-open and renewal-notification-open markers; widget and legacy quick-control intents; user-activity and remote-now-playing callbacks. No vehicle or audio operation is added.
- Bluetooth restoration and background-task markers. Maintenance and weekly-renewal process launch requests have distinct source tags; a launch tag is not a later foreground cause.
- A 1,024-entry display journal and separate 256-entry activation summary. Repeated authentication and location diagnostics no longer displace the screen-only history; normal connection records remain separate.
- **Report screen issue** at the bottom of the watch main screen pins the current marker, last 80 events and 16 activation summaries. Eight pinned incident reports survive later journal rotation.
- No message body, sender, raw URL/activity payload, vehicle-button content, coordinates or keys are recorded.

App Documents contains `watchbridge-display-events.json`, `watchbridge-display-activations.json` and `watchbridge-display-reports.json`. No telemetry server or diagnostic notifications are introduced.

## Next occurrence and limits

If the app unexpectedly appears, tap **Report screen issue** once and tell us. No remembered timestamp, registration reset, refresh or restart is needed.

Public watchOS callbacks do not disclose wrist raise, Crown selection or every OS restoration reason. Missing attribution remains `not-provided-by-os`. Signals within ten seconds are temporal correlation, not proof of causation. This adds incident evidence; it does not claim to fix reappearance. Bluetooth, location-session behavior, cryptography, registration and settings remain intact.

## Deployment progress

Build 64 installed over the existing app (`ev_2b2de47a859011e325edd4853aa97835599d71a66b59aeef4d134c37c39cab5a`). Its initial `--no-activate` launch was refused because the watch was passcode locked (`ev_fdc48dec82255feddefb0d75c58b380120d331332459343b61c5072fb51cfdda`). Successful installation does not establish that the new process or journal has started. Initial launch awaits unlocking.

## Initial runtime follow-up completed

The post-unlock launch request succeeded (`ev_5d67e60cd0502d68af380ccf61fc7105a791863811867eb2dce575a7f6b7f052`). App-owned state reported **build 64 with authenticated connectivity** (`ev_d8f2fb3a2c7c4f84f3af759a07041fd948380734e02de8670f18d3b8d61c0901`), and **schema 2 display records** were obtained (`ev_b33462bab5d99d274715ef2fee5d766130c2332862e28b76d205b178a4f8741a`).

The new process journal started at 18:10:00 KST with a Bluetooth restoration callback. It also recorded a foreground marker at 18:10:56 and return to background at 18:11:04. Launch source remained `unspecified`; the later Mac launch request is not retroactively attributed as process creation. These transitions do not establish the cause of the owner's reported symptom. Location state in the sampled record was `restore-requested`, not confirmed eligible. The renewal runner's pending-initial-launch flag was cleared while preserving installed-version alignment, weekly source and existing completion receipts.
