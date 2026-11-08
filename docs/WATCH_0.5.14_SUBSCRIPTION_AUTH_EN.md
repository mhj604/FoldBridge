# Watch 0.5.14 — start background authentication from phone controls

[한국어](WATCH_0.5.14_SUBSCRIPTION_AUTH_KO.md) · **English**

Branch: `fix/watch-background-reconnect`. Retain Android **0.6.9-local / installation code 28**; apply this connection change to Watch **0.5.14 / build 40** only.

## Problem and change

After restoring original 0.5.12, phone-only **Connect watch / Refresh connection** still led to repeated disconnects at `awaitingBootstrap` while the watch was locked. Opening the watch app allowed authentication. A phone reboot occurred between the successful and failed observations, without establishing direct causation.

Previously the background subscription-completion callback waited for the phone's next bootstrap indication or a two-second app timer before starting authentication. Recorded failures ended the link before that wait completed.

- Submit the first authentication write directly from subscription completion. Do not defer initiation to foreground entry, another bootstrap indication or the two-second timer.
- Duplicate subscription callbacks and late initial bootstrap messages do not replace a nonce for authentication already in flight.
- When restoration retains a `.connecting` peer, register saved-peer discovery once Bluetooth is ready instead of returning with only a delayed app timer.
- If the system already restored a running scan, restore the app routing flag too so its results are handled as saved-peer recovery.
- If an earlier path remains at `awaitingBootstrap`, an executing reconnection path also resumes authentication.

Retain saved-peer pinning, encrypted authentication and explicit Stop connection behavior. Do not erase or recreate registration, keys or vehicle mappings. Processing occurs in the background Bluetooth callback; it does not bring the watch app onscreen. Notification layout and vehicle commands are unchanged.

## Deployment state

- Signed physical-watch build completed.
- Device installation in progress. Successful phone-button-only connection while locked is not declared complete.
- No replacement phone APK is needed; retain Android 0.6.9.
- No system-log collection, vehicle-command execution, extra reboot or physical-range procedure is performed.

The preceding original-app restoration remains documented in the [0.5.12 restoration notes](ROLLBACK_0.5.12_EN.md), separately from this behavioral change.
