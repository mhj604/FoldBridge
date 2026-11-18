# Automatic reconnection and remaining conditions

0.5.28 handles switch completion in failure/disconnect callbacks and rearms only with phone-discovery evidence for the current pending request. [Changes and deployment](RANGE_RECOVERY_0.5.28_EN.md).

[한국어](AUTO_RECONNECT_KO.md) · **English** · [Current versions/downloads](CURRENT_STATUS_EN.md)

As of 2026-11-18: Android **0.6.20 / 42**, Watch **0.5.28 / 62**. Earlier version outcomes are linked separately below.

## Current behavior

1. Retain registration. Use **Connect watch** when the phone service is off, or **Refresh connection** while it is running. **Sync now** processes pending transfers over an already authenticated connection.
2. Refresh on a healthy link sends an encrypted request without replacing the session. After disconnection, authenticate the saved peer again and discard the old notification queue.
3. The watch uses Core Bluetooth saved-peer connection/restoration and service-filtered recovery discovery after range loss. It can resubmit a native connection request that received no callback.
4. When location keepalive provides runtime and both peers support it, encrypted reads deliver notifications. A polling timer cannot itself wake a suspended app.
5. Phone **Settings → Stop connection** intentionally disables the service. This is not an automatic-recovery state; **Connect watch** starts it again without deleting registration.

## Observation scope

Authentication, read delivery, a display request and phone acknowledgement were recorded during passcode lock in actual background. On November 18, the owner reported automatic reconnection after physical return without the app appearing. Lock state for that return was unspecified.

All **three subsequent physical return cycles automatically restored authentication/delivery**; final watch state was actual background. [Per-round REA evidence and collection scope](PHYSICAL_RETURN_2026-11-18_EN.md). Additional multi-hour lock testing was excluded from this session. These results do not guarantee restoration after OS process termination or every future return/environment. Do not erase registration or repeatedly cancel a healthy session to obtain recovery.

Initial location-session preparation after installation/process replacement is distinct from normal reconnection. Unexpected main-screen display is deferred at the owner's request; current connection behavior is retained.

## Directly controlled repeated radio interruptions

During passcode lock, all three Galaxy Bluetooth interruptions of 30, 60 and 90 seconds recovered authentication and delivery without opening the app or refreshing. This differs from physically moving out of range. [Measurement scope and REA evidence](LOCKED_RECOVERY_TEST_2026-11-18_EN.md).

## Change records

- [0.5.24 read delivery and build 57/58 range recovery](REA_0.5.24_EN.md)
- [0.5.25 charging filter and maintenance launch](QUIET_BACKGROUND_0.5.25_EN.md)
- [0.5.26 display-state records](DISPLAY_INVESTIGATION_0.5.26_EN.md)
- [0.5.8 historical reconnection changes](RELEASE_WATCH_v0.5.8_EN.md), not current installation instructions
