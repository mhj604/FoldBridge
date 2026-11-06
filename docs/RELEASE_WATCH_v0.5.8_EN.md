# Watch 0.5.8 · build 32 / Android 0.6.4

[한국어](RELEASE_WATCH_v0.5.8_KO.md) · **English** · [Full usage guide](RELEASE_WATCH_v0.5.7_EN.md)

## Background connection investigation

Opening the app is not a required step in the ordinary reconnect path. The app submits a connection to the saved peer and uses OS auto-reconnect, service-filtered discovery and state restoration. watchOS controls background runtime and BLE delivery opportunities, so immediate reconnection is not guaranteed.

Device logs on 2026-11-06 showed both successful background connections and rapid disconnect/reconnect cycles. Galaxy reported that the remote device terminated the link, but the previous watch diagnostics could not distinguish app cancellation from system behavior. A disconnect without an error does not establish that the user manually disconnected.

This version improves diagnostics. **It does not claim a confirmed cause or permanent reconnection fix.** Logs read after installation showed successful background authentication; an immediate post-update result does not establish long-term reliability.

## Added records

- App cancellation count and reason: `cancellationCount`, `lastCancellation`
- Disconnect error domain, code and description: `lastDisconnect`
- Whether connection/disconnection callbacks refer to the current peripheral object
- Separate `cancel.*` app requests from ordinary `disconnect.ended.*` events

The watch app stores diagnostics in `Documents/foldbridge-status.json` and `Documents/foldbridge-events.json`. Events are capped at 128. These additions do not record message bodies or vehicle credentials. Diagnostics do not execute vehicle commands.

Android remains at 0.6.4. Notification layout, vehicle controls, peer keys and control mappings are outside this change. [Build and install](BUILD_AND_SETUP_EN.md)

Apple explains background link retention, reconnection on return to range and runtime limits in [Get timely alerts from Bluetooth devices on watchOS](https://developer.apple.com/videos/play/wwdc2022/10135/). The specific watchOS 9 limit described in that presentation is not assumed to be a fixed limit on current OS versions.
