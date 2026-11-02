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
