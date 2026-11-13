# 무료 서명 유지 심층 조사: Windows와 워치 단독 갱신

**한국어** · [English](SIGNING_WINDOWS_RESEARCH_EN.md) · 조사일 **2026-11-13**

후속 조사: [배포 변경과 자체 Watch 앱 대체](NO_WEEKLY_SIGNING_ARCHITECTURE_KO.md). 미루팅 USB 시스템 프로토콜 변경안, App Store 배포 주체, 차량 제어용 기본 단축어를 정리했습니다. 아래 Windows 개발 순서는 구현 확정 사항이 아니며 현재 우선 검토 대상은 후속 문서의 구조 변경입니다.

## 결론

**Mac을 대체하는 Windows용 무료 갱신 프로그램은 개발 후보가 있습니다. 하지만 현재 FoldBridge 전체를 watchOS 27.2에서 아이폰·컴퓨터 연결 없이 인터넷만으로 자동 갱신하거나 영구 실행하는 완성된 경로는 찾지 못했습니다.** Windows로 서명해도 Personal Team의 7일 프로파일 유효기간은 그대로입니다. Windows 갱신 프로그램은 그 기한 전에 갱신을 반복하는 역할입니다. [Apple Personal Team 안내](https://developer.apple.com/help/account/basics/about-your-developer-account)

가장 구체적인 구현 재료는 `AndreySemjonov/iloader`의 Watch 설치 코드입니다. 다만 해당 프로젝트의 **자동 갱신은 아이폰 앱 전용이고 Watch 자동 갱신은 명시적으로 미지원**입니다. 이미 완성된 해결책으로 설치를 권하거나, 예약만 추가하면 워치에도 된다고 해석하면 안 됩니다. [자동 갱신 문서](https://github.com/AndreySemjonov/iloader/blob/2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70/docs/automatic-renewal.md)

## 요구 조건과 조사 범위

- 무료가 필수이며 수동 갱신은 해결책에서 제외합니다.
- 이전 요구인 **워치가 Mac에 연결되지 않고 인터넷만으로 갱신**하는 조건을 유지합니다. 이번 Windows 조사 요청을 아이폰 상시 중계 허용으로 해석하지 않습니다.
- 대상은 Ultra 2 / watchOS 27.2, FoldBridge Watch 0.5.15 / 빌드 41과 차량 제어 WidgetKit 확장입니다. 알림만 대체하는 도구는 전체 기능 대체로 보지 않습니다.
- Exa 검색 결과 91개 분량을 네 주제에서 조사했습니다. 이 수치는 중복 결과를 포함한 검색 범위이며, 독립된 91개 출처나 실기기 성공 횟수를 뜻하지 않습니다. 결론은 원저자 문서·소스·Apple/GitHub 공식 문서에 근거합니다. iOS와 watchOS, 계획과 구현, 설치와 자동 갱신을 구분했습니다.
- 이 작업은 자료와 소스 조사입니다. 기기 연결·앱 교체·등록 해제·시스템 로그 수집·차량 명령·예약 재개를 수행하지 않았습니다.

## 후보 비교

| 방식 | 무료 조건 | 현재 구현과 제한 | 이번 요구와의 관계 |
| --- | --- | --- | --- |
| Windows + iLoader Watch 포크 | 무료 Personal Team | 아이폰을 거친 Watch 설치 코드 있음. 자동 갱신은 Watch 제외 | Windows 자동 갱신의 개발 기반. 그대로는 미충족 |
| Windows → 워치 직접 RSD 연결 | 무료 서명 라이브러리 재사용 가능성 | 이번 기기에 대한 완성된 직접 설치·자동 갱신 근거를 확보하지 못함 | 아이폰을 빼려면 먼저 해결할 연구 과제 |
| SideStore 프로파일 갱신 | 무료 Apple 계정 | iOS 로컬 VPN·프로파일 교체. 워치 단독 지원 근거 없음 | 아이폰 기능을 워치 기능으로 취급할 수 없음 |
| ReProvision Reborn | 무료 Apple 계정 | 탈옥한 iOS 기기에서 Watch 앱 재서명 지원 명시 | 워치 단독이 아니며 현재 구성과 다른 조건 |
| TrollStore / 영구 서명 | 지원되는 취약한 OS에 한정 | 공개 TrollStore는 iOS 버전 한정. watchOS 27.2용 지원 없음 | 현재 워치의 무갱신 방법으로 채택 불가 |
| LiveContainer | iOS 컨테이너 도구 | watchOS 실행 환경이 아니고 확장 지원도 제한 | 현재 워치 앱·차량 위젯 대체 불가 |
| App Store + 회비 면제 조직 | 적격 조직이 면제 승인받아야 함 | 개인·1인 사업자는 면제 대상 아님. 배포·심사 필요 | 개인에게 자동 제공되는 무료 해결책 아님 |
| Watch 앱을 없애고 네이티브 프로토콜 사용 | 개발자 서명 대상 Watch 앱을 없앨 수 있음 | 루팅·구버전·지원 기기 제한과 기능 차이 | 현재 미루팅 Fold7·watchOS 27.2의 전체 대체로 확인되지 않음 |

## 1. Windows에서는 무엇을 재사용할 수 있는가

### 실재하는 Watch 설치 코드

조사한 `AndreySemjonov/iloader` 소스 고정점은 **`2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70`**입니다. README는 Windows에서 아이폰의 USB 또는 로컬 Wi-Fi를 이용한 Watch companion 설치를 설명합니다. **로컬 Wi-Fi 무선 설치와, 기기가 어디에 있든 인터넷만으로 설치되는 것은 다른 조건**입니다.

- [`watch_install.rs`](https://github.com/AndreySemjonov/iloader/blob/2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70/vendor/isideload/isideload/src/sideload/watch_install.rs): 아이폰 `CompanionProxy`로 워치의 lockdown과 `streaming_zip_conduit`를 전달합니다. USB와 RSD 경로가 있습니다. 재설치 전에 워치 앱을 명시적으로 삭제하지 않는 덮어 설치 흐름입니다.
- [`sign.rs`](https://github.com/AndreySemjonov/iloader/blob/2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70/vendor/isideload/isideload/src/sideload/sign.rs): Rust 코드로 프로파일·entitlement를 넣고 중첩 Watch 앱을 별도로 서명합니다. 이미 빌드한 실행 파일의 서명을 바꾸는 과정과 Swift 소스를 다시 컴파일하는 과정은 다릅니다.
- [`renewal/live.rs`](https://github.com/AndreySemjonov/iloader/blob/2d13485ef2d7107b2bc2ec6cdb5f54ce5729ef70/src-tauri/src/renewal/live.rs): `connect_device`는 Watch 대상이면 `WatchNotSupported`를 반환하고 `sign`에서도 Watch 작업을 거부합니다. `install_watch`도 같은 미지원 결과를 반환합니다. **한 군데의 설정만 켜면 되는 상태가 아닙니다.**
- 자동 갱신의 서명 검사에는 기본 Bundle ID에 Team ID를 추가한 식별자를 기대하는 코드도 있습니다. 그 동작을 FoldBridge에 그대로 사용하면 기존 앱을 갱신하는 대신 다른 식별자의 앱을 만들 수 있습니다. 기존 등록을 유지하려면 현재 Bundle ID·Team·키체인 접근 관계를 보존하는 별도 처리가 필요합니다.

별도 [Rzbck Watch companion 프로젝트](https://github.com/Rzbck/iloader-watch-companion)는 Windows→아이폰→Watch 설치·실행 성공을 기록합니다. 하지만 [호환성 문서](https://github.com/Rzbck/iloader-watch-companion/blob/404fe4c7f8ad610552ec2a4bc79a0d8d86c3048c/docs/COMPATIBILITY.md)는 **아이폰 호스트 없는 독립형 Watch 앱과 모든 중첩 확장 구조의 지원은 입증되지 않았음**을 명시합니다. 이 성공 기록을 FoldBridge의 성공 기록으로 옮겨 쓰지 않습니다.

### FoldBridge에 적용할 때 필요한 변경

현재 `watch/project.yml`은 iOS 호스트 없는 watchOS application과 `dev.foldbridge.watch.widgets` 확장으로 구성돼 있습니다. 따라서 companion IPA를 요구하는 도구에 현재 `.app`을 이름만 바꿔 넣는 방식으로 끝나지 않습니다.

개발 후보는 **기존에 빌드한 Watch `.app` 재사용 → 동일 Team으로 앱·위젯 프로파일 갱신 → Windows에서 서명 또는 프로파일 교체 → 워치에 적용**입니다. 정기 갱신마다 Swift 컴파일이 필요하다고 전제할 이유는 없습니다. 새 소스 버전을 빌드할 때에는 Apple SDK가 있는 환경이 필요하며, 공개 저장소의 표준 [GitHub Actions 러너](https://docs.github.com/en/actions/concepts/billing-and-usage)는 무료 빌드 후보입니다. 클라우드에서 파일을 만드는 것만으로 워치 설치 경로까지 생기지는 않습니다.

기존 설정을 보존하려면 다음 요구를 구현에 반영해야 합니다.

1. 현재 앱과 위젯의 식별자·Team을 유지하고 자동 등록 해제 없이 덮어 적용합니다.
2. 앱과 위젯 중 먼저 만료되는 프로파일을 기준으로 자동 처리합니다.
3. 최초 로그인 후 저장된 세션을 재사용하며 정기 작업마다 사용자 버튼을 요구하지 않는 구조로 만듭니다. Apple이 재인증을 요구할 때까지 무인 처리가 항상 가능하다고 보장할 근거는 없습니다.
4. 재컴파일·전체 재설치를 매번 반복하기보다 프로파일만 교체하는 경로를 우선 조사합니다.
5. 아이폰 중계 구현을 쓰는 경우 그 의존성을 명확히 표시합니다. **아이폰 없는 직접 연결**은 별도 미완성 항목입니다.

이것은 설계 후보이며 현재 저장소에 Windows 자동 갱신 프로그램이 구현됐다는 뜻이 아닙니다.

## 2. 전체 재설치 없이 갱신할 가능성

앞선 설명에서 모든 갱신이 전체 앱 재서명을 거친 재설치여야 하는 것처럼 표현한 범위는 좁혀야 합니다. SideStore의 병합된 [PR #846](https://github.com/SideStore/SideStore/pull/846)은 iOS refresh에서 재설치 코드를 제거하고 프로파일만 갱신합니다. 원저자는 댓글에서도 이 차이를 설명합니다.

이는 Windows 자동화가 더 가벼워질 수 있다는 **구현 근거**입니다. 하지만 iOS의 `misagent` 프로파일 처리가 워치 앱과 WidgetKit 확장에도 동일하게 적용된다는 결과는 확보하지 못했습니다. **프로파일 교체도 갱신**이며 만료가 사라지는 것은 아닙니다. 또한 기기에 새 프로파일을 전달할 통신 경로가 여전히 필요합니다.

[SideStore](https://github.com/SideStore/SideStore)의 로컬 VPN/Minimuxer 구성은 iOS용입니다. 이를 워치에 그대로 설치할 수 있다는 근거는 없습니다. [ReProvision Reborn](https://github.com/sohsatoh/ReProvision-Reborn)은 Watch 앱 자동 재서명을 명시하지만, 실행 주체는 탈옥한 iOS 기기입니다. 둘 다 워치 단독 인터넷 자동 갱신의 완성품으로 분류하지 않습니다.

## 3. 갱신 자체를 없애는 경로

[TrollStore](https://github.com/opa334/TrollStore)는 지원 iOS 버전을 명시한 CoreTrust 기반 도구입니다. [Watch 지원 이슈](https://github.com/opa334/TrollStore/issues/478)도 별도 문제로 남아 있으며 현재 watchOS 27.2용 배포 근거가 아닙니다. [OverCl0ck](https://github.com/PsychoTea/OverCl0ck)는 watchOS 3용 초기 시제품입니다. 검색에 나오는 오래된 워치 영구 서명 시연이나 iOS용 지원 버전을 현재 Ultra 2의 지원으로 해석하지 않습니다.

[LiveContainer](https://github.com/LiveContainer/LiveContainer)는 iOS/iPadOS 앱 실행기이며 앱 확장 미지원 등의 제약을 명시합니다. 실행기에 앱을 넣는 것이 현재 FoldBridge의 watchOS BLE 수신·알림·WidgetKit 확장을 영구 설치하는 경로는 아닙니다.

공식 배포에서 사용자 측의 매주 개발용 갱신을 없애는 경로는 App Store입니다. 비용을 전혀 내지 않는 공식 멤버십 경로로 [회비 면제](https://developer.apple.com/help/account/membership/fee-waivers/)도 조사했습니다. 적격 비영리 법인·인가 교육기관·정부 기관이 대상이고 개인·개인 사업자·1인 사업자는 제외됩니다. 오픈소스 공개만으로 면제가 되지 않으며, 현재 사용자의 적격 조직 소속이나 배포 파트너가 확보된 상태도 아닙니다. 다른 유료 개발자가 대신 지불하는 방식을 전체 무료라고 표현하지 않습니다.

[EU 웹 배포](https://developer.apple.com/support/web-distribution-eu/)는 iOS/iPadOS용 문서이며 watchOS를 위한 무료 개인 배포 경로가 아닙니다.

## 4. 워치 앱 자체를 없애는 우회 방향

이 방법은 서명 갱신을 하는 대신 서명이 필요한 자체 Watch 앱을 없애는 구조 변경입니다. [WatchWitch](https://github.com/seemoo-lab/watchwitch)는 루팅 Android·탈옥 iPhone과 구형 Watch 환경을 요구하며 watchOS 10 이후의 통신 제한도 문서화합니다. [apple_watch_connector](https://github.com/LordixDemon/apple_watch_connector)는 더 새로운 네이티브 프로토콜 구현이지만 Android root HAL의 지원 기기를 제한하고, 문서상 실기기 버전은 watchOS 26.2입니다.

이 방향은 원본 시스템 알림 전달을 연구할 수 있으나 **현재 미루팅 Fold7·watchOS 27.2에서 FoldBridge 차량 제어 위젯까지 그대로 대체한다는 근거는 없습니다.** Windows 설치 갱신과도 다른 대규모 프로토콜 프로젝트입니다. 조사 중 실제 시스템 페어링이나 앱 등록을 바꾸지 않았습니다.

## 권장 개발 순서와 미완성 경계

무료 Windows 자동 갱신을 다음 개발 후보로 삼을 수 있습니다. 첫 단계는 **아이폰 없는 Windows–Watch 직접 연결과 앱·위젯 프로파일 적용 경로**를 확보하는 것입니다. 이것이 없으면 서명 UI나 Windows 예약 기능을 먼저 만들어도 사용자의 인터넷 전용 조건은 해결되지 않습니다.

아이폰 중계를 허용한다면 공개 Watch 설치 코드와 기존 자동 갱신 엔진을 결합할 구체적인 재료가 있습니다. 그래도 독립형 FoldBridge와 차량 위젯 지원은 추가 개발 사항입니다. 수동 설치가 한 번 되는 것과 만료 전에 자동으로 계속 유지되는 것을 동일하게 취급하지 않습니다.

현시점 결과는 **무료 Windows 자동 갱신: 개발 가능성을 뒷받침하는 코드가 있는 후보**, **워치 인터넷만의 무료 자동 갱신: 미해결**, **현재 워치의 갱신 없는 영구 실행: 사용 가능한 구현 미확인**입니다. 기존 앱 동작과 중지된 예약은 변경하지 않았습니다.
