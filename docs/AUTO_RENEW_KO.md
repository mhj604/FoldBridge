# 무료 계정 워치 앱 자동 갱신

**한국어** · [English](AUTO_RENEW_EN.md) · [문서](README.md)

무료 Personal Team의 7일 유효기간을 없애는 기능이 아닙니다. Mac에서 기존 Xcode 계정으로 새 프로파일을 요청하고 같은 앱·위젯을 다시 서명해 덮어 설치하는 작업을 자동화합니다. 앱 등록과 설정은 유지하며 앱을 삭제하지 않습니다.

## 2026-11-13: 일주일마다 macOS 기본 예약으로 갱신

후속 [Windows·프로파일 전용 갱신 심층 조사](SIGNING_WINDOWS_RESEARCH_KO.md)에서 무료 Windows Watch 설치 코드를 확인했습니다. 해당 도구의 자동 갱신은 Watch를 제외하며, 아이폰 없는 직접 적용 경로는 미해결입니다. SideStore의 iOS 갱신은 전체 재설치 없이 프로파일만 교체하므로, 모든 플랫폼의 갱신에 전체 재설치가 필수라고 일반화하지 않습니다. 아래 설명은 이 저장소의 Mac/Xcode 도구에 해당합니다.

최신 요청에 따라 **Mac 기본 예약 기능으로 7일마다 한 번** 갱신하는 구성을 사용합니다. 기본 시간은 **매주 금요일 16:00, Mac의 현지 시간**입니다. 2026-11-13 설정 시 첫 실행은 **11월 20일 16:00 KST**이며, 기록된 현재 만료일보다 앞섭니다. 이전 Codex 예약은 재개하지 않으며 Codex 앱이 켜져 있을 필요도 없습니다. 기존에 요청했던 워치 인터넷만의 방식과 달리, 이번에 선택한 방식은 갱신 시 Mac과의 개발용 무선 연결을 사용합니다.

현재 설치한 Watch **0.5.15 / 빌드 41**의 앱 프로파일은 **2026-11-20 17:10:56 KST**, 차량 위젯은 **17:10:54 KST**에 만료됩니다. 과거 0.5.2 설치본에 머물러 있던 로컬 갱신 기록은 백업 후 최신 설치본의 만료일로 맞췄습니다. 이 기록 갱신은 실제 재서명이나 예약 실행을 의미하지 않습니다.

인터넷만으로 워치의 무료 서명을 자동 갱신하고 설치하는 사용 가능한 경로는 현재 조사에서 확인하지 못했습니다. [SideStore](https://github.com/SideStore/SideStore)는 iOS 앱과 로컬 VPN을 사용합니다. [Sideloadly 변경 기록](https://sideloadly.io/changelog)의 v0.71.0은 유료 계정의 Watch 처리를 지원하며 무료 지원은 후속 버전 예정이라고 설명합니다. [Windows 기반 Watch 설치 실험](https://github.com/pookjw/HermesEnabler/issues/54)도 PC와 USB로 연결한 iPhone을 요구합니다. 이 자료들은 워치 단독 자동 갱신의 근거가 아닙니다.

[한국 Apple Developer 앱](https://apps.apple.com/kr/app/apple-developer/id640199958)의 멤버십 가격은 **129,000원**, [공식 등록 안내](https://developer.apple.com/kr/programs/enroll/)의 갱신 주기는 연간입니다. 결제 시 표시되는 최종 금액이 기준입니다. 가입만으로 기존 개발용 설치본이 자동 갱신되거나 App Store 설치본으로 바뀌지는 않습니다.

워치가 Mac에 연결하지 않고 인터넷으로 설치·업데이트하는 공식 경로는 [독립형 watchOS 앱의 App Store 배포](https://developer.apple.com/documentation/watchos-apps/creating-independent-watchos-apps)입니다. 멤버십·배포 준비·Apple 심사가 필요하며 이 프로젝트의 승인이 확보된 상태는 아닙니다. [TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)도 빌드당 최대 90일로, 만료 없는 정식 배포와 다릅니다. 이번 설정은 계정 결제나 심사 제출을 하지 않습니다.

## Mac 연결을 허용할 때의 도구 구성

- 실행 도구: [`tools/watch-auto-renew.py`](../tools/watch-auto-renew.py), Python 표준 라이브러리와 Xcode만 사용합니다.
- 예약 설치 도구: [`tools/install-watch-weekly-renew.py`](../tools/install-watch-weekly-renew.py). macOS `launchd`의 사용자 LaunchAgent를 등록합니다. 기본 예약은 **매주 금요일 16:00**이며 6시간 주기의 확인·재시도 작업은 만들지 않습니다.
- 예약 설치 시 갱신 판단 범위를 168시간으로 설정합니다. 이는 실행 간격이 아니라, 주 1회 실행이 갱신을 건너뛰지 않게 하는 조건입니다. 정기 실행에 `--force`는 사용하지 않습니다.
- Mac에 로그인한 상태로 Mac이 깨어 있고 Xcode가 로그인되어 있어야 합니다. 갱신할 때 워치가 같은 Wi-Fi에서 Mac과 개발용 무선 연결이 가능하고 잠금 해제 상태여야 합니다. 케이블과 Codex는 필요 없습니다.
- 워치가 없거나 잠겼으면 기존 앱을 유지하고 상태를 기록합니다. 짧은 주기의 별도 재시도 예약은 없습니다. 7일 간격은 사용자가 명시적으로 선택한 주기이며, 예정된 갱신에 실패하면 만료 전에 추가 실행이 보장되지 않습니다.
- 실행 중에만 `caffeinate -i`로 Mac의 유휴 잠자기를 막습니다. 상시 실행하거나 전원·잠자기 설정을 변경하지 않습니다.

## 실제 갱신 처리

1. 현재 설치된 앱의 빌드 번호와 저장소에 커밋된 빌드 번호가 같은지 확인합니다. 다른 버전을 자동으로 설치하지 않습니다.
2. 저장소의 커밋된 `watch/`만 별도 작업 폴더에 추출합니다. 작성 중인 로컬 변경은 빌드하지 않습니다.
3. 지정한 Team의 FoldBridge 앱·위젯에 해당하는 프로파일만 백업하고 Xcode 캐시에서 옮깁니다. 다른 앱의 프로파일은 변경하지 않습니다.
4. `xcodebuild -allowProvisioningUpdates`로 새 프로파일을 요청하고 빌드합니다.
5. 실제 새 만료일이 연장된 경우에만 갱신본으로 취급합니다. 워치가 연결되지 않으면 빌드 결과를 보관하고 다음 실행에서 설치를 재시도합니다.
6. `devicectl`로 같은 앱에 덮어 설치한 뒤 FoldBridge를 실행해 연결 복구를 시작합니다. 차량 명령은 실행하지 않습니다.

[Apple의 프로파일 갱신 절차](https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles)와 [무료 계정 유효기간 안내](https://developer.apple.com/help/account/basics/about-your-developer-account)를 따릅니다.

## 다른 Mac에서 설정하기

자신의 Team으로 빌드해 실제 워치에 설치한 `.app` 경로와 워치 UDID를 사용합니다. Bundle ID와 Team은 해당 서명본에서 읽습니다.

```sh
python3 tools/watch-auto-renew.py \
  --setup-from-app /absolute/path/to/FoldBridge.app \
  --device YOUR_WATCH_UDID
```

기본 설정·상태 경로는 `~/Library/Application Support/FoldBridge/AutoRenew/`입니다. `config.json`에는 저장소·Xcode 경로, Team·기기·Bundle ID, 설치본의 만료일만 기록합니다. 비밀번호나 인증서는 저장하지 않습니다. 프로파일 백업과 빌드 로그도 이 로컬 폴더에 보관하며 공개 저장소에 올리지 않습니다.

주간 예약 등록은 아래 명령을 **한 번** 실행합니다. 등록 즉시 갱신하거나 기기에 연결하지 않습니다.

```sh
python3 tools/install-watch-weekly-renew.py --weekday 5 --hour 16 --minute 0
```

요일은 월요일 1부터 일요일 7까지입니다. 실행 파일과 커밋된 소스의 독립 Git 사본은 로컬 상태 폴더에 배치합니다. 예약 실행은 Documents 작업 폴더를 직접 읽지 않습니다. 같은 Bundle ID·Team·등록 정보와 만료 기록을 유지하며, 개인 설정이나 기기 식별자를 저장소에 추가하지 않습니다. 앱을 새 버전으로 업데이트하면 그 버전의 커밋에서 이 설치 명령을 다시 실행해 소스 사본도 갱신합니다.

LaunchAgent는 `~/Library/LaunchAgents/dev.foldbridge.weekly-renew.plist`입니다. 이 예약만 제거하려면 `python3 tools/install-watch-weekly-renew.py --remove`를 실행합니다. 앱·등록·로컬 설정은 삭제하지 않습니다. [Apple launchd 문서](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

실행 결과는 로컬 `state.json`, `weekly.stdout.log`, `weekly.stderr.log`에 남습니다. 이는 갱신 작업의 출력이며 워치 시스템 로그를 수집하지 않습니다. 이 LaunchAgent는 Codex 알림을 생성하지 않습니다.

`--force`는 최초 적용 등 즉시 새 프로파일을 요청할 때만 사용합니다. 정기 실행에는 붙이지 않습니다.

## 상태와 필요한 조작

| 상태 | 의미 |
| --- | --- |
| `not_due` | 유효기간이 충분해 아무것도 변경하지 않음 |
| `renewed` | 새 서명 발급·설치·앱 실행 완료 |
| `waiting_watch_connection`, `waiting_watch_unlock` | 워치 연결 또는 잠금 해제 대기 |
| `renewed_waiting_watch`, `install_pending` | 새 빌드를 보관하고 설치 재시도 대기 |
| `renewed_waiting_app_launch`, `waiting_app_launch` | 설치 후 앱 실행을 다음 기회에 재시도 |
| `build_failed`, `renewal_not_extended` | 빌드/프로파일 발급 문제. 로컬 `build.log`에 원인 기록 |
| `source_version_differs` | 설치본과 커밋된 소스 버전이 달라 갱신 중지 |

Apple 재로그인·2단계 인증·Mac 키체인 승인이 필요하면 그때는 사용자가 직접 처리해야 합니다. 이를 자동으로 통과시키지 않습니다. 서명 갱신은 watchOS의 백그라운드 실행 조건이나 마이현대 인증 조건을 바꾸지 않습니다.

최초 적용에서는 Watch 0.5.2의 서명을 새로 발급받아 같은 기기에 덮어 설치하고 앱을 실행했습니다. 매 빌드가 자동으로 유효기간을 연장하는 것은 아니므로, 도구는 빌드 결과의 실제 만료일을 사용합니다.
