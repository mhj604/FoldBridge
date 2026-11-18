# Watch-only free renewal — follow-up on 2026-11-18

[한국어](RENEWAL_RESEARCH_2026-11-18_KO.md) · **English** · [Current versions and priorities](CURRENT_STATUS_EN.md)

The goal is automatic free renewal and application using only watch internet, retaining the existing app, registration and vehicle settings, without a Mac, PC or iPhone. Exa located candidates; the GitHub connector was used to read their renewal code. No new tool installation, device registration or signing request was performed.

## Code and actual requirements

| Source | Support and missing conditions |
| --- | --- |
| [AdminZachary/WatchBridge](https://github.com/AdminZachary/WatchBridge) | An unrelated iLoader derivative with the same name. Its README describes a desktop/paired-iPhone workflow and an IPA containing both an iPhone host and `Watch/*.app`, not in-place renewal of this standalone Watch app. |
| [Its live renewal backend](https://github.com/AdminZachary/WatchBridge/blob/main/src-tauri/src/renewal/live.rs#L167-L173) | `connect_device` explicitly returns **`Failure::WatchNotSupported`** when `watch.is_some()`. `prepare` and `discover` call `require_phone_job`. The README's automatic-renewal feature cannot establish implemented Watch renewal. |
| [TetherlessiOS](https://github.com/pwnapplehat/TetherlessiOS) | Free automatic refresh in the README needs an iPhone, LocalDevVPN and personal automation. The queried public root contains README, website and assets; an implementation for Watch installation/renewal was not established. Computer-free does not mean watch-only. |
| [SideStore](https://github.com/SideStore/SideStore) | An iOS app using LocalDevVPN/local-device connectivity. No supported replacement for a free profile from within this watchOS app was established. |
| [Sideloadly changelog](https://sideloadly.io/changelog.html) | The retrieved v0.71.0 notes describe Watch signing for Developer Program accounts and free Watch support as forthcoming. Desktop automatic refresh is separate from watch-only operation. |
| [idevice pairing tool](https://github.com/jkcoxson/idevice/blob/a64b8867/tools/src/pair_rsd_ios.rs) | A Rust device-service connectivity component. Its existence does not grant a watchOS app permission or execution opportunities to renew/install itself. |
| [Apple Watch MDM deployment](https://support.apple.com/guide/deployment/deploy-apple-watch-dep04f0c5414/web) | Managed-iPhone enrollment and application management do not supply a drop-in free Personal Team renewal path preserving existing personal pairing. |

## Outcome and missing implementation

**The public code read in this investigation did not establish a usable free watch-only renewal path meeting these requirements.** Obtaining a profile from Apple is only one step. Applying it through the watch installation service and obtaining execution before expiry remain necessary. Copying iPhone renewal code or downloading a profile does not supply those missing steps. This is not a claim that every future implementation is impossible.

No nonfunctional “internet auto-renew” toggle was added, and iPhone refresh was not relabeled as Watch support. An actual Watch installation/profile-replacement implementation would be the next starting point.

## Existing weekly Mac setup

The configuration records Watch **0.5.26 / build 60**, source **95577b5**. Earliest recorded expiry is **2026-11-20 17:10:54 KST**; native macOS scheduling is **Friday at 16:00**. No renewal run or schedule change occurred in this task. Configuration is separate from a successful new signature and installation. An awake Mac plus reachable unlocked watch development connection remains necessary. [Renewal conditions](AUTO_RENEW_EN.md).
