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

## Follow-up: open-source catalog with existing apps and pairing retained

An additional Exa search covered **18 searches, 90 result slots including duplicates, and 68 distinct URLs** across Watch installers, expiry/trust bypasses, reusable signed hosts, and renewal/pairing tool boundaries. This is a separate count from the earlier 95 results; adding those counts does not yield a count of independent sources. No devices were modified and no code was executed.

**Related source exists, but no complete product was obtained for the current Ultra 2 / watchOS 27.2 that preserves the existing installation and pairing without renewal.**

| Project/source | Actual function | Why it does not meet the current conditions |
| --- | --- | --- |
| [AppSync Unified](https://github.com/akemin-dayo/AppSync) | Installation and runtime trust hooks | Requires system-process injection on jailbroken iOS; no current Watch port |
| [TrollStore](https://github.com/opa334/TrollStore) / [ChOma](https://github.com/opa334/ChOma) | Older CoreTrust-based installation/signature manipulation | Specific iOS targets, not current Watch support |
| [Permasigner](https://github.com/permasigner/permasigner) | Packages using an older CoreTrust flaw | Requires a vulnerable, initially jailbroken iOS target; Windows execution does not add Watch support |
| [MissedRevoke](https://gist.github.com/khanhduytran0/e3ae92673a1acfe85ce5a50b59d28361) | Public SQL and sample for trust/expiry records | iOS 26-family description; date rollback still needed; no current Watch application path |
| [Omega](https://github.com/jailbreakdotparty/Omega) | Changes iOS certificate blacklist records through partial restore | Author excludes iOS 27 and states data cannot be reliably preserved; not a Watch port |
| [NoMoreExpire source](https://github.com/antiquedev/Tweaks/blob/e6d6b80cea02a27863f445b24d57516fecd5e986/NoMoreExpire/Tweak.xm) | Short `SBApplication` profile-response hooks | No Watch installation, execution, or persistence implementation |
| [Anti-Apple-Revoke](https://github.com/utsur0/Anti-Apple-Revoke) | Online enterprise-certificate revocation blocking | Does not remove this Personal Team profile's local seven-day expiry |
| [SideStore](https://github.com/SideStore/SideStore) / [Splice](https://github.com/franklintra/splice) | Signing/refresh; Splice also has an older CoreTrust branch | Ordinary use renews profiles; permanent branch does not target current Watch |
| [ReProvision Reborn](https://github.com/sohsatoh/ReProvision-Reborn) | Watch re-signing from jailbroken iPhone | Actual renewal, with an iPhone execution dependency |
| [iLoader Watch fork](https://github.com/AndreySemjonov/iloader) | Watch companion installation via iPhone | Installation is not permanent signing; automatic Watch renewal is explicitly unsupported |
| [LiveContainer](https://github.com/LiveContainer/LiveContainer) | Rehosts apps inside a signed iOS host | Not a watchOS host; guest widgets/extensions generally unsupported |
| [WatchBox](https://github.com/34306/WatchBox) / [WatchFix](https://github.com/577fkj/WatchFix) / [watched](https://github.com/34306/watched) | iPhone–Watch pairing/version compatibility | Does not remove FoldBridge expiry; some flows require pairing again |

### New lead: MissedRevoke

The original Gist revision is [`3d15c8d63f7b6f2e71b9086f4cb9e099c786fe16`](https://gist.github.com/khanhduytran0/e3ae92673a1acfe85ce5a50b59d28361/3d15c8d63f7b6f2e71b9086f4cb9e099c786fe16). It publishes `_MissedRevoke.md` and `misdb.sql`; it is not classified here as a complete Watch application with a separate license file.

Its SQL triggers address expiry records, making it relevant research. However, the original text retains installation/launch time checks requiring system-date rollback. The sample creates a new database for iOS `MobileDeviceDomain` partial restore, rather than providing an in-place migration for an existing Watch database. The author also describes that restore route as blocked on iOS 27. None establishes an equivalent supported Watch route. No clock or database changes were made.

### Source-level distinctions

- AppSync revision [`235aca6cddfbdc9fa87fcb5b2aec2df37ed6d65a`](https://github.com/akemin-dayo/AppSync/blob/235aca6cddfbdc9fa87fcb5b2aec2df37ed6d65a/AppSyncUnified-FrontBoard/AppSyncUnified-FrontBoard.x) changes runtime trust responses through hooks. It needs injection into operating-system processes, not an ordinary function added to FoldBridge.
- Splice revision [`7968bb190ffe4f1aa0bac1b8da6fd3003af072be`](https://github.com/franklintra/splice/blob/7968bb190ffe4f1aa0bac1b8da6fd3003af072be/frontends/cli/source/trollstore.d) bases permanent-install status on vulnerable iOS versions. The option name does not establish watchOS support.
- [LiveContainer's FAQ](https://livecontainer.github.io/docs/faq) excludes general guest widget/extension support; it does not preserve the existing vehicle WidgetKit extension.
- [SideStore's FAQ](https://docs.sidestore.io/docs/faq) explicitly describes renewal. [NoFreeAppLimit](https://havoc.app/package/nofreeapplimit) removes an app-count restriction, not expiry.
- Netskao/AntiProfilesRevoke remains in search indexes, but direct GitHub API access returned 404 in this investigation. It is not presented as currently retrievable, maintained source. Free binary descriptions of Anti-Revoke 2 likewise do not establish source availability or Watch support.

Research ingredients exist, but a Watch implementation satisfying the full request remains unavailable in the material obtained. Existing apps and pairing remain intact; no no-renewal feature was installed or implemented.

## Can MissedRevoke be ported directly to current watchOS?

The follow-up on 2026-11-13 examined three areas: upstream/forks, deployment access, and independent launch-time expiry. Nine Exa searches returned **45 results including duplicates, with 40 distinct URLs**. Separately, the GitHub Gist API supplied upstream history, comments, and the files of 12 direct forks. This was source research, not an on-device experiment. Ultra 2 / watchOS 27.2 (24S118) is the previously recorded target, not a freshly read device version.

**Assessment: editing SQL and implementing no-renewal execution on this Watch are different tasks. SQL can be written, but the current Watch access and execution paths needed to make it effective have not been obtained.** No installed application was replaced or modified on the basis of this research.

### New upstream and fork findings

The [upstream Gist](https://gist.github.com/khanhduytran0/e3ae92673a1acfe85ce5a50b59d28361) has latest code revision `3d15c8d63f7b6f2e71b9086f4cb9e099c786fe16`, committed **2026-08-08**. Its November 6 `updated_at` metadata is not evidence of a new Watch implementation. All 12 direct forks returned by the API contained the same two files with the same contents. No Watch port or removal of the clock workaround was present in that set; this does not establish the contents of every derivative elsewhere. [History API](https://api.github.com/gists/e3ae92673a1acfe85ce5a50b59d28361) · [Direct forks API](https://api.github.com/gists/e3ae92673a1acfe85ce5a50b59d28361/forks?per_page=100)

### Four distinct implementation areas

| Area | Upstream implementation | Additional requirement on this Watch |
| --- | --- | --- |
| Database format | Creates an iOS schema-version-9 database | Actual current watchOS path, schema and service behavior; iOS equivalence cannot be assumed |
| Existing data | Recreates the local output DB; profile trigger acts on insertion | Migration preserving existing rows and relationships; adding an insert trigger does not retroactively change existing rows |
| Delivery | iOS MobileDeviceDomain partial-restore sample | A current Watch access path retaining registration, keys and settings; none is provided |
| Expired execution | Changes expiry/deletion bookkeeping but retains the original cms_blob | Handling the separate install/launch clock checks described by the author, including app and widget relaunch |

These SQL observations are static analysis. No device database was read and no trigger was executed. The sample also lacks a FoldBridge-only scope; copying it does not produce a targeted modification that preserves the existing installation.

Apple's [TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles) explains that a profile is Apple-signed CMS data containing execution validity, and that **watchOS 8 and later require the DER profile representation**. Changing a database timestamp or readable plist does not extend the Apple-signed profile. Combined with the author's remaining clock workaround, this supports the assessment that an SQL port alone does not deliver indefinite execution with the correct system clock. The exact current Watch enforcement functions or a bypass for them have not been obtained.

### Why ordinary developer connections and restore clients do not fill the gap

[pymobiledevice3's MisagentService](https://github.com/doronz88/pymobiledevice3/blob/master/pymobiledevice3/services/misagent.py) implements profile installation, enumeration and removal. It has no database-upload or arbitrary-SQL method. Having an RSD service name does not establish permission to write the protected database on this Watch; no such path was found in this client's functionality.

Apple's [Watch restore documentation](https://support.apple.com/guide/watch/restore-applewatch-from-a-backup-apdaa8cc32e8/watchos) describes selecting a backup during pairing. It does not document in-place replacement of a system database while retaining pairing. The [iOS 27 restore report](https://github.com/libimobiledevice/libimobiledevice/issues/1746) and [Nugget27](https://github.com/idkwhatt0d0dev/Nugget27)'s full backup/change/restore workaround do not provide a Watch no-renewal implementation preserving its current pairing. Their iOS behavior is not asserted to occur on this watchOS build.

FoldBridge has two executables: `dev.foldbridge.watch` and `dev.foldbridge.watch.widgets`. `WatchStore.swift` stores the registration identity in Keychain and sets newly inserted items to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Copying app preference files alone therefore cannot establish registration preservation. Neither that code nor the registration was changed.

### Outcome

The required port is now separated into database format, data preservation, system deployment, and runtime expiry handling. The missing foundation is **a deployment path on this physical Watch build and a means of permitting execution after expiry**, rather than SQL syntax. No nonfunctional installer or success placeholder was added. Existing apps, pairing and vehicle settings remain intact. No system logs, device connections, clock changes, restores, re-signing, or renewal automation were performed. The free no-renewal objective remains unachieved.
