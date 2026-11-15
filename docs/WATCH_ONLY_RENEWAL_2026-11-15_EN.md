# Watch-internet-only free renewal — November 15, 2026

[한국어](WATCH_ONLY_RENEWAL_2026-11-15_KO.md)

Priority requirements: **retain the app/registration, free, automatic, Watch internet alone with no Mac or iPhone**. This pass used Exa to review 26 results across five search angles, then opened relevant primary sources. The table summarizes distinct candidates, not result counts. No applicable implementation meeting every requirement was obtained.

| Candidate | Actual scope and missing requirement |
| --- | --- |
| [SideStore](https://github.com/SideStore/SideStore) | An iOS app using LocalDevVPN and local device services, not a native watchOS target. |
| [SideInstaller](https://github.com/FrizzleM/SideInstaller/blob/main/NOTES.md) | An iOS implementation of local VPN/RPPairing, not evidence of Watch support. |
| [WatchBridge](https://github.com/AdminZachary/WatchBridge) | A Windows/macOS program requiring a paired iPhone during preparation; its documentation excludes Watch-only packages. |
| [iLoader automatic renewal](https://github.com/AndreySemjonov/iloader/blob/main/docs/automatic-renewal.md) | This branch explicitly excludes automatic Watch renewal. Installation support in other branches is a separate claim. |
| [JAS](https://github.com/jkcoxson/jas) | Server-hosted iOS renewal; could replace a Mac host, but is not Watch-only and has no demonstrated deployment on this Watch. |
| [iOS Signer Service FAQ](https://github.com/oh-me/ios-signer-service/blob/master/FAQ.md) | Despite cloud signing, its free-account workflow excludes OTA installation. Adding a web download does not solve deployment. |
| [idevice](https://github.com/jkcoxson/idevice/) | Building blocks for RSD and profile management; their availability does not demonstrate automatic renewal inside a Watch app. |

The installed Xcode watchOS SDK declares [NEPacketTunnelProvider](https://developer.apple.com/documentation/networkextension/nepackettunnelprovider) as `API_UNAVAILABLE(watchos)`. SideStore's local VPN extension therefore cannot simply be ported using that API. **Obtaining a fresh profile** and **applying it through the Watch's installation services** are separate operations; the latter Watch-only path remains missing. This identifies present limitations of the researched paths, not a proof against every future implementation.

An external Galaxy/Linux signing and RSD host remains a development candidate. It differs from Watch-internet-only renewal, and no placeholder claiming working renewal was added. The existing weekly Mac job is not presented as Watch-only renewal.
