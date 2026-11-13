# watchOS 27.2 signing bypass: public research and implementation feasibility

[한국어](WATCHOS_27_SIGNING_BYPASS_RESEARCH_KO.md) · **English** · Research date: **2026-11-13, Korea time**

## Finding

**No free, no-renewal implementation was obtained for Ultra 2 / watchOS 27.2 (24S118) that preserves the existing FoldBridge installation and pairing.** Relevant research exists: physical Watch permasigning on older firmware, a recent Watch modification demo, memory-corruption research affecting the current OS family, and execution in a virtual Watch. None supplies the required complete path on this device.

This was public-source analysis. No devices were connected, system logs collected, PoCs executed, apps installed or re-signed, settings changed, devices erased, or pairings removed. No vehicle commands or canceled renewal schedules were run. FoldBridge application code was not changed; signing bypass remains unimplemented.

## Scope

The target is the prior device record, **Ultra 2 / watchOS 27.2 / 24S118**, not a newly read device version. Conditions remain free operation, no manual renewal, no permanently attached USB adapter, and preservation of installed apps, registration, system pairing, and vehicle settings.

Exa coverage comprised 19 searches, **95 result slots including duplicates, 84 distinct URLs**, grouped into four themes. These are search-coverage counts, not independent experiments. Conclusions rely on Apple advisories, original researcher posts, and repository source/status documents. iOS results, crashes, user-space corruption, kernel privileges, signing bypass, installation, relaunch, and reboot persistence are treated separately.

## Candidate matrix

| Candidate | Public result | Missing for this target |
| --- | --- | --- |
| LIJI32 permasigning demo | Physical Watch on watchOS 8.3, MacDirtyCow + CoreTrust | Both bugs were fixed years before the target firmware |
| Calif Watch demo | Original Watch modification post on October 26, 2026 | Exact Ultra 2 / 24S118 support and complete public code not established |
| CVE-2026-111497 / Brotli | Later watchOS fix advisory; iPhone corruption reproducer | Watch execution, privileges, signing bypass, and persistence |
| sn0wbite | User binary execution in a virtual Watch | No physical Ultra 2 entry exploit or trusted-boot bypass |
| ABrake27 | iPhone static analysis and probe application | No Watch implementation; some early hypotheses retracted |
| iOS-Research | iPhone protection analysis and open leads | No Watch build support or confirmed TXM bypass |
| AppSync Unified | Installation/runtime trust hooks on jailbroken iOS | Requires system-process injection first; no current Watch support |
| jelbrekTime / OverCl0ck | Older Watch kernel/signing research | Different firmware, hardware, and exploit prerequisites |

## Physical Watch permasigning has historical precedent

[LIJI32's original March 16, 2024 post](https://x.com/LIJI32/status/1769120899293159746) describes combining CVE-2022-46689 and CVE-2022-26766 on watchOS 8.3. This means the general concept is not inherently impossible. Apple documents the respective fixes in [watchOS 9.2](https://support.apple.com/en-us/102741) and [watchOS 8.6](https://support.apple.com/en-us/102759). A recently republished article does not make the old technique applicable to current firmware.

The author's [follow-up](https://x.com/LIJI32/status/1769123903585058905) did not commit to a product release. No follow-up PoC applicable to the current device was obtained in this investigation.

## Recent Calif demonstrations

[Calif's October 26 Watch post](https://x.com/calif_io/status/2114716526129627579) does not specify the exact model, firmware build, exploited bugs, or execution code in its text. It cannot establish a no-renewal installer for this Ultra 2 or preservation of existing data. The separate [October 16 iPhone post](https://blog.calif.io/p/iphone) promises future disclosure, not an already available Watch chain. The team's [public MIE challenge](https://calif.io/research/apple-mie) targets macOS rather than this Watch.

## A current-family lead: Brotli

Apple lists CVE-2026-111497 as fixed in [watchOS 27.2.1, released November 9](https://support.apple.com/en-us/149722), with memory corruption as the impact. This is relevant to investigating 27.2, but not proof of code execution or permasigning on Ultra 2. Google publishes the [upstream fix](https://github.com/google/brotli/commit/0ed4268a4401abcb4472096340477cf4af7d1a2b) and [1.2.1 changelog](https://github.com/google/brotli/blob/v1.2.1/CHANGELOG.md).

The [Apple-library PoC at `0899753a85829472ac4a6e63b75655dd91db6fa0`](https://github.com/MchinaMd57764/CVE-2026-111497-PoC/tree/0899753a85829472ac4a6e63b75655dd91db6fa0) reports iPhone behavior and explicitly excludes demonstrated code execution, control-flow hijack, PAC bypass, and kernel compromise. It contains no Watch result. Connecting this lead to the user's goal requires new work establishing a reachable Watch path and execution control, additional privileges or trust-check bypass, installation/relaunch, and persistence. Adding a crash reproducer to FoldBridge would not resolve expiry. No PoC was run or transmitted.

## Why other code is not directly portable

- **sn0wbite**, revision [`cbfd718646d0f76a1738fc20fce215361a4f49c9`](https://github.com/andrei-borcea/sn0wbite/tree/cbfd718646d0f76a1738fc20fce215361a4f49c9), modifies a virtual Watch7,11 kernel, ramdisk, and trust cache. Editing those files before a VM boots does not provide permission to edit them on a physical Watch.
- **ABrake27**, revision `a9ebd52ab4342f5f2c22d885fd3afa9711f5aad7`, has an AMFI-bypass whitepaper title, but its authoritative [status document](https://github.com/vvirei333/ABrake27/blob/a9ebd52ab4342f5f2c22d885fd3afa9711f5aad7/STATUS.md) targets iPhone/iOS and retracts an early VFS TOCTOU theory after function-address misidentification. Its [probe](https://github.com/vvirei333/ABrake27/blob/a9ebd52ab4342f5f2c22d885fd3afa9711f5aad7/poc/probe_app/README.md) studies ImageIO behavior, not permanent signing. This does not imply all findings in that repository are false.
- **iOS-Research**, revision [`a3416a5f062e404c0688cf9aaa8064b422cfb3eb`](https://github.com/AzozzALFiras/iOS-Research/blob/a3416a5f062e404c0688cf9aaa8064b422cfb3eb/STATUS.md), reports no confirmed TXM bypass in its investigation. iPhone protection analysis does not establish the exact Ultra 2 implementation or bypass success.
- [**AppSync**](https://github.com/akemin-dayo/AppSync) handles installation and runtime expiry through separate hooks on jailbroken iOS. Linking the code into an ordinary Watch app does not supply system-process injection. [jelbrekTime](https://github.com/tihmstar/jelbrekTime) and [OverCl0ck](https://github.com/PsychoTea/OverCl0ck) likewise depend on older exploit environments.

## What implementation still requires

A **signature-logic-bug route** needs a current Watch validation flaw plus an installation/registration path, runtime/expiry handling, and reboot persistence. It need not theoretically require a complete kernel jailbreak, but the current flaw and application path are missing.

A **privilege-escalation route** needs access/execution on the current build, handling of signing/installation/runtime trust boundaries, and a persistence or automatic restoration mechanism. A kernel read/write primitive alone does not establish all these capabilities.

FoldBridge uses both `dev.foldbridge.watch` and `dev.foldbridge.watch.widgets`. App execution alone would not prove WidgetKit extension operation or relaunch support. Preserving registration, keys, and settings also requires maintaining bundle identity, keychain access relationships, and the data container. None of the candidates supplies that complete path for the current target.

## Outcome

The concrete research candidates and missing implementation stages are documented. Free permanent operation while preserving existing apps and pairing remains unresolved. No build-setting change or direct copy of an older bypass closes the gaps.

Useful next evidence would be public entry code for the physical Watch/build, signing/expiry handling, and reboot persistence. No current installation was replaced, and the request was not substituted with automatic renewal or external hardware.
