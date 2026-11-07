# Watch 0.5.9 / build 33: pending installation

[한국어](WATCH_0.5.9_CANDIDATE_KO.md) · **English**

This branch adds watch background-restoration changes on top of Android 0.6.7. The build completed, but installation on the physical watch is pending because the Mac–watch developer network tunnel times out. Distinguish this candidate from the default branch and the currently installed Watch 0.5.8.

## Changes

- Preserve an already active TX characteristic subscription when restoring in background, and authenticate over it. Avoid disabling the last monitoring source merely to re-enable it. Retain explicit resubscription in foreground.
- Allow stalled-authentication and transfer recovery while the OS is actually executing a connection-keepalive callback. Previously the foreground guard returned before those timeouts despite the callback already running.
- Record actual application state, whether the in-memory identity is available, and foreground/background transitions. These additions do not record keys or message bodies.

This does not remove watchOS runtime/BLE budgets or arbitrarily launch a suspended app. The foreground requirement for initially starting the location session is unchanged. Reliable immediate recovery on unlock has not been established before installing and observing that condition.

See [Reconnection investigation](AUTO_RECONNECT_EN.md) for two observed Android 0.6.7 reconnection cases and remaining conditions. This branch does not execute vehicle commands.
