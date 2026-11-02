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
- No controls/authentication required: finish widget configuration. Unlabelled controls or changed widget structures may be unsupported.
- Selection required: choose items in the phone's checkbox list.
- Stale catalogue: refresh the control list on the watch.

No automated test operates a vehicle. This implementation provides the official-widget bridge; it is not evidence of successful vehicle actuation or compatibility with every MyHyundai version.

## Smart Stack widget and watch-face buttons (Watch 0.5.1 / build 25)

Requires watchOS 11+. The rectangular widget has **Start, Stop, Lock and Unlock** buttons; smaller complications display one selected action. Tapping a button automatically brings FoldBridge to the foreground and dispatches the command. You do not navigate through the app list or menus; this is not invisible background execution.

### Assign controls once

1. Open watch **FoldBridge → Vehicle controls → Quick control settings**.
2. Assign each quick button to its corresponding official MyHyundai action. Assignment itself sends no vehicle command.
3. Only actions exposed by the phone are available. Complete phone widget setup first if an action is absent.

### Add the widget

1. Turn the Digital Crown from the watch face to open Smart Stack.
2. Touch and hold the widget area; choose **+ → FoldBridge → Vehicle controls**.
3. Pin it for convenient access. Tap the desired control once to dispatch through the assigned official widget button.

For a watch-face complication, touch and hold the face, then choose **Edit → Complications → FoldBridge vehicle controls**. Choose Start, Stop, Lock or Unlock for a small slot. Available slots vary by face.

### Dispatch behavior

The app opens, restores the Galaxy connection and requests a fresh catalogue. The saved action ID and label must both match before a single dispatch. Missing assignments or changed actions display setup guidance. Failure to obtain the connection/catalogue within 15 seconds cancels the pending tap; it does not execute later. Lost command replies never trigger automatic resend.

Assignments stay on the watch and are scoped to the registered phone. The widget needs no shared storage capability and creates no separate BLE session. Widget text follows the watch system language; app screens use the FoldBridge language preference. MyHyundai authentication and actual vehicle outcome limitations still apply.

### A widget tap opens the app but sends no command (0.5.2)

Adding a widget does not itself assign the underlying vehicle action. Version 0.5.2 automatically assigns a control when exactly one explicit canonical label (such as Start engine, Stop engine, Lock or Unlock) matches the official catalogue. Existing user assignments are never silently overwritten.

Ambiguous or changed actions display a picker directly below the quick-control buttons. Choosing an item stores the assignment only; a subsequent widget tap dispatches it. Disabled phone controls and incomplete widget configuration have distinct guidance.

Receiving a valid official catalogue is not a vehicle-success response. MyHyundai still provides the actual outcome.
