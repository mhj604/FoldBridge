# MyHyundai vehicle controls through Galaxy

[한국어](VEHICLE_CONTROL_KO.md) · **English** · [Documentation](README.md)

Available with Android **0.6.0-local / code 16** and Watch **0.5.0 / build 24**. Start vehicle controls in the FoldBridge watch app. This does not redirect the original MyHyundai watch app's iPhone connection.

## How it works

`Watch FoldBridge → existing encrypted BLE → Galaxy FoldBridge → official MyHyundai widget button`

FoldBridge hosts a widget supplied by the Korean MyHyundai Android app (`com.hyundai.oneapp.kr`) using Android AppWidgetHost. The owner authorizes widget binding and selects the controls to expose. FoldBridge does not store MyHyundai passwords or vehicle PINs or call private vehicle APIs.

The watch-to-phone link needs no server or iPhone relay. **Actual remote vehicle service requires internet connectivity for Galaxy MyHyundai and the vehicle, plus the applicable service subscription and conditions.** Offline BLE notification forwarding and remote vehicle service are separate features.

## Setup

1. Update both apps and keep the existing BLE registration. No new watch pairing is required.
2. Sign in and register your vehicle in the official Galaxy MyHyundai app.
3. Open Galaxy FoldBridge Local → **Vehicle control settings → Connect MyHyundai widget**.
4. Choose an official control widget, allow Android widget binding, and complete the vehicle/authentication configuration in MyHyundai if shown.
5. Select controls in **Buttons to show on watch**. The checkboxes select the watch catalogue; tapping a control inside the actual official widget may operate the vehicle.
6. Open watch **FoldBridge → Vehicle controls**. It displays the selected official button labels. Use **Refresh control list** after changes.

Turning off Watch vehicle controls disables the catalogue and dispatch. Disconnect vehicle controls removes only FoldBridge's hosted widget and selections; it does not remove the Hyundai account or BLE registration.

## Commands and responses

Choose a watch button and confirm execution to invoke the corresponding official widget button once. **A widget-invoked response means the widget listener was invoked, not that the vehicle operation succeeded.** MyHyundai's own UI and notifications provide the actual outcome. Its notifications can also reach the watch through the existing notification relay when enabled.

If MyHyundai requires phone unlock, login, or authentication, complete it on Galaxy. The widget's implementation and Android background activity-launch rules may require phone interaction. Unattended background execution of every vehicle command is not guaranteed.

Lost BLE responses and the 30-second reply timeout never automatically retry a vehicle command. Repeated request IDs are suppressed; the last 64 are stored on the phone. A changed widget/control catalogue invalidates old selections and requests a fresh catalogue.

## Empty catalogue

- Disabled: turn on Watch vehicle controls on the phone.
- Widget needed: bind an official MyHyundai widget.
- Authentication required: complete the explicit prompt shown by the official widget on Galaxy.
- No controls: check whether a result notice is hiding the controls. An empty catalogue alone does not imply lost login. Unlabelled controls or a changed widget structure may also be unsupported.
- Selection required: choose items in the phone's checkbox list.
- Stale catalogue: refresh the control list on the watch.

No automated test operates a vehicle. This implementation provides the official-widget bridge; it is not evidence of successful vehicle actuation or compatibility with every MyHyundai version.

## One vehicle control widget (Watch 0.5.5 / build 29)

Smart Stack and watch faces now offer one **Vehicle controls** widget. Tap it to open the FoldBridge control panel, then choose **Start engine / climate, Lock doors, Turn on hazard lights or Unlock doors**. Opening the widget alone sends no vehicle command. The widget kind is unchanged, so an existing widget can refresh to this layout. Separate action recommendations and the widget action picker are removed.

1. Open Smart Stack, touch and hold, then choose **+ → FoldBridge → Vehicle controls**. For a watch face, use **Edit → Complications → FoldBridge vehicle controls**.
2. Tap the widget to open the panel and prepare the Galaxy connection and current catalogue.
3. Choose the desired vehicle button. Saved quick assignments are retained. A uniquely matching explicit label can be assigned automatically; use **Quick control settings** if an assignment is needed.

A command is sent once only when the assigned ID and label match the current catalogue. Connection/catalogue requests time out after 15 seconds without deferred execution. Lost replies never automatically resend a vehicle command. Widget labels follow the watch system language; the panel uses the FoldBridge language setting.

## Automatically acknowledge result notices (Android 0.6.3 / Watch 0.5.6)

Recommended versions: Android **0.6.3-local / code 19**, Watch **0.5.7 / build 31**. The official widget can replace its controls with an **OK** result notice after incomplete, successful, approved or failed requests. An empty control list alone does not indicate a lost login.

Tap **Start engine / climate, Lock doors, Turn on hazard lights or Unlock doors** in the watch control panel. When a result notice is present, FoldBridge acknowledges it once, fetches a fresh catalogue and sends the action you just chose once the controls are ready. A separate recovery tap or second action tap is no longer required. Merely opening the widget does not start this sequence.

Recognition is based on a unique **확인·닫기 / OK·Close** acknowledgement inside the official widget rather than one exact message body. Clickable notice containers containing words such as “engine start” are not treated as vehicle controls. Authentication prompts and questions authorizing vehicle operations are distinguished from result notices.

Preparation lasts at most 15 seconds from the action tap. Leaving the panel or failing to restore the catalogue in that window cancels it. This neither repeats a previous command nor retries a vehicle command whose response was lost. Manual notice dismissal remains available in Galaxy settings. MyHyundai still provides the actual vehicle outcome.

## Controls remain unselected after dismissing a notice (Android 0.6.2 / Watch 0.5.4)

Recommended versions: Android **0.6.2-local / code 18**, Watch **0.5.4 / build 28**. Earlier builds included the official widget's internal View ID in each control identifier. Rebuilding the controls after a result notice could change those IDs and break both phone selections and watch quick assignments.

The current build uses a unique exact label within the bound widget as the stable identifier. Legacy phone selections migrate only when their old digest and exact current label match. Watch quick assignments follow a uniquely matching saved label. No new BLE pairing is needed. Renamed or ambiguous actions require reassignment in the phone checklist and watch quick-control settings. Migration itself sends no vehicle command.

## Reconnect on return to range (Watch 0.5.5)

A saved-peer connection attempt immediately registers a service-filtered Bluetooth scan as well. After range loss, the system retains the pending connection. A fresh advertisement can resubmit a disconnected peer even if an old auto-reconnect flag remains set. Location-session callbacks and the maintenance timer can recover a disconnected peer without foreground UI. Transport failures also preserve the cancellation callback and register recovery before returning from background runtime.

The Galaxy connection service and Bluetooth must remain enabled. watchOS background Bluetooth runtime limits, force quitting and post-reboot lock conditions still apply; this is not a guarantee of immediate reconnection in every OS state. [Apple background Bluetooth guidance](https://developer.apple.com/videos/play/wwdc2022/10135/)

## Match the official widget controls (Watch 0.5.7)

The current Galaxy official widget exposes **Start engine / climate, Lock doors, Turn on hazard lights and Unlock doors**. The watch panel uses the same order and labels. The unsupported Stop button is removed because the bound widget has no engine-stop action. Unlock is labelled as unlocking the doors rather than opening them.

Existing engine, lock and unlock assignments remain when they match the intended function. Hazard lights is a new action and is assigned when exactly one explicit official label matches. Legacy Stop assignments are never transferred to hazard lights. If the corresponding function is absent, the UI reports it rather than choosing an unrelated target. Existing phone widget authorization and selected controls are retained.

## Acknowledgement and dispatch intervals

There is no fixed delay. The notice is acknowledged when detected, then the selected action is sent once the response and a ready catalogue arrive. Catalogue polling uses **one-second intervals**, with a **15-second** preparation deadline from the original tap. A separate **three-second minimum interval** applies between vehicle commands; an early request returns busy and is not queued for later.
