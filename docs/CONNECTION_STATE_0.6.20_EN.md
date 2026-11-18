# Android 0.6.20 — distinguish retained connection from delivery waiting

[한국어](CONNECTION_STATE_0.6.20_KO.md) · **English** · [Current versions](CURRENT_STATUS_EN.md)

2026-11-18. Android **0.6.20 / code 42**; installed Watch remains **0.5.26 / build 60**. Updated in place with the existing Android key. Registration, BLE UUIDs, crypto context and watch location/display behavior are retained.

## Observed state and source path

REA app-owned records showed authenticated read delivery on both devices. The watch was in actual native/SwiftUI `background`, with no cancellation, failure or disconnection in its current process. The observed passcode state was unlocked, so this is not a multi-hour lock result.

Phone `isConnected()` also returned false after a ten-second read gap, independently of retained BLE authentication. UI and foreground-notification channels used that result as connection presence. A read pause could therefore appear disconnected while BLE remained retained. `connectionStartedAt` was also reset as a notification cutoff when reads resumed; it cannot represent the authentication time or link lifetime. This does not establish the cause of every actual radio disconnect.

## Changes

- Separate delivery readiness from the authenticated BLE link. Show **Connected · waiting for delivery** when only reads have paused.
- Retain the same connected notification channel while the authenticated link remains. Change its text to explain delivery waiting instead of switching connected/waiting channels. Missing link/authentication still uses the waiting channel.
- Record `authenticatedLink`, `deliveryResponsive`, actual `authenticatedAt`, `notificationCutoffAt`, read time/age, read-resumption count and maximum gap, plus native disconnection count/time. No notification content or peer keys are recorded.
- Preserve notification admission during read pauses and old-queue clearing on resumption. A retained-link label does not claim uninterrupted delivery.

## Deployment and remaining scope

The APK compiled and was installed in place through REA. Subsequent app-owned state reported actual build 42 with `authenticatedLink=true` and `deliveryResponsive=true`. Without launching the watch app, the same build 60 process recorded authentication/read delivery in `background`. No new watch installation or location-session preparation was performed.

This is post-update recovery, not completion of multi-hour/overnight lock, repeated physical range return or every radio-disconnection condition. No forced range/lock trial, synthetic notification, vehicle command or system log was used. Investigate actual link loss with native counters and watch disconnect events, and read pauses separately with resumption intervals. Unexpected main-screen display remains deferred.

## Evidence

- Before-update phone: `ev_f520cb5507c11e0aa163f29dc61a9c10bc1089b0b98c9f9aa7db983bfec6e7b9`
- Before-update watch: `ev_167514ecc1f1e57bbd5bc92204a828490fd047099fe4d644839d5f26d7ffb14b`
- Watch app events: `ev_740096527fbcce932c055eb6b3accf71031966f2bd4f5c9020d772d1fc07d220`
- Installation: `ev_931b2b091f834089e025a41c37b56c160eb016e9586984ab47f4c19fd808d402`
- Installed phone build 42: `ev_3e73ddbbfa046060bff368d44c6158c2dc6b897d92c0fbaa9100feb99b2a17aa`
- Watch background after update: `ev_6db5f9536d9147d1d209ffd43e910e6c8d3dfb16a7d6ab7298ecbc4834aadf3c`

Used REA CLI Android functions and Apple devicectl app-file copies wrapped in `capture-process`. Raw device records remain local.
