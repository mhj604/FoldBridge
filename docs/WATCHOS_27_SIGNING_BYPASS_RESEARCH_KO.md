# watchOS 27.2 서명 우회: 공개 연구와 직접 구현 가능성

**한국어** · [English](WATCHOS_27_SIGNING_BYPASS_RESEARCH_EN.md) · 조사일 **2026-11-13, 한국 시간**

## 현재 판단

**Ultra 2 / watchOS 27.2(24S118)에 기존 FoldBridge와 페어링을 유지하면서 적용할 수 있는 무료·무갱신 서명 우회 구현은 확보하지 못했습니다.** 관련 연구가 없다는 뜻은 아닙니다. 과거 실물 워치의 영구 서명 시연, 최근 워치 탈옥 시연, 현재 OS 계열의 메모리 손상 PoC와 가상 워치 실행 코드를 찾았습니다. 그러나 어느 것도 이 기기에 적용할 수 있는 완성된 실행 경로가 아닙니다.

이번 작업은 공개 자료·소스 분석입니다. 기기 연결, 시스템 로그 수집, PoC 실행, 앱 설치·재서명, 시스템 설정 변경, 초기화, 페어링 해제를 수행하지 않았습니다. 차량 명령과 중지된 자동 갱신 예약도 실행하지 않았습니다. FoldBridge 앱 코드는 변경하지 않았으며 우회 기능이 구현됐다고 보고하지 않습니다.

## 범위와 근거

- 대상 버전은 기존 작업 기록의 **Ultra 2 / watchOS 27.2 / 24S118**입니다. 이번 작업에서 기기의 현재 버전을 새로 읽은 것은 아닙니다. 버전이 달라지면 적용 가능성도 다시 판단해야 합니다.
- 무료이며 수동 갱신과 상시 외장 USB 어댑터는 제외합니다. 기존 앱·워치 등록·시스템 페어링·차량 설정을 보존합니다.
- Exa 검색 19회, 검색 결과 **95개(중복 포함), 서로 다른 URL 84개**를 네 주제로 분류했습니다. 이 숫자는 독립된 실험이나 기기 성공 횟수가 아닙니다. 결론에는 Apple 공지, 연구자 원문, 저장소 소스·상태 문서를 사용했습니다.
- 단일 CVE, 충돌 재현, 사용자 공간 메모리 손상, 커널 권한, 서명 검사 우회, 설치·재실행, 재부팅 후 지속성을 서로 다른 단계로 취급했습니다. iOS의 성공을 watchOS 성공으로 바꾸어 쓰지 않습니다.

## 후보별 결과

| 후보 | 실제로 공개된 내용 | 현재 대상과의 차이 | 직접 적용 판단 |
| --- | --- | --- | --- |
| LIJI32 영구 서명 시연 | watchOS 8.3에서 MacDirtyCow + CoreTrust 이용 | 두 취약점은 각각 watchOS 9.2·8.6에서 수정됨 | 현재 버전용 코드로 사용할 수 없음 |
| Calif 워치 시연 | 2026-10-26 원저자 게시물에 워치 변조 시연 | 원문에 Ultra 2 / 24S118 지원·전체 소스·설치 절차가 없음 | 시연에서 현재 기기용 구현을 도출할 수 없음 |
| CVE-2026-111497 / Brotli | 후속 watchOS 27.2.1의 수정 공지, iPhone용 메모리 손상 PoC | Watch 코드 실행·커널·서명·지속성 연결이 없음 | 대상과 연관된 연구 후보이지만 우회 구현은 아님 |
| sn0wbite | QEMU의 가상 Watch에서 사용자 바이너리 실행 | 실제 Ultra 2의 부트·서명 제한을 우회하는 취약점이 아님 | 가상 환경 연구 자료로만 분류 |
| ABrake27 | iPhone 펌웨어 정적 분석·상태 문서·probe | Watch용 구현 아님. 일부 초기 가설은 저자가 철회 | 제목의 AMFI bypass를 완성품으로 볼 수 없음 |
| iOS-Research | iPhone SPTM/TXM 등의 정적 분석과 미완료 과제 | Watch 빌드 지원 없음. TXM 우회 버그도 확정하지 않음 | 아키텍처 참고 자료 |
| AppSync Unified | 탈옥 iOS의 설치·실행 신뢰 검사 후킹 | 먼저 시스템 프로세스 주입 환경이 필요. 현재 Watch 지원 없음 | 초기 접근 없이 가져다 쓸 수 없음 |
| jelbrekTime / OverCl0ck | 구형 워치용 커널·서명 연구 | watchOS 4.1 / 3 및 구형 기기 대상 | 버전·오프셋만 바꿔 현재 워치로 이식할 수 없음 |

## 1. 과거 실물 워치의 영구 서명은 실제 연구 사례

LIJI32의 **2024-03-16 원문**은 watchOS 8.3에서 `CVE-2022-46689`와 `CVE-2022-26766`을 결합해 영구 서명 앱을 설치했다고 설명합니다. 따라서 워치에서 이런 구조가 원리적으로 불가능하다고 말하는 것은 부정확합니다. 다만 현재 버전에 맞는 구현과는 다릅니다. [연구자 원문](https://x.com/LIJI32/status/1769120899293159746)

Apple은 CoreTrust 관련 `CVE-2022-26766`을 **watchOS 8.6**, MacDirtyCow `CVE-2022-46689`를 **watchOS 9.2**에서 수정했다고 공지했습니다. 해당 시연을 최근 기사 날짜만 보고 현재 워치의 방법으로 해석하지 않습니다. [8.6 수정 공지](https://support.apple.com/en-us/102759) · [9.2 수정 공지](https://support.apple.com/en-us/102741)

연구자는 당시 제품화 여부가 정해지지 않았고 향후 PoC를 올릴 수 있다고 밝혔습니다. 이번 조사에서는 현재 대상에 적용할 후속 PoC를 확보하지 못했습니다. [후속 원문](https://x.com/LIJI32/status/1769123903585058905)

## 2. 최근 Calif 시연과 공개 구현의 차이

Calif는 **2026-10-26** 워치 시연을 게시했습니다. 원문 텍스트는 짧으며 구체적인 Watch 모델·OS 빌드·사용 취약점·실행 코드를 명시하지 않습니다. 이 게시물만으로 watchOS 27.2용 무갱신 설치법이나 기존 데이터 보존을 결론낼 수 없습니다. [원저자 게시물](https://x.com/calif_io/status/2114716526129627579)

별도의 **2026-10-16 iPhone 시연 글**은 추후 공개를 예고합니다. 이는 이번에 필요한 Watch 전체 코드가 이미 공개됐다는 뜻이 아닙니다. 연구자의 공개 MIE 과제도 대상은 macOS이며 워치에 그대로 사용할 수 없습니다. [iPhone 원문](https://blog.calif.io/p/iphone) · [MIE 연구](https://calif.io/research/apple-mie)

따라서 이 후보의 남은 항목은 현재 기기·빌드 지원과 공개 실행 코드입니다. 비공개 시연 내용을 추측해 설치 프로그램을 만들지는 않았습니다.

## 3. 현재 OS 계열의 새 후보: Brotli

Apple은 **2026-11-09 watchOS 27.2.1**에서 `CVE-2026-111497`을 수정했다고 명시하며 영향은 악성 입력 처리 중 메모리 손상입니다. 이는 27.2 대상 연구에 관련된 단서입니다. 하지만 공지는 Ultra 2에서의 코드 실행이나 영구 서명을 입증하지 않습니다. [Apple 공지](https://support.apple.com/en-us/149722)

Google의 [수정 커밋](https://github.com/google/brotli/commit/0ed4268a4401abcb4472096340477cf4af7d1a2b)과 [1.2.1 변경 이력](https://github.com/google/brotli/blob/v1.2.1/CHANGELOG.md)이 공개돼 있습니다. 라이브러리 취약점의 존재와 특정 OS에서의 전체 탈옥은 다른 범위입니다.

[`MchinaMd57764/CVE-2026-111497-PoC`](https://github.com/MchinaMd57764/CVE-2026-111497-PoC/tree/0899753a85829472ac4a6e63b75655dd91db6fa0)은 iPhone의 `libcompression`과 네트워크 응답 경로를 조사합니다. 작성자가 명시한 한계는 **코드 실행·제어 흐름 탈취·PAC 우회·커널 침해를 시연하지 않았다는 것**입니다. Watch 전용 결과도 아닙니다.

따라서 이 후보를 직접 활용하려면 먼저 해당 Watch에서의 도달 가능한 처리 경로와 실행 제어를 확보하고, 추가 권한·서명 또는 설치 신뢰 검사 우회·재실행 지속성까지 연결해야 합니다. 그 연결 코드가 이번 공개 자료에는 없습니다. 단순 충돌 PoC를 FoldBridge에 추가해도 프로파일 만료는 해결되지 않습니다. PoC를 실행하거나 기기에 전송하지 않았습니다.

## 4. 실행 가능한 공개 코드가 있어도 대상이 다름

**sn0wbite:** `cbfd718646d0f76a1738fc20fce215361a4f49c9`의 문서는 가상 `Watch7,11`에서 커널·램디스크·trust cache를 수정하고 사용자 바이너리를 실행하는 흐름을 설명합니다. 저자도 물리 Apple Watch 취약점이 제공되는 프로젝트로 설명하지 않습니다. 가상 환경에서 부팅 전에 바꿀 수 있는 파일을 실물 워치에서도 바꿀 수 있다고 가정할 수 없습니다. [소스와 상태](https://github.com/andrei-borcea/sn0wbite/tree/cbfd718646d0f76a1738fc20fce215361a4f49c9)

**ABrake27:** `a9ebd52ab4342f5f2c22d885fd3afa9711f5aad7`의 `WHITEPAPER.md` 제목은 AMFI bypass를 표방하지만, 최신 `STATUS.md`는 대상이 iPhone 13 / iOS이며 남은 작업이 정적 분석이라고 명시합니다. 특히 초기 VFS TOCTOU 가설은 함수 주소 오인으로 철회됐습니다. 별도 probe 앱은 ImageIO 입력 동작을 살피는 앱으로, 영구 서명 도구가 아닙니다. 일부 가설의 철회를 모든 연구가 거짓이라는 의미로 확대하지도 않습니다. [권위 상태 문서](https://github.com/vvirei333/ABrake27/blob/a9ebd52ab4342f5f2c22d885fd3afa9711f5aad7/STATUS.md) · [Probe 설명](https://github.com/vvirei333/ABrake27/blob/a9ebd52ab4342f5f2c22d885fd3afa9711f5aad7/poc/probe_app/README.md)

**iOS-Research:** `a3416a5f062e404c0688cf9aaa8064b422cfb3eb`의 상태 문서는 TXM 관련 조사에서 확정한 우회 버그가 없다고 설명합니다. iPhone 보호 구조의 연구를 Ultra 2 / 24S118의 정확한 구조나 우회 성공으로 치환하지 않습니다. [상태 문서](https://github.com/AzozzALFiras/iOS-Research/blob/a3416a5f062e404c0688cf9aaa8064b422cfb3eb/STATUS.md)

## 5. 직접 구현에 빠져 있는 부분

경로는 두 종류로 구분해야 합니다.

- **서명 검증 논리 버그 경로:** 현재 watchOS의 실제 서명 검사 결함 + 기존 앱에 적용할 설치/등록 경로 + 실행·만료 검사 처리 + 재부팅 뒤 유지가 필요합니다. 이론상 전체 커널 탈옥이 필수인 것은 아니지만 현재 사용할 논리 버그와 적용 코드가 없습니다.
- **권한 상승 경로:** 현재 빌드에서의 접근·실행 권한 + 서명/설치/실행 신뢰 경계 처리 + 재부팅 후 복원 경로가 필요합니다. 커널 메모리를 읽거나 쓰는 하나의 PoC만으로 모두 충족됐다고 볼 수 없습니다.

[AppSync](https://github.com/akemin-dayo/AppSync)는 iOS에서 설치 검사와 실행 시 만료 검사를 서로 다른 후킹으로 처리합니다. 먼저 탈옥된 환경의 시스템 프로세스 주입이 필요하므로, 이 코드를 일반 Watch 앱에 링크하는 것으로 같은 효과를 얻을 수 없습니다. [jelbrekTime](https://github.com/tihmstar/jelbrekTime)과 [OverCl0ck](https://github.com/PsychoTea/OverCl0ck)도 구형 버전의 시작 지점과 가정에 의존합니다.

FoldBridge는 앱 `dev.foldbridge.watch`와 확장 `dev.foldbridge.watch.widgets`를 함께 사용합니다. 앱 하나의 실행만 가능해져도 WidgetKit 확장과 재실행까지 해결된 것은 아닙니다. 기존 등록·키·설정을 보존하려면 앱 식별자·키체인 접근 관계·데이터 컨테이너를 유지하는 적용 경로도 있어야 합니다. 이번 후보 중 그 전체를 현재 기기에 제공하는 구현은 없습니다.

## 결과와 다음에 필요한 자료

이번 조사로 **관련 연구의 구체적인 후보와 누락된 구현 구간**은 정리했습니다. 그러나 기존 앱·페어링을 유지하는 무료 무갱신 기능은 아직 구현되지 않았습니다. 빌드 설정만 바꾸거나 오래된 우회 코드를 가져다 붙이는 작업으로 해결될 상태가 아닙니다.

새 자료가 나온다면 우선 볼 것은 현재 물리 Watch 빌드의 공개 진입 코드, 서명/만료 처리 코드, 재부팅 이후 유지 방식입니다. 이를 확보하기 전에는 무료 영구 실행을 약속하거나 기존 설치를 교체하지 않습니다. 이번 요청을 자동 갱신 예약 재개나 외장 어댑터 도입으로 대체하지 않았습니다.

## 추가 조사: 기존 앱·페어링 유지 조건의 오픈소스 목록

사용자의 후속 요청에 따라 Exa로 **18회 추가 검색, 결과 90개(중복 포함), 서로 다른 URL 68개**를 조사했습니다. 이는 앞선 95개 결과와 별도의 검색 집계이며, 두 집계를 더한 수가 독립된 출처 수라는 뜻은 아닙니다. 네 주제는 Watch 설치기, 만료·신뢰 우회, 기존 서명 호스트 재사용, 갱신·페어링 도구의 기능 경계입니다.

**쉽게 말하면: 앱의 만료를 없애거나 만료 검사를 바꾸는 관련 소스는 있습니다. 하지만 현재 Ultra 2 / watchOS 27.2에서 기존 설치와 페어링을 유지하는 완성품은 이번에도 확보하지 못했습니다.** 추가 검색에서도 기기 변경이나 코드 실행은 하지 않았습니다.

| 프로젝트·소스 | 실제 기능 | 현재 조건에서 제외되는 이유 |
| --- | --- | --- |
| [AppSync Unified](https://github.com/akemin-dayo/AppSync) | 설치 서명 검사와 실행 시 만료 검사를 후킹 | 탈옥 iOS용 시스템 프로세스 주입 환경이 선행됨. 현재 Watch 포트 없음 |
| [TrollStore](https://github.com/opa334/TrollStore) / [ChOma](https://github.com/opa334/ChOma) | 구버전 CoreTrust 결함을 이용한 영구 설치·서명 조작 | 지원 목록과 구현은 특정 iOS 대상. 현재 Watch 지원을 제공하지 않음 |
| [Permasigner](https://github.com/permasigner/permasigner) | 구버전 iOS의 CoreTrust 기반 패키지 생성 | 대상 기기의 초기 탈옥과 취약한 iOS가 필요. Windows에서 실행 가능해도 Watch OS 지원이 생기지 않음 |
| [MissedRevoke](https://gist.github.com/khanhduytran0/e3ae92673a1acfe85ce5a50b59d28361) | `mis.db`의 신뢰·만료 기록을 다루는 공개 SQL·샘플 | iOS 26 계열 설명이며 만료 앱 실행에는 날짜 되돌리기가 남음. 현재 Watch용 적용 경로 없음 |
| [Omega](https://github.com/jailbreakdotparty/Omega) | iOS 인증서 차단 기록을 partial restore로 변경 | 원저자가 iOS 27 미지원·데이터 유지 불가를 명시. Watch 포트도 아님 |
| [NoMoreExpire 소스](https://github.com/antiquedev/Tweaks/blob/e6d6b80cea02a27863f445b24d57516fecd5e986/NoMoreExpire/Tweak.xm) | `SBApplication`의 프로파일 관련 응답을 후킹하는 짧은 코드 | Watch용 실행·설치·재부팅 처리 없음. 현재 기기의 만료 우회 성공 근거 아님 |
| [Anti-Apple-Revoke](https://github.com/utsur0/Anti-Apple-Revoke) | 기업용 인증서의 온라인 폐기 확인을 차단하는 목록 | 현재 Personal Team 프로파일의 로컬 7일 만료를 없애는 구현이 아님 |
| [SideStore](https://github.com/SideStore/SideStore) / [Splice](https://github.com/franklintra/splice) | 서명·프로파일 갱신 자동화. Splice에는 구버전 CoreTrust 분기도 있음 | 일반 사용은 갱신을 계속함. 영구 설치 분기도 현재 Watch 대상이 아님 |
| [ReProvision Reborn](https://github.com/sohsatoh/ReProvision-Reborn) | 탈옥 iPhone에서 Watch 앱 재서명 지원 | Watch 지원 문구는 있지만 무갱신이 아닌 재서명이며 iPhone 실행 환경 필요 |
| [iLoader Watch 포크](https://github.com/AndreySemjonov/iloader) | iPhone을 통한 Watch companion 설치 | 설치와 무갱신은 다름. 자동 Watch 갱신도 명시적으로 미지원 |
| [LiveContainer](https://github.com/LiveContainer/LiveContainer) | 서명된 iOS 호스트 안에서 앱 실행 | watchOS 호스트가 아니며 게스트 위젯·확장도 일반적으로 미지원 |
| [WatchBox](https://github.com/34306/WatchBox) / [WatchFix](https://github.com/577fkj/WatchFix) / [watched](https://github.com/34306/watched) | iPhone–Watch 버전·페어링 호환성 변경 | FoldBridge 만료를 없애지 않으며 일부 절차는 재페어링을 요구 |

### 새로 찾은 핵심 자료: MissedRevoke

원저자 Gist 고정점은 [`3d15c8d63f7b6f2e71b9086f4cb9e099c786fe16`](https://gist.github.com/khanhduytran0/e3ae92673a1acfe85ce5a50b59d28361/3d15c8d63f7b6f2e71b9086f4cb9e099c786fe16)입니다. 공개 파일은 `_MissedRevoke.md`와 `misdb.sql` 두 개입니다. 별도 라이선스 파일이나 완성된 Watch 앱이 제공되는 자료로 분류하지 않습니다.

이 자료는 만료 기록의 수정을 막는 SQL trigger를 제시하므로 목표와 직접 관련됩니다. 하지만 원문은 다음 한계를 남깁니다.

- 설치·실행 시의 시간 검사가 별도로 남아 **날짜를 과거로 바꾸는 조작**이 필요합니다. 날짜 조작 없이 계속 자동 실행된다는 의미가 아닙니다.
- 예시는 새 데이터베이스를 만들고 iOS의 `MobileDeviceDomain` partial restore 경로로 전달합니다. 현재 워치의 기존 데이터베이스를 보존하는 마이그레이션·적용 코드는 없습니다.
- 원저자는 iOS 27에서 partial restore 경로가 막혔다고 설명합니다. 해당 설명을 watchOS의 동일 경로나 지원 증거로 보지 않습니다.

따라서 이 소스는 **만료 데이터 처리의 연구 참고 자료**이지, 현재 워치에 적용할 수 있는 무료 무갱신 기능은 아닙니다. 시스템 날짜나 데이터베이스를 바꾸지 않았습니다.

### 소스 수준에서 확인한 구분

- AppSync 고정점 [`235aca6cddfbdc9fa87fcb5b2aec2df37ed6d65a`](https://github.com/akemin-dayo/AppSync/blob/235aca6cddfbdc9fa87fcb5b2aec2df37ed6d65a/AppSyncUnified-FrontBoard/AppSyncUnified-FrontBoard.x)의 실행 시 후킹은 신뢰 상태 응답을 바꿉니다. 이는 운영체제 프로세스에 주입되는 코드이며 일반 FoldBridge 앱 내부의 함수로 대체할 수 없습니다.
- Splice 고정점 [`7968bb190ffe4f1aa0bac1b8da6fd3003af072be`](https://github.com/franklintra/splice/blob/7968bb190ffe4f1aa0bac1b8da6fd3003af072be/frontends/cli/source/trollstore.d)의 영구 설치 상태 판단은 iOS 취약 버전에 관한 것입니다. `--permanent` 옵션 이름이 현재 watchOS 지원을 뜻하지 않습니다.
- [LiveContainer FAQ](https://livecontainer.github.io/docs/faq)는 게스트 위젯·확장을 일반적으로 지원하지 않는다고 명시합니다. 현재 차량 제어 WidgetKit 확장을 유지하는 해결책으로 제시하지 않습니다.
- [SideStore FAQ](https://docs.sidestore.io/docs/faq)는 7일 기간을 갱신한다고 명시합니다. [NoFreeAppLimit](https://havoc.app/package/nofreeapplimit)의 3개 앱 제한 해제는 시간 제한 해제와 다른 기능입니다.
- Netskao/AntiProfilesRevoke는 검색 색인에 남아 있지만 이번 직접 GitHub API 접근은 404였습니다. 색인만으로 지금 받을 수 있는 유지보수 중 소스라고 표시하지 않습니다. 별도 Anti-Revoke 2도 무료 패키지 소개만으로 공개 소스·Watch 지원을 인정하지 않습니다.

자료를 검토한 결과, **원하는 기능의 연구 재료는 존재하지만 현재 요구를 충족하는 Watch용 오픈소스 제품은 미확보**라는 결론입니다. 기존 설치·페어링은 그대로이며 무갱신 기능을 구현·설치한 것으로 보고하지 않습니다.
