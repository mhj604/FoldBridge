# Changelog

[한국어](CHANGELOG.md) · **English** · [Documentation](docs/README.md)

The previous documentation update paired current setup, FAQ, build, architecture, protocol, display-scope, history, and contribution guides in Korean and English. That remains a past documentation entry; newer app changes are recorded below.

## Watch 0.5.1 · build 25 (Android 0.6.0 unchanged)

- Add a WidgetKit vehicle-control extension for Smart Stack and watch faces. Rectangular widgets show Start, Stop, Lock and Unlock; small complications show one selected control.
- A tap automatically foregrounds the app, obtains a fresh catalogue over its existing BLE connection, and dispatches the assigned action once.
- Assign official actions once in watch Quick control settings. A 15-second connection/catalogue timeout cancels the tap without delayed execution or automatic command resend.
- No App Group capability or separate widget BLE session is required. [Widget setup](docs/VEHICLE_CONTROL_EN.md#smart-stack-widget-and-watch-face-buttons-watch-051--build-25)

## Watch 0.5.0 · build 24 / Android 0.6.0-local · code 16

- Add FoldBridge watch vehicle controls and owner-authorized hosting of the official Korean MyHyundai widget on Galaxy.
- Expose selected labelled widget controls over the existing authenticated, encrypted BLE link.
- Suppress duplicate request IDs, require the current catalogue revision, and never automatically retry commands after a timeout. Distinguish widget invocation from vehicle success.
- The original MyHyundai watch app remains iPhone-bound. No vehicle command was executed. [Setup and scope](docs/VEHICLE_CONTROL_EN.md)

## Watch 0.4.9 · build 23 / Android 0.5.4-local · code 15

- Initial registration and every reconnection forward only notifications posted after authentication completes; pre-connection and offline items are not replayed.
- Retry current-session items in memory only; clear them on disconnect and remove the previous disk outbox. Drop the watch's unscheduled old-session receipts and stale display callbacks.
- Stop Android advertising when connected and resume it after disconnect without recreating GATT for advertising retries.
- Retain service-filtered recovery scanning without foreground gating or a 20-second expiry. Background disconnect callbacks submit native reconnect requests immediately; disconnected cached peripherals no longer block recovery.
- Healthy refresh preserves the session and notification layout is unchanged. [Release details](docs/RELEASE_WATCH_v0.4.9_EN.md)

## Watch 0.4.7 · build 21 / Android 0.5.2-local · code 13

- Healthy one-sided refresh sends an encrypted update/sync request and retains the link/session.
- Remove generated periodic ping and short disconnect deadlines based only on background wall-clock silence.
- Improve saved-link restoration, explicit CCC re-subscription, fresh-nonce in-place authentication, MTU recovery, and separation of old ATT completion callbacks.
- Preserve healthy crypto sessions while rebinding characteristics after shared Android GATT service changes. Back off repeated physical disconnects.
- Keep missing notification ACKs in the pending outbox instead of cancelling a healthy BLE link.
- Retain text/source-icon positions and reduce only lower card spacing by 4pt.
- [Current release details and bounded device observations](docs/RELEASE_WATCH_v0.4.7_EN.md)

## Watch 0.4.8 · build 22 / Android 0.5.3-local · code 14

- Clear notifications queued before the first successful watch registration and persist an encrypted registration-time cutoff. Active-notification replay after process restart cannot re-enqueue older items.
- Preserve the pending queue when recovering an already registered peer.
- Enable Core Bluetooth's automatic reconnect option for saved peers. Keep the same peripheral object while the OS owns a reconnect attempt, so foreground maintenance does not replace it.
- After reconnection, rediscover GATT and authenticate with fresh nonces. Android advertising and existing retry/scan recovery remain available.
- Range loss, interference, power, and OS scheduling can still interrupt or delay a link. Automatic recovery is requested, not guaranteed to be immediate.
- [Release details](docs/RELEASE_WATCH_v0.4.8_EN.md)

## Watch 0.4.6 · build 17 / Android 0.5.1-local · code 11

- Move the small source icon and text down together by 3pt, retaining size and spacing.
- Add one-sided reconnect requests while retaining the phone's GATT service.
- Add service-change, connection/authentication-stall, and response-stall recovery. Periodic ping/short deadlines introduced here were superseded by 0.4.7/0.5.2.
- Avoid treating incoming long-message fragments as stalled responses; update Korean/English UI guidance.

## Watch 0.4.5 · build 16

- Adjust the base font to 16pt using same-content simulator comparisons.
- Move the 24pt icon into an overlay so it no longer increases title-row height.
- Use zero extra paragraph gap, adjusted 18.5pt body line height on watchOS 26+, and a 16pt left baseline.
- Correct the watchOS 27 content start by −16pt while retaining the icon outline. System template and line-wrap differences remain. Android stays at 0.5.0.

## Watch 0.4.4 · build 15

- Keep the 24pt expanded-body icon, widen content to a 16pt horizontal baseline, reduce paragraph spacing, and remove extra vertical padding.

## Watch 0.4.3 · build 14

- Use bounded-width custom expanded content only when a source icon is available.
- Keep a 24pt icon in the body and use system text content when unavailable.
- Do not use photo attachments; system popup/card icons remain FoldBridge.

## Watch 0.4.2 · build 13

- Remove source icons as media attachments after oversized previews/reused thumbnails.
- Preserve old delivered notifications; changes apply to new deliveries.

## Watch 0.4.1 · build 12

- Restore system text layout by removing the earlier custom notification scene.
- Try source icons as standard image attachments, with text fallback. This attachment path was removed in 0.4.2.

## Android 0.5.0 / Watch 0.4.0 · build 11

- Add System default / Korean / English settings independently on both devices.
- Generate Android/watch resources from a shared English catalog. Preserve received content in its original language.

## Android 0.4.0 / Watch 0.3.0 · build 10

- Add Refresh connection while retaining registration and pending items.
- Separate stale GATT-server callbacks from new sessions; avoid duplicate connection/subscription authentication starts.
- Improve retry/error clearing, visually center the FoldBridge icon, and publish Korean setup/contribution guides on `local-ble`.

## Android 0.3.2 / Watch 0.2.4

- Center the icon geometry on its canvas.

## Android 0.3.1 / Watch 0.2.2–0.2.3

- Improve recovery after restart/update/Bluetooth changes and saved-peer rediscovery.
- Refine watch notification text alignment and spacing.

## Android 0.3.0 / Watch 0.2.0–0.2.1

- Transfer encrypted source app icons and simplify app UI.
- Remove the watch's separate notification inbox/body storage; keep Notification Center and duplicate-receipt hashes.
- Document per-app sensitive-notification-content settings.

Earlier notification-access diagnosis, charging-update filtering, the move from the original APNs design to Local BLE, and installation history are summarized in [Development history](docs/DEVELOPMENT_HISTORY_EN.md). Original detailed Korean notes remain available through the language switch.
