# Android 0.6.11 / Watch 0.5.15 — reduce reconnection latency

[한국어](FAST_RECONNECT_0.5.15_KO.md) · **English**

Branch: `fix/watch-background-reconnect`. Android **0.6.11-local / code 29**, Watch **0.5.15 / build 41**. [APK](../artifacts/android/FoldBridge-Local-0.6.11.apk).

## Observed delay and changes

On 0.5.14, the passcode-locked watch reauthenticated through phone-only interaction, and the user confirmed connection. Device lock state was `passcodeRequired=true` and authentication events remained `active=false`. Authentication completed about 20 seconds after the phone service reappeared, or 13 seconds after subscription. Phone records include a service restart and one refresh; this is not a measured single-button-click latency.

An ordinary refresh `wake` arrived during authentication and discarded the ongoing exchange for a new nonce. Watch 0.5.15 coalesces that request while authentication is making progress. Refresh can still restart an exchange with no valid authentication progress for 15 seconds. This threshold is evaluated upon reception, not an added waiting timer.

Once the phone receives the first client authentication request, discard queued obsolete bootstrap/wake fragments and proceed to the authentication reply. Retain any ATT indication already in flight until its completion callback, so the following reply is not lost. Keep the normal authentication exchange, saved-peer pinning and encryption. Do not uninstall, unregister or reset vehicle settings.

## Deployment state

Both apps were installed on November 13, 2026. Device records show Android 0.6.11 / code 29 and watch build 41. Registration, keys and vehicle settings were retained.

After the phone update, the service-reappearance event at **17:31:18 KST** preceded authenticated state at **17:31:25** by about **7 seconds**. The first authentication write at **17:31:24** preceded completion by about **1 second**. Those watch events remained `active=false`, and device passcode lock was also read afterward. Phone outgoing frames/messages and pending alerts were zero, with no recorded error.

The preceding 20-second case and this 7-second case are not same-condition repeated averages. This case used post-update service restoration and a retained BLE link; a Mac no-activation launch command was also used during installation preparation. It does not guarantee a seven-second connection, one-second authentication, or all OS-initiated relaunches after full termination.

The new process did not yet have the location keepalive session running. A one-time foreground setup after updating was requested to resume the saved preference; that setup result is pending. This is distinct from requiring app entry for every normal connection.

No system logs, vehicle commands, extra reboot or physical-range procedure are used. Scheduled signing renewal is not re-enabled. The expired-signing app-entry recovery remains in the [0.5.14 notes](WATCH_0.5.14_SUBSCRIPTION_AUTH_EN.md).
