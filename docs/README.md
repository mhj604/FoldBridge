# WatchBridge 문서 / Documentation

**[한국어 홈](../README.md)** · **[English home](../README.en.md)** · **[현재 버전·남은 작업](CURRENT_STATUS_KO.md)** · **[Current versions and remaining work](CURRENT_STATUS_EN.md)**

2026-11-20 기준: **Android 0.6.23 / 코드 45 · Watch 0.5.29 / 빌드 63**. Android APK 배포 묶음 태그는 `android-v0.6.23`입니다. 워치는 현재 소스를 자신의 Team으로 서명해 설치합니다. / Android APK release bundle: `android-v0.6.23`; sign current Watch source for your own team.

## 현재 사용 안내 / Current guides

| 내용 / Topic | 한국어 | English |
| --- | --- | --- |
| 현재 버전·파일·진행 상태 / Versions, downloads, status | [기준 문서](CURRENT_STATUS_KO.md) | [Current status](CURRENT_STATUS_EN.md) |
| 처음 설치·등록 / First installation | [빠른 시작](QUICK_START_KO.md) | [Install and connect](QUICK_START_EN.md) |
| 연결·알림 문제 / Connection and notifications | [문제 해결](TROUBLESHOOTING_KO.md) | [Troubleshooting](TROUBLESHOOTING_EN.md) |
| 재연결 동작·남은 조건 / Recovery behavior and remaining conditions | [자동 재연결](AUTO_RECONNECT_KO.md) | [Automatic reconnection](AUTO_RECONNECT_EN.md) |
| 자주 묻는 질문 / Questions | [FAQ](FAQ_KO.md) | [FAQ](FAQ_EN.md) |
| 빌드·서명·민감한 본문 / Build, signing, sensitive content | [빌드와 설치](BUILD_AND_SETUP.md) | [Build and settings](BUILD_AND_SETUP_EN.md) |
| 무료 계정 워치 서명 갱신 / Free-account renewal | [주간 Mac 갱신](AUTO_RENEW_KO.md) | [Weekly Mac renewal](AUTO_RENEW_EN.md) |
| 케이블 없는 APK 업데이트 / Wireless APK update | [무선 설치](WIRELESS_INSTALL_KO.md) | [Wireless installation](WIRELESS_INSTALL_EN.md) |
| 마이현대 차량 제어 / Vehicle controls | [위젯 연결과 사용](VEHICLE_CONTROL_KO.md) | [Widget setup and use](VEHICLE_CONTROL_EN.md) |
| 앱 구조 / Architecture | [구조](ARCHITECTURE.md) | [Architecture](ARCHITECTURE_EN.md) |
| 암호화·BLE·복원 / Encryption, BLE, restoration | [프로토콜](PROTOCOL.md) | [Protocol](PROTOCOL_EN.md) |
| 시스템 아이콘과 본문 / Notification display | [표시 범위](NOTIFICATION_DISPLAY_LIMITS_KO.md) | [Display scope](NOTIFICATION_DISPLAY_LIMITS_EN.md) |
| 수정·번역·문의 / Contributing | [기여 방법](../CONTRIBUTING.md) | [Contributing](../CONTRIBUTING.en.md) |

## 버전별 조사와 변경 기록 / Historical investigations and changes

- [Android 0.6.23 양쪽 상태 불일치·새로고침 복구](CONNECTION_RESYNC_0.6.23_KO.md) · [State mismatch and refresh recovery](CONNECTION_RESYNC_0.6.23_EN.md)

- [Android 0.6.21 UI 업데이트 설치](ANDROID_UI_0.6.21_KO.md) · [Android UI update deployment](ANDROID_UI_0.6.21_EN.md)

- [11월 18일 실제 거리 복귀 3회 결과](PHYSICAL_RETURN_2026-11-18_KO.md) · [Three physical range-return cycles](PHYSICAL_RETURN_2026-11-18_EN.md)

- [11월 18일 암호 잠금 중 반복 무선 복구 시험](LOCKED_RECOVERY_TEST_2026-11-18_KO.md) · [Repeated radio recovery during passcode lock](LOCKED_RECOVERY_TEST_2026-11-18_EN.md)

- [워치 0.5.29 잠금 중 콜백·거리 복구 보완](RANGE_RECOVERY_0.5.29_KO.md) · [Locked callbacks and range recovery](RANGE_RECOVERY_0.5.29_EN.md)

- [Android 0.6.20 연결 상태 분리](CONNECTION_STATE_0.6.20_KO.md) · [Retained link and delivery waiting](CONNECTION_STATE_0.6.20_EN.md)

아래는 각 버전 당시의 기록입니다. “현재/완료/실패”를 최신 설치본의 상태로 해석하지 마세요. 최신 상태는 위 기준 문서를 따릅니다. / The following describe their own version/date. Use the current status page for today's behavior and unfinished work.

| 기록 / Record | 한국어 | English |
| --- | --- | --- |
| 0.5.26 화면 진입 기록 / Display-entry journal | [조사](DISPLAY_INVESTIGATION_0.5.26_KO.md) | [Investigation](DISPLAY_INVESTIGATION_0.5.26_EN.md) |
| 0.5.25 충전 필터·표시 / Charging filter and presentation | [변경](QUIET_BACKGROUND_0.5.25_KO.md) | [Changes](QUIET_BACKGROUND_0.5.25_EN.md) |
| 0.5.24 잠금 중 읽기 수신·거리 복구 / Locked read delivery and range recovery | [REA 기록](REA_0.5.24_KO.md) | [REA record](REA_0.5.24_EN.md) |
| 0.5.23 이름 변경·REA 조사 / Rename and REA | [기록](REA_0.5.23_KO.md) | [Record](REA_0.5.23_EN.md) |
| 0.5.22 읽기 우선 인증 / Read-first authentication | [기록](LOCKED_AUTH_0.5.22_KO.md) | [Record](LOCKED_AUTH_0.5.22_EN.md) |
| 손목 들기 화면 복귀 / Wrist-raise presentation | [이력과 추정 정정](WRIST_RAISE_REGRESSION_KO.md) | [History and corrected hypothesis](WRIST_RAISE_REGRESSION_EN.md) |
| 원본 아이콘·본문 배치 / Notification layout | [화면 비교](NOTIFICATION_LAYOUT_COMPARISON_KO.md) | [Layout history](NOTIFICATION_LAYOUT_COMPARISON_EN.md) |
| 버전별 변경 / Changelog | [변경 이력](../CHANGELOG.md) | [Changelog](../CHANGELOG.en.md) |
| 전체 구축 과정 / Milestones | [구축 이력](DEVELOPMENT_HISTORY.md) | [Development history](DEVELOPMENT_HISTORY_EN.md) |

이전 `RELEASE_*`, `WATCH_*`, `ROLLBACK_*` 문서와 [과거 배포 파일](https://github.com/mhj604/WatchBridge/releases)은 그대로 보존합니다. 파일의 과거 버전 번호를 최신 버전으로 바꿔 쓰지 않습니다. / Older version-specific files and release artifacts remain available with their original versions.

## 서명·배포 방식 조사 / Signing and distribution research

- [11월 18일 워치 단독 갱신 소스 후속 조사](RENEWAL_RESEARCH_2026-11-18_KO.md) · [November 18 renewal source follow-up](RENEWAL_RESEARCH_2026-11-18_EN.md)

아래 조사 문서는 사용 가능한 워치 단독 갱신 기능이 구현됐다는 뜻이 아닙니다. / These investigations do not establish an implemented watch-only renewal path.

- [워치 단독 갱신 조사](WATCH_ONLY_RENEWAL_2026-11-15_KO.md) · [Watch-only renewal research](WATCH_ONLY_RENEWAL_2026-11-15_EN.md)
- [Windows·프로파일 갱신 조사](SIGNING_WINDOWS_RESEARCH_KO.md) · [Windows/profile renewal](SIGNING_WINDOWS_RESEARCH_EN.md)
- [배포·앱 구조 대안](NO_WEEKLY_SIGNING_ARCHITECTURE_KO.md) · [Distribution/architecture alternatives](NO_WEEKLY_SIGNING_ARCHITECTURE_EN.md)
- [공개 서명 우회 연구의 범위](WATCHOS_27_SIGNING_BYPASS_RESEARCH_KO.md) · [Scope of public signing-bypass research](WATCHOS_27_SIGNING_BYPASS_RESEARCH_EN.md)
