# Changelog

[한국어](CHANGELOG.md) · **English** · [Documentation](docs/README.md)

The previous documentation update paired current setup, FAQ, build, architecture, protocol, display-scope, history, and contribution guides in Korean and English. That remains a past documentation entry; newer app changes are recorded below.

## Watch 0.5.14 · build 40 (retain Android 0.6.9)

Start authentication writes immediately from subscription completion instead of waiting for bootstrap or an app timer. Retain in-flight authentication on duplicate callbacks, and register native recovery discovery for restored pending connections. [Changes and deployment state](docs/WATCH_0.5.14_SUBSCRIPTION_AUTH_EN.md).

On November 13, expired development signing was found in the preceding installation artifacts, and build 40 was rebuilt with fresh signing and installed in place under the same app ID/team. The renewal schedule was not re-enabled; direct app-entry feedback and locked-state phone-only connection are not marked complete.

## Restore preceding connection code — Android 0.6.9 / Watch 0.5.12

Restore the original apps from `c3f3f53` after the reported foreground-only connection on 0.5.13. Replace the earlier Android 27 / Watch 39 rollback with the original watch build-36 artifact and Android original executable code and resources with installation number 28 only. Android app-owned diagnostics intentionally retain the original build value 25. Both apps were installed in place, preserving registration, keys and vehicle settings. Foreground authentication completed during setup; full recovery without watch app entry and sustained connection remain unresolved. [Scope and deployment state](docs/ROLLBACK_0.5.12_EN.md).

## Android 0.6.10 / Watch 0.5.13 automatic recovery

Submit native connection requests and filtered discovery after background failure/restoration without relying solely on app timers. Restore phone advertising when the monitor is disabled. Final watch build 38 also restores an enabled location activity session immediately on background relaunch; locked-process restoration and authentication were recorded. Automatic authentication was recorded after actual Bluetooth loss and range departure/return, and after background watch process restoration. A later locked-state disconnect remains under investigation; sustained locked operation, hours-long locking and full device reboot recovery are not declared complete. [Changes and observations](docs/WATCH_0.5.13_AUTOMATIC_RECOVERY_EN.md).

## Android 0.6.9 / Watch 0.5.12 background authentication recovery

Send bootstrap after subscription and resume background authentication from its receive callback. Restart discovery advertising on phone refresh and submit background reconnection requests promptly. Physical-device recovery succeeded without reopening the watch app after phone service restart and stop/start. Prolonged lock, actual range return and all phone-only refresh cases after physical-link loss remain open. [Changes and observed scope](docs/WATCH_0.5.12_BACKGROUND_AUTH_EN.md).

## Watch 0.5.11 · build 35 (Android 0.6.8 unchanged)

Remove inherited retry backoff on foreground entry before resuming the saved connection, and resume waiting service discovery immediately. This addresses the 0.5.10 regression between opening the watch app and manually refreshing, while retaining registration. [Cause and scope](docs/WATCH_0.5.11_FOREGROUND_FIX_EN.md). Prolonged locking and physical range return remain unfinished.

## Android 0.6.8 / Watch 0.5.10 reconnection candidate

Retries missing-service discovery without cancelling the link, handles restored subscriptions and stale crypto state after phone restart, and backs off repeated connection failures. Registration and keys are retained. [Changes and observation limits](docs/WATCH_0.5.10_CANDIDATE_EN.md). Not declared fully resolved.

## Android 0.6.7-local · code 23 (Watch 0.5.8 unchanged)

Android GATT server connection callbacks can include links used by other BLE traffic. Previously the first physical link claimed the watch slot and stopped advertising, allowing an unrelated device to occupy connection waiting. Select the peer only when it subscribes to FoldBridge's own TX CCC descriptor. Existing pinned-key encrypted authentication remains required. Retain MTU values per device until subscription; unrelated connections and disconnections no longer reset the watch session or trigger cancellation of the other device.

While running, the phone service checks the local Bluetooth stack every 15 seconds. Clear a stale app connection and resume advertising when the physical link is gone. This check sends no periodic heartbeat to the watch. Add advertising, observed-link, subscription-claim and local-check fields to diagnostics.

Device records showed authentication without refresh after APK replacement, and again after stopping the phone process and explicitly reopening only the phone app. The agent did not launch FoldBridge on the watch. The Mac–watch developer tunnel remained unavailable, so the watch screen and a physical lock/unlock cycle could not be checked directly. This does not establish reliable automatic recovery after every unlock or extended idle period. [Scope and remaining investigation](AUTO_RECONNECT_EN.md)

## Android 0.6.6-local · code 22 (Watch 0.5.8 unchanged)

Galaxy records showed a real bring&T device-response notification with a title, plus an Android-generated `GROUP_SUMMARY` / `AUTOGROUP_SUMMARY` shell without title or body. Forwarding that empty shell caused FoldBridge's empty-notification fallback.

Exclude textless group summaries from initial collection, active-notification replay and forwarding, before recording first-post state. Summaries with text, text lines, custom layouts or action buttons, and individual notifications, are not excluded by this filter. Keep the existing bring&T numeric-update and charging-alert policies. Previously delivered watch Notification Center entries are not removed by the update.

## Android 0.6.5-local · code 21 (Watch 0.5.8 unchanged)

Forward Samsung System UI charging alerts (`charging_state` / `CHR`) and System UI notifications marked `ONLY_ALERT_ONCE` only once per active Android notification key. Even with charging alerts enabled, changes to battery percentage or time remaining do not alert the watch again. Charging alerts remain excluded when their setting is off. Existing indicators are baselined rather than replayed on listener reconnect or refresh. Removal followed by a new post can alert once again. Update the setting description in Korean and English; retain the existing Wattz/bring&T first-post policy.

## Watch 0.5.8 · build 32 (Android remains at 0.6.4)

Record every app cancellation request and connection callback/error details to distinguish causes of background link termination. Rename the misleading `manual` disconnect event to `ended`. Connection policy is unchanged; this is not a claim of a permanent reconnection fix. [Investigation and scope](docs/RELEASE_WATCH_v0.5.8_EN.md)

## Android 0.6.4-local · code 20 (Watch 0.5.7 unchanged)

For Wattz (`dubrowgn.wattz`) and bring&T (`com.bring.bringnt`), only the first post of an active Android notification key is forwarded to the watch. Updated numbers or text do not alert again; the watch retains the initial content. Removal of the phone notification allows a subsequent new post to be forwarded once again. Existing indicators are baselined during listener reconnects and are not replayed by refresh. Other apps and the original phone notifications are unchanged.

## Current-release documentation

- Add a [Watch 0.5.7 / Android 0.6.3 release guide](docs/RELEASE_WATCH_v0.5.7_EN.md) covering notifications, reconnection, supported vehicle controls and execution intervals.
- Update the documentation index and architecture wording, and label the 0.4.9 guide ZIP as archived. Korean and English guides contain the same changes. App behavior is unchanged.

## Watch 0.5.7 · build 31 (Android 0.6.3 unchanged)

- Match the quick-control panel to the current official widget: **Start engine / climate · Lock doors · Turn on hazard lights · Unlock doors**.
- Remove the unsupported Stop action and add a new `hazard` action. Legacy Stop assignments are not transferred to hazard lights.
- Include the official engine/climate label in automatic assignment. Each assignment picker exposes only matching official functions; old assignments to unrelated functions are replaced by the appropriate match.
- Retain automatic result acknowledgement and the single vehicle-control launcher. [Usage](docs/VEHICLE_CONTROL_EN.md)

## Watch 0.5.6 · build 30 / Android 0.6.3-local · code 19

- Recognize general result acknowledgement screens, including completion, approval and failure, instead of matching only the previous-request-incomplete sentence. Do not collect clickable result-message containers as vehicle controls.
- A control tap now acknowledges a result notice, waits for a fresh ready catalogue, then submits the selected vehicle action once. Remove the separate watch recovery button.
- Require both the acknowledgement response and the restored catalogue. Preparation expires 15 seconds after the original tap and is cancelled on leaving the panel. Vehicle commands themselves are not automatically retried.

## Watch 0.5.5 · build 29 (Android 0.6.2 unchanged)

- Replace four direct-action widget buttons with one **Vehicle controls launcher** in every supported widget size. Choose the four controls inside the panel; saved assignments are retained. Opening the widget sends no vehicle command.
- Register a service-filtered recovery scan immediately alongside a saved-peer connection attempt instead of relying solely on a delayed app timer.
- Allow background connection-maintenance callbacks to recover disconnected peers. Fresh advertisements can recover a peer despite stale auto-reconnect flags, and transport failure cancellation callbacks submit the next connection.
- Operation remains subject to watchOS background runtime limits. [Usage](docs/VEHICLE_CONTROL_EN.md)

## Watch 0.5.4 · build 28 / Android 0.6.2-local · code 18

- Fix selected controls disappearing after the official widget rebuilds its button screen with different internal View IDs. Four stored selections could previously match none of the four current controls.
- Use a unique exact button label within the bound widget as its stable identity. Migrate legacy selections only when their original digest and exact label match; preserve watch quick assignments when exactly one current action has the saved label.
- Duplicate labels are excluded rather than arbitrarily choosing a target. Renamed actions require reassignment.

## Watch 0.5.3 · build 27 / Android 0.6.1-local · code 17

- Stop mislabelling an empty official-widget catalogue as a login/authentication failure. Distinguish processing, refreshing and explicit authentication prompts.
- Recognize the observed MyHyundai notice that the previous remote-service request has not completed. Add **Dismiss notice and restore controls** to watch quick controls, all controls and phone settings. It dismisses only the notice; tap the desired vehicle control again afterward.
- Keep disabled controls in the inventory, lay out offscreen hosted widgets and request an official widget refresh for an otherwise empty catalogue.
- Preserve widget binding, selected controls and quick assignments. [Usage](docs/VEHICLE_CONTROL_EN.md#automatically-acknowledge-result-notices-android-063--watch-056)

## Mac tool: automatic free-account signing renewal

- Add Xcode re-provisioning and in-place watch app/widget installation when expiration is within 72 hours.
- Retry around watch availability/unlock, require a real expiration extension, preserve registration/settings, and back up matching profiles locally.
- Initial application renewed, installed and launched Watch 0.5.2 without changing its feature version. [Usage](docs/AUTO_RENEW_EN.md)

## Watch 0.5.2 · build 26 (Android 0.6.0 unchanged)

- Fix the missing-assignment path that opened the app without dispatching a vehicle command. On first use, assign an official action automatically only when exactly one explicit canonical label matches.
- Ambiguous labels such as a generic start/stop toggle, or missing previous assignments, show an action picker directly on the quick-control screen. Manual assignment does not execute a command.
- Show specific phone-side states: vehicle controls disabled, widget not bound, no selected actions, and other catalogue conditions.
- Add catalogue state/count, dispatch phase, and result codes to diagnostics without notification contents, vehicle identifiers, credentials, or control labels.

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
