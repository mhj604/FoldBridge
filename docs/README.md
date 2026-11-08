# FoldBridge 문서 / Documentation

**[한국어 홈](../README.md)** · **[English home](../README.en.md)** · **[다운로드 / Downloads](https://github.com/mhj604/FoldBridge/releases)**

처음 사용하는 분은 **빠른 시작**부터 읽어 주세요. 현재 배포는 **Android 0.6.7-local / 코드 23**, **Watch 0.5.8 / 빌드 32**입니다.

New users: start with **Install and connect**. Current release: **Android 0.6.7-local / code 23**, **Watch 0.5.8 / build 32**.

직전 연결 코드 복원 / Restore the preceding connection code: [Android 0.6.9 / Watch 0.5.12 한국어](ROLLBACK_0.5.12_KO.md) · [English](ROLLBACK_0.5.12_EN.md).

이전 후보의 자동 연결·거리 복귀·프로세스 복원 / Previous candidate automatic connection, range return and process recovery: [Android 0.6.10 · Watch 0.5.13 한국어](WATCH_0.5.13_AUTOMATIC_RECOVERY_KO.md) · [English](WATCH_0.5.13_AUTOMATIC_RECOVERY_EN.md).

백그라운드 인증 재개 수정 / Background authentication recovery: [Android 0.6.9 · Watch 0.5.12 한국어](WATCH_0.5.12_BACKGROUND_AUTH_KO.md) · [English](WATCH_0.5.12_BACKGROUND_AUTH_EN.md).

앱 실행 후 연결 지연 퇴행 수정 / Foreground reconnection regression fix: [Watch 0.5.11 한국어](WATCH_0.5.11_FOREGROUND_FIX_KO.md) · [English](WATCH_0.5.11_FOREGROUND_FIX_EN.md).

이전 재연결 수정 후보와 미완료 목표 / Previous candidate and unfinished goals: [Android 0.6.8 · Watch 0.5.10 한국어](WATCH_0.5.10_CANDIDATE_KO.md) · [English](WATCH_0.5.10_CANDIDATE_EN.md).

| 내용 / Topic | 한국어 | English |
| --- | --- | --- |
| 개요·다운로드 / Overview and downloads | [시작 화면](../README.md) | [Overview](../README.en.md) |
| 처음 설치·등록 / First installation and registration | [빠른 시작](QUICK_START_KO.md) | [Install and connect](QUICK_START_EN.md) |
| 자주 묻는 질문 / Common questions | [FAQ](FAQ_KO.md) | [FAQ](FAQ_EN.md) |
| 연결·알림 문제 / Connection and notification problems | [문제 해결](TROUBLESHOOTING_KO.md) | [Troubleshooting](TROUBLESHOOTING_EN.md) |
| 빌드·서명·민감한 본문 / Build, signing, sensitive content | [빌드와 설치](BUILD_AND_SETUP.md) | [Build and settings](BUILD_AND_SETUP_EN.md) |
| 무료 계정 워치 서명 갱신 / Free-account watch renewal | [자동 갱신](AUTO_RENEW_KO.md) | [Automatic renewal](AUTO_RENEW_EN.md) |
| 케이블 없는 APK 업데이트 / Wireless APK updates | [무선 설치](WIRELESS_INSTALL_KO.md) | [Wireless installation](WIRELESS_INSTALL_EN.md) |
| 마이현대 차량 제어 / MyHyundai vehicle controls | [위젯 연결과 사용](VEHICLE_CONTROL_KO.md) | [Widget setup and use](VEHICLE_CONTROL_EN.md) |
| 현재 앱 구조 / Current architecture | [구조](ARCHITECTURE.md) | [Architecture](ARCHITECTURE_EN.md) |
| 암호화·BLE·복원 / Encryption, BLE, restoration | [프로토콜](PROTOCOL.md) | [Protocol](PROTOCOL_EN.md) |
| 시스템 아이콘과 본문 / System icons and custom content | [알림 표시 범위](NOTIFICATION_DISPLAY_LIMITS_KO.md) | [Notification display](NOTIFICATION_DISPLAY_LIMITS_EN.md) |
| 알림 화면·배치 이력 / Notification screenshots and layout | [화면 비교](NOTIFICATION_LAYOUT_COMPARISON_KO.md) | [Layout examples](NOTIFICATION_LAYOUT_COMPARISON_EN.md) |
| 미완료 재연결·다음 수정 / Unfinished reconnection work | [최신 복구 결과와 남은 조건](WATCH_0.5.13_AUTOMATIC_RECOVERY_KO.md) | [Latest recovery results and remaining conditions](WATCH_0.5.13_AUTOMATIC_RECOVERY_EN.md) |
| 최신 배포 변경 / Current release changes | [0.5.8 안내](RELEASE_WATCH_v0.5.8_KO.md) | [0.5.8 notes](RELEASE_WATCH_v0.5.8_EN.md) |
| 버전별 변경 / Changes by version | [변경 이력](../CHANGELOG.md) | [Changelog](../CHANGELOG.en.md) |
| 주요 구축 과정 / Development milestones | [구축 이력](DEVELOPMENT_HISTORY.md) | [Development history](DEVELOPMENT_HISTORY_EN.md) |
| 수정·번역·문의 / Contributions, translations, help | [기여 방법](../CONTRIBUTING.md) | [Contributing](../CONTRIBUTING.en.md) |

현재 차량 제어 권장 버전은 Android **0.6.7-local / 23**, Watch **0.5.8 / 32**입니다. / Recommended vehicle-control versions: Android **0.6.7-local / 23**, Watch **0.5.8 / 32**.

## 먼저 알아둘 점 / Before starting

- **사용 중:** 갤럭시와 워치의 Bluetooth로 직접 전달합니다. 서버·인터넷·아이폰 중계가 필요하지 않습니다.
- **최초 준비:** 워치 초기 설정에는 아이폰, 워치 앱 서명·설치에는 Mac/Xcode와 자신의 Apple Team이 필요합니다.
- **업데이트:** Android 서명 키, 워치 Bundle ID와 Team을 유지합니다. 연결 문제에는 먼저 한쪽의 연결 새로고침을 사용합니다.
- **백그라운드:** watchOS 실행 기회와 수신 예산이 적용됩니다. 실행이 중단된 경우 워치 앱을 한 번 열어야 할 수 있습니다.

- **During use:** notification delivery runs directly over Bluetooth; no server, internet, or iPhone relay is needed.
- **Initial setup:** Apple Watch setup needs an iPhone; signing/installing the watch app needs Mac/Xcode and your Apple team.
- **Updates:** retain the Android signing key and watch Bundle ID/team. Try Refresh connection on one device for ordinary connection problems.
- **Background:** watchOS controls runtime opportunities and budgets. Opening the watch app once may be needed after execution stops.

과거 0.4.9 문서 묶음은 [한글·영어 문서 ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-0.4.9-guides-ko-en.zip)에 보존되어 있습니다. 최신 안내는 위 표를 사용하세요. / [Archived 0.4.9 Korean/English guide bundle](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-0.4.9-guides-ko-en.zip) contains the older documentation; use the table above for current guides.

## 이전 문서 / Archives

이전 버전의 `RELEASE_*_KO.md`와 초기 `legacy/` 문서는 한국어 원문으로 보존합니다. 현재 사용법은 위 표의 문서를 따릅니다. 중요한 과거 변경은 두 언어의 변경·구축 이력에 정리했습니다.

Older `RELEASE_*_KO.md` and initial `legacy/` documents remain archived in their original language. Use the guides above for current operation. Significant earlier changes are summarized in both languages' changelog and development history.

- [Watch 0.5.14: 구독 콜백에서 백그라운드 인증 시작](WATCH_0.5.14_SUBSCRIPTION_AUTH_KO.md) · [English](WATCH_0.5.14_SUBSCRIPTION_AUTH_EN.md)
