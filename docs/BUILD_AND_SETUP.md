# 빌드와 설치

현재 배포는 Android `0.5.2-local` / versionCode 13, 워치 `0.4.7` / build 21이다. 처음 사용하는 경우 [빠른 시작](QUICK_START_KO.md)을 먼저 읽는다.

## Android

Android SDK Platform 36, Build Tools 36.0.0과 JDK 17 이상을 사용한다. 저장소의 경량 빌드 스크립트는 Gradle 없이 Java 컴파일·DEX 생성·APK 패키징·정렬·서명을 수행한다.

```sh
python3 android/build_android.py \
  --sdk /absolute/path/to/android-sdk \
  --java-home /absolute/path/to/jdk \
  --keystore /absolute/path/to/foldbridge-local.keystore \
  --output /absolute/path/to/FoldBridge-Local-0.5.2.apk \
  --skip-signature-check
```

`--skip-signature-check`는 이 작업에서 추가 서명 검사 명령을 생략하는 옵션이며 APK 서명 자체는 수행한다. Gradle 구성도 포함하지만 이 배포 APK는 위 스크립트로 빌드했다.

기존 Local 앱 위에 업데이트하려면 동일한 서명 키를 사용해야 한다. 이번 실제 설치에 사용한 키는 저장소 밖에서 보관한다. 다른 키로 기존 앱을 덮어쓸 수는 없다. 처음 빌드할 때 생성한 키는 후속 업데이트를 위해 별도로 보관한다.

APK는 `artifacts/android/`에도 포함한다. 설치 후 다음을 설정한다.

1. 근처 기기와 일반 알림 권한 허용.
2. **알림 접근 허용** 또는 **설정 → 알림 접근 설정**에서 **FoldBridge Local 알림 전달**의 알림 접근 허용.
3. 기존 Android FoldBridge 앱을 실행 중이면 연결 중지.
4. 처음 연결할 때 Local의 **설정 → 새 워치 등록**을 누르고 워치와 코드를 비교해 양쪽 확인.
5. 일반 사용 시 연결 시작. 충전 상태 알림 전달은 기본 꺼짐.

## Apple Watch

Mac에 전체 Xcode를 설치하고 Apple 계정/서명 Team과 개발용 기기 등록을 준비한다. 프로젝트에는 개인 Team을 지정하지 않았다.

```sh
python3 watch/build_watch.py --team YOUR_TEAM_ID
```

또는 `watch/FoldBridge.xcodeproj`를 Xcode에서 열어 Team과 실제 워치를 선택하고 Run으로 설치한다. 기본 bundle ID는 `dev.foldbridge.watch`이며 업데이트할 때 bundle ID와 서명 Team을 유지한다. 워치 개발자 모드와 Mac 개발용 페어링을 먼저 완료한다. 기기 발견 문제가 있으면 워치와 페어링된 아이폰을 USB로 연결하는 초기 개발 설정이 필요할 수 있다. 앱 통신 자체는 Galaxy–Watch BLE를 사용한다.

워치 앱에서 **휴대폰 연결 → 휴대폰 찾기 → Galaxy 선택**으로 등록한다. 이전 프로필을 사용 중이면 **연결할 앱 선택 → FoldBridge Local**로 바꾼다. **알림 표시 허용**을 처리하고, 필요한 경우 **설정 → 연결 유지**를 켜서 위치 권한을 허용한다. 위치 모드는 배터리를 더 사용할 수 있고 상시 수신을 보장하지 않는다. 무료 개발 Team의 설치는 프로비저닝 만료에 따라 재서명이 필요할 수 있다.

## 진단 도구

이번 문제 해결에는 REA 6.8.0 CLI와 Android platform-tools의 ADB를 사용했다. 로컬 도구이며 앱에 포함하거나 런타임 서버로 쓰지 않는다. REA의 설치와 현재 런타임 요구사항은 [공식 저장소](https://github.com/morluto/rea)를 따른다.

예시:

```sh
export REA_ADB_PATH=/absolute/path/to/adb
rea read-adb-setting DEVICE_SERIAL secure enabled_notification_listeners --format json
rea inspect-adb-package DEVICE_SERIAL dev.foldbridge.local --format json
rea read-adb-logcat DEVICE_SERIAL --pid APP_PID --count 200 --format json
```

Android 상태 파일은 `/sdcard/Android/data/dev.foldbridge.local/files/foldbridge-status.json`, 워치 상태 파일은 앱 컨테이너의 `Documents/foldbridge-status.json`이다. 개인 기기의 상태 파일과 로그는 저장소에 넣지 않는다.

## 앱 아이콘 자산

저장소의 FoldBridge 자체 아이콘은 `tools/generate-app-icon.swift`로 만든 기기 연결 모양이다. Mac에서 아래처럼 다시 만들 수 있다.

```sh
xcrun swift tools/generate-app-icon.swift \
  watch/FoldBridge/Assets.xcassets/FoldBridgeIcon.appiconset/FoldBridgeIcon.png \
  android/app/src/main/res/drawable/foldbridge_icon.png
```

다른 앱의 원본 아이콘은 사용자 갤럭시에서 런타임에 읽어 전달한다. 저장소나 APK에 타사 앱 아이콘 모음을 포함하지 않는다.

## 민감한 알림 본문 허용

Android의 민감한 알림 가림은 알림 접근을 허용해도 별도로 적용될 수 있다. 실제 기기에서 Local 앱의 `RECEIVE_SENSITIVE_NOTIFICATIONS`가 `ignore`였으며, 일반 잠금 화면 내용 표시는 이미 허용되어 있었다. 앱별 AppOp를 허용하고 수집 서비스를 다시 연결해 적용한다. 루팅이나 전체 기기의 가림 해제는 필요하지 않다. APK 업데이트와 별도인 기기 설정이며, 앱 삭제/재설치나 OS 정책 변경 후에는 다시 필요할 수 있다.

사용자가 본문 전체 전달을 원하는 경우, USB 디버깅이 허용된 자신의 기기에서 실행한다:

```sh
adb shell cmd appops set --user 0 dev.foldbridge.local RECEIVE_SENSITIVE_NOTIFICATIONS allow
adb shell cmd notification disallow_listener dev.foldbridge.local/dev.foldbridge.NotificationRelay 0
adb shell cmd notification allow_listener dev.foldbridge.local/dev.foldbridge.NotificationRelay 0
```

원래 차단 상태로 되돌리려면 AppOp를 `ignore`로 바꾸고 같은 수집 서비스 재연결을 실행한다. 다른 앱에서 본문을 제공하지 않거나 자체적으로 숨긴 내용은 복원할 수 없다. [Android 구현의 앱별 허용 처리](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/android16-release/services/core/java/com/android/server/notification/NotificationManagerService.java#13603)

워치 자체의 펼치기 전 미리보기 설정은 별도다. 자동으로 자세히 보려면 워치 설정 → 알림 → 전체 알림을 보려면 탭하기를 끈다. 앱은 이 시스템 설정을 직접 바꿀 수 없다. [Apple 알림 설정](https://support.apple.com/108369)

## 재시작 후 사용

한 번 양쪽 코드로 등록하고 Galaxy의 연결 시작을 켜 두면 등록 키와 연결 의도는 계속 저장된다. 재부팅 뒤 양쪽 잠금을 한 번 해제하고 Bluetooth가 켜져 있어야 한다. Galaxy는 연결 서비스를 자동 재개하며, 워치는 OS 실행/복원 기회에 저장된 휴대폰으로 연결한다. 워치가 바로 연결되지 않으면 FoldBridge를 한 번 연다. 새 워치 등록이나 기존 등록 해제는 필요하지 않다. 사용자가 연결 중지/등록 해제를 선택한 상태는 자동 시작으로 덮어쓰지 않는다.

watchOS는 일반 앱에 부팅 즉시 실행을 보장하는 공개 API를 제공하지 않는다. 30분 뒤 백그라운드 갱신 요청과 Core Bluetooth 복원은 실행 기회를 요청하는 수단이며 완전한 무인 재부팅 복구를 보장하지 않는다. [Apple 백그라운드 재연결](https://developer.apple.com/documentation/watchkit/using-background-tasks), [Android 부팅/업데이트 후 서비스 시작](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start)

## 번역 리소스

번역 원본은 `localization/en.json`이다. 한국어 UI 문구를 키로 두고 영어 번역을 관리한다. 변경 후 아래 명령으로 Android 문자열 리소스/I18n 매핑과 watchOS `Localizable.strings`·권한 설명을 생성한다.

```sh
python3 tools/generate-localization.py
python3 watch/generate_project.py
```

생성 파일도 저장소에 포함하므로 처음 받는 사용자가 별도로 생성할 필요는 없다. Android는 `LocaleManager`의 앱별 언어 설정을 사용하며, 워치는 `AppLanguage`에서 선택을 저장하고 선택된 언어 번들을 사용한다. 연결 진단 상태는 원래 식별 문구를 유지하고 화면에 표시할 때 번역하므로 언어 전환을 위해 연결을 다시 맺을 필요가 없다.
