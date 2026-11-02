# FoldBridge Local

**한국어** · [English](README.en.md) · [전체 문서](docs/README.md)

갤럭시에 도착한 알림을 **Apple Watch로 직접 전달**하는 Android·watchOS 앱입니다. 두 기기는 Bluetooth LE로 통신하며, 알림 전달에 서버·인터넷·페어링된 아이폰을 사용하지 않습니다. 루팅·운동·오디오 세션도 사용하지 않습니다.

워치의 최초 설정과 개발용 앱 설치에는 Apple의 기기 등록과 Mac/Xcode가 필요합니다. 위치 세션을 이용하는 백그라운드 수신은 실험 기능이며, watchOS가 앱을 중단할 수 있어 모든 알림의 상시·즉시 수신을 보장하지는 않습니다.

<img src="watch/FoldBridge/Assets.xcassets/FoldBridgeIcon.appiconset/FoldBridgeIcon.png" width="96" alt="FoldBridge 앱 아이콘">

## 바로 시작하기

**[최신 배포 파일](https://github.com/mhj604/FoldBridge/releases)** · **[자주 묻는 질문](docs/FAQ_KO.md)** · **[English setup](docs/QUICK_START_EN.md)**

| 항목 | 현재 버전 / 링크 |
| --- | --- |
| 사용·수정용 브랜치 | [`local-ble`](https://github.com/mhj604/FoldBridge/tree/local-ble) — 서버 없는 BLE 구성 |
| Android | **0.5.4-local · 코드 15** / [APK 바로 다운로드](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-Local-0.5.4.apk) |
| Apple Watch | **0.4.9 · 빌드 23** / [Xcode 프로젝트](watch/FoldBridge.xcodeproj) |
| 배포 묶음 | [GitHub Releases](https://github.com/mhj604/FoldBridge/releases) · [한글·영어 문서 ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-0.4.9-guides-ko-en.zip) |
| 처음 설치하는 경우 | **[처음부터 설치하고 연결하기](docs/QUICK_START_KO.md)** |
| 연결이 끊긴 경우 | **[새로고침·문제 해결](docs/TROUBLESHOOTING_KO.md)** |

1. 갤럭시에 APK를 설치하고 **근처 기기·알림·알림 접근**을 허용합니다.
2. Mac에서 소스를 받아 `watch/FoldBridge.xcodeproj`를 Xcode로 엽니다. 자신의 Team과 고유한 Bundle ID를 선택해 실제 워치에 설치합니다. 다른 사람의 워치 서명 파일을 그대로 설치하는 방식은 아닙니다.
3. 갤럭시 **설정 → 새 워치 등록**, 워치 **휴대폰 연결 → 휴대폰 찾기**에서 서로 선택합니다. 코드가 같으면 양쪽에서 확인합니다.
4. 워치에서 알림 표시를 허용합니다. 원하는 경우 **설정 → 연결 유지**를 켜고 위치 권한을 허용합니다.
5. 연결이 풀리면 **갤럭시 또는 워치 한쪽의 ‘연결 새로고침’**을 누릅니다. 기존 등록과 대기 알림은 보존됩니다.

```sh
git clone --branch local-ble https://github.com/mhj604/FoldBridge.git
cd FoldBridge
open watch/FoldBridge.xcodeproj
```

`main`에도 최신 소스와 한국어·영어 문서를 반영합니다. `relay/`, `windows/`, `legacy/`는 과거 구성으로 현재 Local 앱 실행에는 필요하지 않습니다.


## 갤럭시를 통한 마이현대 차량 제어

Android **0.6.0-local** / Watch **0.5.0**에는 **FoldBridge 워치 → BLE → 갤럭시 공식 마이현대 위젯** 연결 기능이 추가되었습니다. 기존 워치 마이현대의 아이폰 연동을 변경하지 않습니다. 갤럭시에서 위젯을 연결하고 표시할 버튼을 선택한 후 워치의 **차량 제어**를 사용합니다. 실제 차량 서비스에는 인터넷과 마이현대 인증이 필요하며 위젯 호출은 차량 성공 응답과 다릅니다. **[설정과 동작 범위](docs/VEHICLE_CONTROL_KO.md)** · [0.6.0 APK](artifacts/android/FoldBridge-Local-0.6.0.apk)

## 한국어 / English 전환

갤럭시와 워치 앱의 **설정 → 언어 / Language**에서 **시스템 설정·한국어·English**를 선택합니다. 각 기기에서 따로 선택하며, 재실행과 재시작 후에도 유지됩니다. 시스템 설정을 선택하면 한국어 환경은 한국어, 그 외 환경은 영어를 사용합니다.

버튼·설정·연결 상태·오류 안내·진단과 앱 자체 연결 알림을 번역합니다. 다른 앱에서 전달받은 알림 제목·본문·앱 이름은 원문 그대로 유지합니다. 언어를 변경해도 등록 키와 미전달 알림을 지우지 않습니다. OS가 표시하는 권한 창은 해당 기기의 시스템 언어 설정을 따를 수 있습니다.

## 무엇을 할 수 있나요?

- 다른 앱의 제목·본문·원본 앱 아이콘을 암호화해 워치로 전달합니다. 모든 앱 전달이 기본이며 앱 선택도 가능합니다.
- 알림은 워치 **알림 센터**에 표시합니다. FoldBridge 내부에 이전 메시지 목록이나 본문을 따로 보관하지 않습니다.
- 미확인 알림은 현재 연결 중에만 메모리에서 재시도합니다. 연결이 끊기면 대기열을 비우고 디스크에 저장하지 않습니다.
- 최초 등록뿐 아니라 재연결 때도 인증 완료 시점을 기준으로 시작합니다. 그 전에 게시된 알림과 연결이 끊긴 동안의 알림은 나중에 몰아서 보내지 않습니다.
- 충전율 변경 때 반복되던 Samsung System UI 충전 알림은 기본 제외합니다. **충전 상태 알림**을 켜면 포함합니다.
- 저장된 등록은 watchOS Core Bluetooth 자동 재연결 요청과 앱 재시도를 함께 사용합니다. Bluetooth 범위를 벗어나 링크가 끊겨도 다시 가까워지면 재연결을 시도합니다. 전파 간섭·전원·OS 실행 제한 때문에 연결 단절이나 복구 지연 자체를 막거나 즉시 복구를 보장할 수는 없습니다.
- **연결 새로고침**은 정상 연결에서 암호화된 갱신 요청을 보내 기존 연결과 세션을 유지합니다. 연결이 없으면 저장된 상대에 재접속합니다. **지금 동기화**는 이미 연결된 상태에서 미전달 알림을 가져옵니다.

## 알림 모양과 개인정보 표시

현재 0.4.9은 작은 원본 아이콘과 펼친 본문 배치를 유지합니다. 첫 요약 팝업과 상세 화면의 전체 디자인을 동일하게 만들거나 시스템 아이콘을 알림별로 교체하는 기능은 제공하지 않습니다. 이전 요청의 조사 결과는 [알림 표시 범위](docs/NOTIFICATION_DISPLAY_LIMITS_KO.md)에 기록했습니다.

처음 뜨는 팝업과 알림 센터 카드의 시스템 아이콘은 **FoldBridge**입니다. 원본 앱 아이콘이 있으면 **눌러 펼친 본문에만 24pt**로 표시합니다. 원본 아이콘이 없는 알림은 기본 텍스트 화면을 사용합니다.

원본 아이콘은 사진 첨부로 보내지 않습니다. 따라서 큰 미디어 미리보기나 카드 썸네일로 재사용되지 않습니다. 아이콘이 있는 상세 본문은 왼쪽 16pt 기준선을 유지하고, 기본 16pt 글자·0pt 추가 문단 간격·18.5pt 본문 줄 높이로 조정했습니다. 원본 아이콘은 텍스트 행 높이에 영향을 주지 않습니다. watchOS 27의 본문 시작점을 보정했습니다. 0.4.6에서 아이콘과 글씨를 함께 3pt 아래로 옮긴 위치는 유지하고, 0.4.7에서는 카드의 아래 여백만 4pt 줄였습니다. [기본 알림과 비교한 화면·측정 결과](docs/NOTIFICATION_LAYOUT_COMPARISON_KO.md)를 참고하세요. 확장 프레임·중첩 스크롤·고정 본문 높이를 사용하지 않습니다. 제목과 본문은 시스템 글꼴로 줄바꿈하고, 스크롤과 닫기 버튼은 watchOS가 처리합니다. [Apple 알림 표시 구조](https://developer.apple.com/documentation/watchos-apps/presenting-notifications-on-apple-watch)

Android가 민감한 본문을 가리면 워치에도 가림 문구가 전달됩니다. 본문 전체 전달을 원하는 사용자는 자신의 기기에서 앱별 수신 설정을 할 수 있습니다. **[민감한 알림 본문 허용](docs/BUILD_AND_SETUP.md#민감한-알림-본문-허용)**을 참고하세요. APK가 이 설정을 스스로 부여하지 않습니다.

알림 내용·개인 키·위치 좌표를 진단 파일이나 이 저장소에 올리지 않습니다. 위치 연결 유지에서도 좌표는 저장하거나 전송하지 않습니다.

## 환경과 한계

| 환경 | 필요 사항 |
| --- | --- |
| 갤럭시 / Android | Android 13 이상, BLE peripheral/광고 지원, 근처 기기와 알림 접근 허용 |
| Apple Watch | watchOS 10 이상 대상으로 빌드, Bluetooth와 알림 권한. 실제 사용 기기는 Ultra 2 / watchOS 27 계열 |
| 워치 앱 설치 | Mac, 기기 OS에 맞는 Xcode, 자신의 Apple 개발 Team, 개발자 모드와 Mac 개발용 페어링 |
| Apple 계정 | 무료 Personal Team 사용 가능. 갤럭시와 워치 계정을 맞출 필요는 없습니다. 워치 설치 서명은 자신의 Team을 사용합니다. |

워치 개발용 서명은 만료에 따라 재서명이 필요할 수 있습니다. 위치 세션은 배터리를 더 사용하며, 강제 종료·OS의 실행 예산·Bluetooth 범위·집중 모드·알림 권한은 수신에 영향을 줍니다. 읽음/삭제의 양방향 동기화와 답장은 구현하지 않았습니다.

## 직접 빌드하거나 기여하기

- [설치·연결 순서](docs/QUICK_START_KO.md)
- [빌드 도구·서명·민감한 알림 설정](docs/BUILD_AND_SETUP.md)
- [문제 해결과 새로고침 사용법](docs/TROUBLESHOOTING_KO.md)
- [구조](docs/ARCHITECTURE.md) / [BLE 프로토콜](docs/PROTOCOL.md)
- [변경 이력](CHANGELOG.md) / [전체 구축 이력](docs/DEVELOPMENT_HISTORY.md)
- [기여 방법](CONTRIBUTING.md)

Android APK는 저장소와 Releases에서 내려받을 수 있습니다. Apple 서명 프로파일·Android 서명 키·기기 로그는 공개하지 않습니다. 자기 키로 빌드한 Android 앱은 배포 APK와 서명이 달라 같은 앱 위에 업데이트할 수 없습니다. **[서명과 업데이트 안내](docs/QUICK_START_KO.md#업데이트할-때)**를 먼저 읽어 주세요.
