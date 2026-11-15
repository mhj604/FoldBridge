# Android 0.6.16 / Watch 0.5.22 — locked-state authentication

[한국어](LOCKED_AUTH_0.5.22_KO.md) · [Documentation](README.md)

November 15, 2026. Candidate: Android **0.6.16-local / code 38**, Watch and vehicle widget **0.5.22 / build 53**. Install in place, preserving registration, pinned keys, identity keys and vehicle settings. [Android APK](https://github.com/mhj604/WatchBridge/releases/download/connection-v0.5.22/FoldBridge-Local-0.6.16.apk).

## Changed path

The locked-state 0.5.21 record repeatedly ended authentication just after subscription without an error or an app cancellation. The phone's shared GATT server retained its peer/subscription while the Watch app received disconnect callbacks. These are distinct connection lifetimes.

The new saved-peer flow is:

1. Rediscover services and characteristics on reconnection instead of synthesizing discovery completion from cached characteristic objects.
2. The updated phone exposes TX as `READ | INDICATE`. Write the short saved-peer request, then read its response from the native write-completion callback. Do not enable indication monitoring just to receive authentication responses.
3. Verify the request with the pinned key. Start compact authentication with reads even when the phone's shared GATT server retains an old subscription. Enable fresh indications after the phone receives encrypted confirmation and the Watch receives `ready`.
4. Deduplicate responses arriving through both read and indication. Do not complete a background task while an authentication read, `ready`, or subscription setup remains pending.

A transport-only disconnect no longer disables fast-authentication support. Migrate the previously disabled Local capability once without deleting peer registration or keys. Route restored values by peer/service/characteristic identifiers, excluding explicitly invalidated service objects. Wrapper mismatch was not established as the cause in the actual observation.

The phone's MTU estimate can be only a conservative lower bound for indication fragments. Truncating reads to that estimate incorrectly signals end-of-value. Return the remaining value at the requested offset and let the ATT stack apply its actual MTU. This was discovered and fixed in an intermediate candidate; it is not retroactively described as the cause of the original 0.5.21 failure.

## Encoding and compatibility

Retain existing P-256 pinned keys, fresh 32-byte nonces, HKDF/HMAC contexts and AES-GCM confirmation. Only compact resume serialization changes: `FBR 02 + one-byte kind + 32-byte nonce + 32-byte proof`, totaling 69 bytes. Including the existing eight-byte fragment header requires 77 bytes and fits one frame when ATT capacity permits. Older indication-only phone characteristics use the JSON flow. Update both apps for the new read path.

The read mailbox retains only the current peer's authentication response and encrypted ready response. It does not replay notification history or vehicle commands. Notification cutoff, connection-dependent phone notifications, vehicle-command deduplication and notification layout remain unchanged.

## Initial preparation and remaining limits

After an in-place Watch update, location activity may remain `restore-requested`. This is not eligibility or proof of execution. During this work the user opened the final build once, returned to the watch face and passcode-locked it. The following path stops/restarts only the phone service without reopening the Watch app. Distinguish that installation preparation from a requirement to open the Watch app on each reconnect.

Apple limits watchOS Bluetooth background runtime and reconnection opportunities. Location execution and Bluetooth-monitor runtime are separate. [Apple's behavior and limits](https://developer.apple.com/videos/play/wwdc2022/10135/). This change does not establish every native nil-error disconnect cause or remove OS limits.

## Actual result

Installed Watch build 53 and Android code 38 in place. The user completed one-time preparation, returned to the watch face and passcode-locked the Watch; the native device state also reported `passcodeRequired=true`. Without reopening the Watch app, the phone service was stopped and **Connect Watch** was pressed once at 22:48:24 KST. The phone started a fresh service instance.

The changed locked-state flow reached request/response reads, authentication on both peers and indication subscription. Even before final preparation, the installed Watch recorded `fastResumeCompleted=3`, `cancellationCount=0` and `failureCounts={}`. After final preparation the phone recorded `authenticated=true`, `subscribed=true`, 12 fast-authentication completions, no error and zero explicit disconnects. Individual authentication processing took approximately 2–3 seconds; that is not discovery-to-connection elapsed time.

**Sustained connection remains unresolved.** The final phone record had 24 attempts and 12 completions, showing continued retries. Both pre-authentication endings and endings after authentication/subscription were observed. The requirement to open the Watch app before any authentication has been improved, but uninterrupted proximity operation, prolonged lock and real range return are not declared solved. Some Mac development-tunnel reads timed out. A subsequently received Watch event file still contained six authentication and six subscription completions among its latest 128 entries, zero `cancel.failure` events, and repeated native terminations/retries. Neither peer’s completion record establishes sustained operation. Mac tunnel failure is distinct from Galaxy–Watch BLE termination.

The remaining issue is the condition behind native nil-error termination after authentication/subscription and repeated authentication afterward. Location eligibility alone does not establish why it occurs. Do not conceal it by blindly reusing handles/keys or skipping authentication. This release remains a **candidate**.

At handoff, stop the actual phone service with **Settings → Stop connection** and disconnect Mac wireless debugging, retaining registration, keys and vehicle settings. For ordinary automatic connection, leave **Connect Watch** enabled on the phone. Explicit service stop is different from temporary radio loss.

No system logs, administrator password, registration reset, device reboot or vehicle commands were used. Align the existing once-weekly Mac renewal source to the final committed installation without running renewal now. Free signing through Watch-only internet remains separately unresolved.
