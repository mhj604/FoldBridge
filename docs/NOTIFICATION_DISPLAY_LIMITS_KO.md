# 알림 표시 범위와 이전 조사

**한국어** · [English](NOTIFICATION_DISPLAY_LIMITS_EN.md) · [전체 문서](README.md)

현재 Watch **0.4.7 / 빌드 21**은 시스템 팝업·카드·상단 헤더에 FoldBridge를 표시하고, 원본 앱 아이콘은 펼친 본문에 24pt로 표시합니다. 아이콘·글씨 위치를 유지하며 카드 아래 여백만 4pt 줄였습니다. [현재 화면 예문](NOTIFICATION_LAYOUT_COMPARISON_KO.md) · [최신 배포 안내](RELEASE_WATCH_v0.4.7_KO.md)

아래는 0.4.3 당시의 조사 기록입니다. 당시 설치 상태·계정 조사와 현재 사용법을 구분해 주세요.

후속 Watch 0.4.5 / 빌드 16은 실제 시뮬레이터 기본 알림과 비교해 글꼴·줄 높이·본문 폭·위치를 추가 조정했다. [측정 결과와 화면](NOTIFICATION_LAYOUT_COMPARISON_KO.md). 아래의 모든 단계 시스템 아이콘 요구는 이번 변경 범위에서 제외됐다.

후속 변경: 사용자가 모든 단계의 원본 아이콘 교체 요청을 제외하고, 작은 원본 아이콘을 유지하며 상세 본문의 글씨 위치·간격을 기본 알림에 최대한 맞추는 작업을 요청했다. Watch 0.4.4 / 빌드 15는 그 범위의 레이아웃 조정이다. 아래 내용은 이전의 완전 동일 레이아웃·모든 단계 원본 아이콘 요구에 대한 0.4.3 시점 조사 기록이다.

Watch 0.4.3 / 빌드 14 기준. 상세 본문의 작은 원본 아이콘과 텍스트는 사용자가 정상 표시된다고 보고했다. 다음 두 요청은 아직 구현되지 않았다.

- 첫 요약 팝업과 눌러 펼친 화면을 동일한 레이아웃으로 표시하기
- 첫 팝업·알림 센터 카드·상세 화면 모두에서 원본 Android 앱 아이콘 사용하기

## 화면마다 누가 표시하는가

| 영역 | 표시 주체 | 현재 표시 | 앱에서 가능한 변경 |
| --- | --- | --- | --- |
| 첫 요약 팝업(short-look) | watchOS | FoldBridge 아이콘·이름, 알림 제목 | 제목 제공. 시스템 템플릿 자체는 변경 불가 |
| 알림 센터의 기본 카드 | watchOS | FoldBridge 앱에 속한 알림 | 제목·내용·묶음 ID 제공. 일반 알림별 원본 앱 아이콘 지정 API는 없음 |
| 펼친 화면의 상단 sash | watchOS | FoldBridge 아이콘·이름 | 지원되는 색상·흐림 속성. 다른 앱으로 발신 주체 교체 불가 |
| 펼친 화면의 본문 | FoldBridge SwiftUI | 원본 앱 이름·제목·본문, 24pt 원본 아이콘 | 본문 레이아웃·이미지 변경 가능 |

Apple은 short-look을 시스템이 생성하며 사용자 정의할 수 없다고 명시한다. long-look은 별도의 스크롤 화면이고 본문을 사용자 정의할 수 있다. 따라서 SwiftUI 본문을 수정하는 것으로 두 단계의 전체 레이아웃을 같게 만들 수는 없다. [알림 표시 구조](https://developer.apple.com/documentation/watchos-apps/presenting-notifications-on-apple-watch)

## 추가로 조사한 통신 알림

`UNNotificationContent.updating(from:)`와 `INSendMessageIntent`의 알림 콘텐츠 제공은 watchOS 8 이상에서 지원된다. 메시지 발신자의 아바타를 시스템 알림에 표현하는 별도 경로다. API가 SDK에 있다는 사실만으로 현재 서명 계정에서 사용할 수 있다는 뜻은 아니다. [콘텐츠 업데이트 API](https://developer.apple.com/documentation/usernotifications/unnotificationcontent/updating(from:))

Apple 구현 문서는 Communication Notifications 기능, 지원하는 intent의 `NSUserActivityTypes` 선언, 발신자·참여자 정보와 상호작용 기부를 요구한다. 목적은 사람 간 메시지·통화이며 모든 일반 앱 알림의 아이콘 교체 기능이 아니다. 모든 시스템·쇼핑·금융 알림을 사람의 메시지로 바꾸면 알림의 의미와 Focus 처리가 달라진다. [통신 알림 구현](https://developer.apple.com/documentation/usernotifications/implementing-communication-notifications)

Apple의 watchOS 지원표에서 Communication Notifications는 유료 프로그램에 지원 표시가 있고 무료 Apple Developer 열에는 없다. 현재 Personal Team으로는 이 경로를 사용할 수 없다. 유료 가입을 하더라도 모든 알림 단계의 아이콘·배치를 요구대로 제어할 수 있다는 근거는 없다. [watchOS 권한 지원표](https://developer.apple.com/help/account/reference/supported-capabilities-watchos/)

## 다시 사용하지 않는 방식

- 원본 앱 그림을 `UNNotificationAttachment`에 넣기: 시스템이 미디어로 표시해 팝업의 그림이 커지고 카드 썸네일에 재사용됐던 방식이다. PNG 크기를 줄이는 것으로 시스템 표시 영역을 제어할 수 없다.
- 상세 본문의 그림 변경을 시스템 앱 아이콘 교체로 설명하기: 서로 다른 영역이며 전체 요청을 해결한 것이 아니다.
- 일반 알림을 모두 사람 간 메시지로 취급하기: 일반 알림을 원래 앱에서 온 시스템 알림으로 바꾸는 API가 아니다.

## 당시 배포 상태 (0.4.3)

이 조사는 앱 수정·설치 완료를 의미하지 않는다. 설치된 Watch 0.4.3 / 빌드 14와 Galaxy 0.5.0은 유지한다. 작동 중인 상세 본문을 다시 변경하거나 테스트 알림을 보내지 않았다. 무료 서명·일반 watchOS 앱·서버와 아이폰 없는 사용이라는 현재 조건에서 두 요청을 모두 충족하는 지원 API 경로는 찾지 못했다.

## REA로 배포 산출물 분석

사용자 요청에 따라 기존 REA 6.8.0 CLI로 빌드 14의 로컬 `.app`과 실행 코드를 읽었다. 소스만 읽은 결과를 REA 결과라고 부르지 않으며, 이 분석은 워치 화면의 실시간 관찰이 아니다.

| REA 작업 | 관찰 | Evidence ID |
| --- | --- | --- |
| `inspect-plist` | 버전 0.4.3 / 14, `dev.foldbridge.watch`, 기본 아이콘 `FoldBridgeIcon` | `ev_6208e9f430e3f9a74f8d59ba0baac03093f6bfba93ba1d2cbaccee012cbb9530` |
| `inspect-macho` — 실행 파일 | 앱 시작 파일은 `@rpath/FoldBridge.debug.dylib`를 로드 | `ev_a4d6004a4b9244ae58cabd784bc2fe5c698ea680ce1ca194f40d59d98779f3e3` |
| `inspect-macho` — 실제 디버그 코드 | `WKNotificationScene` 및 `UNNotificationRequest`·`UNUserNotificationCenter` 의존성 | `ev_8faec91328de28e10e45ff1ba0175b4c131f3b8cf239ec992320ac072c60545f` |
| `inspect-asset-catalog` | 컴파일된 카탈로그의 이미지 이름은 `FoldBridgeIcon`, 1024px 아이콘 | `ev_4d07718e6a05a01bae3606a81f6471575e3e270f14a5b70132ae92d51526d707` |

별도로 소스에서는 원본 아이콘을 저장한 뒤 알림 카테고리를 정하고, 같은 알림 요청을 시스템에 한 번 등록하는 순서를 읽었다. 최초 표시와 나중 표시를 위해 서로 다른 아이콘 카테고리를 번갈아 등록하는 코드는 이 경로에 없다. 이는 코드의 순서에 대한 관찰이며 실제 시스템 화면이 언제 전환되는지를 측정한 결과는 아니다.

일반 `codesign` 도구로 읽은 현재 서명에는 `application-identifier`, `com.apple.developer.team-identifier`, `get-task-allow`만 있고 Communication Notifications 권한은 없었다. 이 서명 관찰은 REA가 제공한 Evidence와 구분한다.

### 분석의 한계

- REA의 plist·리소스 관찰은 실행 파일 전체의 해시 식별을 제공하지 않는다. Mach-O 관찰은 각 파일을 별도 해시로 식별한다.
- Mach-O imports/exports는 완전한 심벌 목록이 아니므로 검색 결과가 없다는 이유만으로 모든 비공개 기능의 부재를 주장하지 않는다.
- asset catalog 관찰은 이미지 메타데이터이며 실제 픽셀이나 워치에서 렌더링한 화면을 관찰한 것이 아니다.
- 현재 사용한 REA 경로는 로컬 산출물 분석이다. watchOS 알림 표시를 담당하는 시스템 프로세스를 분석하거나 변경한 것이 아니다.
- REA 분석 결과는 기본 아이콘과 사용자 정의 본문의 경로를 뒷받침한다. 시스템 화면의 변경 가능 범위와 계정 권한의 근거는 위 Apple 문서이며, 이 분석으로 운영체제 권한이 추가되지는 않는다.

현재 남은 문제는 두 요구를 만족할 실제 시스템 표시 경로의 확보다. REA 사용 자체나 문서 업데이트를 앱 문제 해결로 완료 처리하지 않는다.

## 시스템 미러링을 직접 사용하는 대안 조사

- **Accessory Notifications:** Apple 문서는 iPhone 전용이며 iOS 알림을 외부 액세서리로 전달하는 API라고 명시한다. Android 알림을 watchOS 알림 센터에 등록하는 API가 아니다. [Apple 문서](https://developer.apple.com/documentation/accessorynotifications)
- **ANCS:** 공개 규격은 iOS 기기를 알림 제공자, Bluetooth 액세서리를 소비자로 정의한다. 이 규격만으로 Android GATT 서버가 Apple Watch의 기본 미러링 발신 기기가 된다고 판단할 근거는 없다. [ANCS 규격](https://developer.apple.com/library/archive/documentation/CoreBluetooth/Reference/AppleNotificationCenterServiceSpecification/Introduction/Introduction.html)
- **네이티브 프로토콜 재현 프로젝트:** `apple_watch_connector`는 시스템 bulletin 전달 경로를 구현하고 있다. 그러나 Android 설치 경로는 root가 있는 OnePlus CPH2653으로 제한된다. `RootBluetoothHalHost.validateInvocation()`도 UID 0과 해당 제조사·모델을 요구한다. 현재 Galaxy Z Fold7에서 사용할 수 있는 구현이 아니다. [프로젝트 설치 조건](https://github.com/LordixDemon/apple_watch_connector#en-android-install), [실제 조건 코드](https://github.com/LordixDemon/apple_watch_connector/blob/main/apple-watch-bridge/hal/src/main/java/dev/applewatchandroid/bridge/RootBluetoothHalHost.java)
- **Android 36 공개 소켓 API:** `BluetoothSocketSettings`가 추가됐지만 새 생성 API가 지원하는 소켓은 RFCOMM과 LE이며 LE PSM 범위는 128–255다. Bluetooth classic ERTM과 컨트롤러 접근을 사용하는 위 연구 프로젝트의 전송 계층을 이 API로 그대로 대체할 수 있다는 근거는 없다. [Android API](https://developer.android.com/reference/android/bluetooth/BluetoothSocketSettings.Builder)

위 연구 프로젝트에 `TYPE_SET_SECTION_SUBTYPE_ICON = 14` 상수는 있지만, 해당 상수가 있다는 사실만으로 원본 아이콘을 모든 알림 단계에 표시하는 완성된 기능을 입증하지는 않는다. 현재 조회한 Java 소스에서는 상수 선언과 상수 값 테스트 외의 참조를 찾지 못했다. 이 프로젝트의 소스 조사는 REA의 바이너리 분석과 별도로 수행했다.

따라서 현재 지원되는 기기·계정·서버 없는 사용 조건을 유지하면서 시스템 알림의 발신 앱 아이콘과 전체 레이아웃을 변경할 구현 경로는 아직 확보하지 못했다. 프로토콜 재현을 일반 앱 UI 수정처럼 설명하거나, 지원하지 않는 갤럭시에 해당 실험 구현을 설치하지 않는다.
