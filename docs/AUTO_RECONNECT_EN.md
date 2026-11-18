# Automatic reconnection and remaining conditions

[한국어](AUTO_RECONNECT_KO.md) · **English** · [Current versions/downloads](CURRENT_STATUS_EN.md)

As of 2026-11-18: Android **0.6.19 / 41**, Watch **0.5.26 / 60**. Earlier version outcomes are linked separately below.

## Current behavior

1. Retain registration. Use **Connect watch** when the phone service is off, or **Refresh connection** while it is running. **Sync now** processes pending transfers over an already authenticated connection.
2. Refresh on a healthy link sends an encrypted request without replacing the session. After disconnection, authenticate the saved peer again and discard the old notification queue.
3. The watch uses Core Bluetooth saved-peer connection/restoration and service-filtered recovery discovery after range loss. It can resubmit a native connection request that received no callback.
4. When location keepalive provides runtime and both peers support it, encrypted reads deliver notifications. A polling timer cannot itself wake a suspended app.
5. Phone **Settings → Stop connection** intentionally disables the service. This is not an automatic-recovery state; **Connect watch** starts it again without deleting registration.

## Observation scope

Authentication, read delivery, a display request and phone acknowledgement were recorded during passcode lock in actual background. On November 18, the owner reported automatic reconnection after physical return without the app appearing. Lock state for that return was unspecified.

**Multi-hour/overnight lock, repeated physical range returns, OS process termination, nearby repeated disconnections and recovery delays are not marked complete.** Do not erase registration or repeatedly cancel a healthy session to obtain recovery.

Initial location-session preparation after installation/process replacement is distinct from normal reconnection. Unexpected main-screen display is deferred at the owner's request; current connection behavior is retained.

## Change records

- [0.5.24 read delivery and build 57/58 range recovery](REA_0.5.24_EN.md)
- [0.5.25 charging filter and maintenance launch](QUIET_BACKGROUND_0.5.25_EN.md)
- [0.5.26 display-state records](DISPLAY_INVESTIGATION_0.5.26_EN.md)
- [0.5.8 historical reconnection changes](RELEASE_WATCH_v0.5.8_EN.md), not current installation instructions
