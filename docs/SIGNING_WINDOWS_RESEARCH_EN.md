# Free signing research: Windows and watch-only renewal

[한국어](SIGNING_WINDOWS_RESEARCH_KO.md) · **English** · Researched **November 13, 2026**

## Finding

**A free Windows renewal application has concrete implementation building blocks. No complete path was established for keeping all FoldBridge functionality on watchOS 27.2 through internet-only, watch-only automatic renewal, or permanent signing.** Replacing macOS with Windows does not remove the free Personal Team profile's seven-day validity. [Apple limits](https://developer.apple.com/help/account/basics/about-your-developer-account)

The strongest candidate is the Watch installer in `AndreySemjonov/iloader`. Its unattended renewal backend explicitly excludes Watch apps. This is a development candidate, not a ready-to-install solution.

The owner requires free automatic renewal, excludes manual renewal, and previously required no Watch–Mac connection and internet only. Investigating Windows does not authorize an always-present iPhone relay. The target is Ultra 2 / watchOS 27.2, FoldBridge 0.5.15 / build 41 and its vehicle WidgetKit extension.

Research covered 91 Exa search-result slots, including duplicates, across Windows installation, untethered renewal, permanent-signing techniques and free distribution. This is search coverage, not 91 independent sources or hardware results. Conclusions use primary documentation and source. No device connection, app replacement, registration change, system-log collection, vehicle command or schedule restart was performed.

## Candidate comparison

| Candidate | Evidence | Remaining boundary |
| --- | --- | --- |
| Windows iLoader Watch fork | Watch installation through a paired iPhone, USB or local Wi-Fi | Watch automatic renewal is explicitly unsupported |
| Direct Windows–Watch RSD | General cross-platform transport libraries exist | A working direct installer/renewer for this configuration was not established |
| SideStore | iOS VPN-based renewal; profile-only refresh implementation | Not evidence of standalone watchOS support |
| ReProvision Reborn | Watch re-signing explicitly listed | Runs on a jailbroken iOS device |
| TrollStore / permanent signing | Version-specific iOS implementation | No supported watchOS 27.2 implementation found |
| LiveContainer | iOS/iPadOS app container | Does not host the current watchOS app and WidgetKit extension |
| App Store with membership fee waiver | Official route for eligible organizations | Individuals/sole proprietors are ineligible; distribution and review still required |
| Remove the custom Watch app; use native protocols | WatchWitch and newer protocol research | Root, device/version limits and missing full feature equivalence |

## Windows source findings

Inspected `AndreySemjonov/iloader` at **`2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70`**:

- [Automatic renewal documentation](https://github.com/AndreySemjonov/iloader/blob/2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70/docs/automatic-renewal.md) specifies iPhone-only automatic renewal and separates manual Watch installation. Local Wi-Fi does not mean installation from anywhere over the internet.
- [Watch installer](https://github.com/AndreySemjonov/iloader/blob/2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70/vendor/isideload/isideload/src/sideload/watch_install.rs) forwards Watch lockdown and `streaming_zip_conduit` through iPhone `CompanionProxy`, with USB and RSD variants. Normal updates do not explicitly uninstall the existing Watch app.
- [Signing](https://github.com/AndreySemjonov/iloader/blob/2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70/vendor/isideload/isideload/src/sideload/sign.rs) uses Rust signing code and explicitly signs embedded Watch apps. Re-signing an existing executable is distinct from compiling Swift source again.
- [Renewal backend](https://github.com/AndreySemjonov/iloader/blob/2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70/src-tauri/src/renewal/live.rs) rejects Watch in `connect_device` and `sign`; `install_watch` returns `WatchNotSupported`. Enabling a single switch would not implement Watch renewal.
- That backend also expects Team-suffixed rewritten bundle identifiers. FoldBridge must retain its existing app/widget IDs, Team and keychain access relationship to update in place and preserve registration.

The independent [Rzbck project](https://github.com/Rzbck/iloader-watch-companion) records physical Windows→iPhone→Watch installation and launch. Its [compatibility document](https://github.com/Rzbck/iloader-watch-companion/blob/404fe4c7f8ad610552ec2a4bc79a0d8d86c3048c/docs/COMPATIBILITY.md) explicitly does not establish support for independent Watch apps without an iPhone host or all nested extension layouts. This is not a FoldBridge hardware result.

FoldBridge's `watch/project.yml` defines a watch-only application plus `dev.foldbridge.watch.widgets`, without an iOS host. Renaming the current `.app` to `.ipa` does not satisfy a companion-IPA installer's assumptions.

A candidate implementation would reuse the existing Watch executable, renew app/widget profiles under the same Team, sign or replace profiles on Windows, then apply them to the watch. Regular renewal need not require a fresh Swift compilation. Future source updates still need an Apple SDK build environment; public-repository standard [GitHub Actions runners](https://docs.github.com/en/actions/concepts/billing-and-usage) are a free build candidate. Cloud artifact production alone does not supply a watch installation transport.

The required custom work includes preserving identity/settings, scheduling against the earliest app/extension expiration, integrating Watch delivery into unattended jobs, and retaining account sessions. Apple's possible reauthentication requirements mean completely intervention-free operation cannot be guaranteed. No Windows renewal application was implemented in this investigation.

## Profile-only refresh is a meaningful lead

Earlier wording implying that every renewal necessarily requires a full app reinstall was too broad. Merged [SideStore PR #846](https://github.com/SideStore/SideStore/pull/846) removes reinstall work from iOS refresh and renews profiles instead. That is implementation evidence for a lighter renewal path, not evidence that the same path already supports this watchOS app and WidgetKit extension.

Profile replacement remains renewal; it does not eliminate expiration. It still needs a transport to apply the profile to the device. [SideStore's](https://github.com/SideStore/SideStore) VPN/Minimuxer architecture is iOS-based. [ReProvision Reborn](https://github.com/sohsatoh/ReProvision-Reborn) lists Watch re-signing but runs on a jailbroken iOS device. Neither establishes a watch-only internet renewer.

## Routes that do not currently remove this watch's renewal requirement

[TrollStore](https://github.com/opa334/TrollStore) documents specific supported iOS versions and has a separate [Watch support issue](https://github.com/opa334/TrollStore/issues/478). [OverCl0ck](https://github.com/PsychoTea/OverCl0ck) targets watchOS 3. Neither supplies current watchOS 27.2 support. Old Watch demonstrations and iOS version ranges must not be promoted as support for this Ultra 2.

[LiveContainer](https://github.com/LiveContainer/LiveContainer) targets iOS/iPadOS and documents extension limitations. It does not permanently install the current watchOS BLE receiver, notification interface and vehicle widget.

App Store distribution removes the user's weekly development-profile renewal workflow. The official no-membership-fee route is Apple's [fee waiver](https://developer.apple.com/help/account/membership/fee-waivers/) for qualifying nonprofit legal entities, accredited educational institutions and government entities. Individuals, sole proprietors and single-person businesses are excluded. Open-source publication alone does not qualify; no eligible distribution organization is established here. Someone else paying for membership is not a universally cost-free route.

[EU Web Distribution](https://developer.apple.com/support/web-distribution-eu/) documents iOS/iPadOS, not free personal watchOS distribution.

## Replacing the Watch app is a different architecture

[WatchWitch](https://github.com/seemoo-lab/watchwitch) requires rooted Android, jailbroken iPhone setup and older supported Watch conditions; it documents a watchOS 10+ transport limitation. [apple_watch_connector](https://github.com/LordixDemon/apple_watch_connector) has newer native-protocol work but restricts its Android root HAL to supported hardware and documents watchOS 26.2 hardware evidence.

These projects may avoid a custom development-signed Watch receiver, but do not establish full FoldBridge vehicle-widget equivalence on the owner's unrooted Fold7 and watchOS 27.2. This is a separate protocol implementation effort, not a Windows re-signing setting. No system pairing was changed.

## Development direction

For the strict requirement, the first missing piece is **direct Windows–Watch connectivity and app/widget profile application without an iPhone relay**. A signing UI or scheduled task does not solve that missing transport.

If an iPhone relay becomes acceptable, concrete Watch installation code and a separate renewal engine could be integrated. Independent FoldBridge and its widget would still require implementation work. One successful manual installation is not proof of ongoing unattended renewal.

Current classification: **free Windows automatic renewal — a source-backed development candidate; free watch-only internet renewal — unresolved; permanent execution on this current watch — no usable implementation established.** Existing app behavior and the stopped schedule were left unchanged.
