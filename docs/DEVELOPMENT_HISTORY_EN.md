# Development history and important decisions

[한국어](DEVELOPMENT_HISTORY.md) · **English** · [All guides](README.md)

This summarizes the important milestones. For current setup, use [Install and connect](QUICK_START_EN.md); earlier implementation details do not necessarily describe the current release.

## Current: Watch 0.4.9 / Android 0.5.4

Each authenticated connection becomes the notification start point. Unlike 0.4.8/0.5.3's first-registration-only cutoff, reconnection also drops the older queue. The phone removes the disk outbox and retries only current-session items in memory. Phone advertising restart and watch background recovery scans/native pending connects support recovery. Cable-free Mac–Galaxy deployment uses saved ADB pairing; personal endpoints and keys remain local. [Release notes](RELEASE_WATCH_v0.4.9_EN.md)

## Requirements and initial installation

The project began from a 0.1.0 package containing Android, watchOS, Windows, and APNs relay components. Watch-only project settings, signing, developer mode, Mac–Watch development pairing, and physical installation were addressed first.

The accepted Local configuration uses Galaxy–Watch BLE without a runtime server, internet, iPhone relay, paid push membership, root, or artificial workout/audio session. A separate Local Android app ID/signing setup allowed development without replacing the older app when its signing key was unavailable. Optional location keepalive requests runtime but does not remove watchOS limits.

## Notification access diagnosis

Both apps could appear connected while the phone's notification listener lacked access. Bluetooth authorization alone did not allow collection of other apps' notifications. REA and ADB observations separated package/permission/listener state from BLE and local watch display requests.

Changes exposed separate collection/connection status, guided users to notification access, requested listener rebinding, checked watch notification permission before ACK, enabled foreground notification presentation, removed an arbitrary short background-task cutoff, and added content-free diagnostic counters. Different cumulative counts can result from duplicate revisions/retransmission; they are not automatically evidence of loss.

## Repeated charging alerts

Samsung System UI updated charging-state notification contents as the battery percentage changed. Forwarding each changed revision created repeated watch alerts; these were not periodically generated debug messages. A default charging-update filter and optional override were added without blanket-blocking system notifications. No BLE protocol change was required.

## Original icons, UI, and inbox removal

Android PackageManager icons became bounded PNG metadata, encrypted alongside messages and cached on the watch. Per-session icon acknowledgment reduced repeated image bytes. UI was simplified, and subsequent builds removed the separate watch message list/body store. The migration retained only receipt hashes; watchOS Notification Center continued to own delivered content.

The sensitive-content investigation found the phone's per-app `RECEIVE_SENSITIVE_NOTIFICATIONS` setting blocked full text. The device-owner setting and listener rebinding were documented separately from ordinary notification access and watch preview expansion.

## Restarts, refresh, icon alignment, and languages

Android recovery expanded to package update, listener reconnection, and Bluetooth events while preserving connection intent. Watch recovery handled saved peripherals, Core Bluetooth state restoration, discovery fallback, and requested background-refresh opportunities. These mechanisms do not guarantee boot-time launch.

Both apps gained a refresh action that preserves registration. Old-server callbacks and duplicate authentication starts were separated. The FoldBridge icon was first geometrically recentered, then adjusted for visual balance and given a refreshed watch asset name.

Android 0.5.0 / Watch 0.4.0 added independent Korean/English/system language selection, a shared translation catalog, and generated resources. Language changes preserve the connection and forwarded contents.

## Notification layout iterations: Watch 0.4.1–0.4.7

| Version | Important change |
| --- | --- |
| 0.4.1 | Restore system text presentation and try source icons as media attachments |
| 0.4.2 | Remove attachments after oversized preview/thumbnail behavior |
| 0.4.3 | Retain source icons only as 24pt artwork in bounded expanded content |
| 0.4.4 | Reduce extra margins and align the text baseline |
| 0.4.5 | Adjust font, paragraph/line spacing, icon overlay, and watchOS 27 start position using example comparisons |
| 0.4.6 | Move text and icon down together by 3pt following user feedback |
| 0.4.7 | Keep that placement and trim lower spacing by 4pt |

System popup/card/header branding remains FoldBridge. Earlier research into communication notifications, ANCS/accessory APIs, and a root-dependent native-protocol project did not produce an adopted replacement path for the current setup. REA artifact inspection was distinguished from live system rendering and from source review. [Display scope](NOTIFICATION_DISPLAY_LIMITS_EN.md) · [Example captures](NOTIFICATION_LAYOUT_COMPARISON_EN.md)

## Watch 0.4.7 / Android 0.5.2 connection repair

Previous one-sided refresh forced reauthentication and used short periodic ping deadlines. Locked/background observations exposed repeated disconnects and authentication waiting. Runtime-aware maintenance replaced background wall-clock disconnects, and healthy refresh became an encrypted update/sync request that preserves the session.

Phone records showed a Samsung system service's GATT registration change at the same time as watch service invalidation. The new watch path rebinds characteristics without discarding a healthy crypto session. Actual process restoration still uses fresh nonces and pinned peer keys; explicit CCC restoration, MTU recovery, stale ATT completion handling, and repeated-disconnect backoff were added. Missing display ACKs wait in the outbox instead of cancelling a healthy BLE link.

With build 21 installed, a phone-only refresh reached a locked/background watch, incremented its remote-refresh counter, and retained both sessions with no recorded errors or pending items at that observation. This was a bounded physical-device observation with optional location keepalive enabled, not a claim of unrestricted background launch. [Release notes](RELEASE_WATCH_v0.4.7_EN.md)

## Watch 0.4.8 / Android 0.5.3 pairing and recovery

The first successful registration now clears the Android outbox and stores an encrypted posted-time cutoff. Listener callbacks use Android's notification post time, and active-notification replay after service restart filters against that cutoff. Already registered peers retain pending alerts while recovering.

Saved watch-to-phone connections request Core Bluetooth automatic reconnection. The watch preserves the peripheral object while the OS owns that retry and rediscoveries GATT with fresh nonces when the link returns. Existing app retry/scan logic remains a fallback. This requests recovery after range loss; it cannot prevent disconnection or promise an immediate link under every radio and watchOS condition. [Release notes](RELEASE_WATCH_v0.4.8_EN.md)

## Korean and English documentation

The repository now provides paired overview, installation, FAQ, troubleshooting, build/settings, architecture, protocol, display/layout, current-release, changelog, development-history, and contribution guides. The bilingual index links each pair. Original older release notes remain archived in Korean.
