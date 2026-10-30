# 빌드와 설치

현재 배포는 Android `0.2.2-local` / versionCode 5, 워치 `0.1.0` / build 4다.

## Android

Android SDK Platform 36, Build Tools 36.0.0과 JDK 17 이상을 사용한다. 저장소의 경량 빌드 스크립트는 Gradle 없이 Java 컴파일·DEX 생성·APK 패키징·정렬·서명을 수행한다.

```sh
python3 android/build_android.py \
  --sdk /absolute/path/to/android-sdk \
  --java-home /absolute/path/to/jdk \
  --keystore /absolute/path/to/foldbridge-local.keystore \
  --output /absolute/path/to/FoldBridge-Local-0.2.2.apk \
  --skip-signature-check
```

`--skip-signature-check`는 이 작업에서 추가 서명 검사 명령을 생략하는 옵션이며 APK 서명 자체는 수행한다. Gradle 구성도 포함하지만 이 배포 APK는 위 스크립트로 빌드했다.

기존 Local 앱 위에 업데이트하려면 동일한 서명 키를 사용해야 한다. 이번 실제 설치에 사용한 키는 저장소 밖에서 보관한다. 다른 키로 기존 앱을 덮어쓸 수는 없다. 처음 빌드할 때 생성한 키는 후속 업데이트를 위해 별도로 보관한다.

APK는 `artifacts/android/`에도 포함한다. 설치 후 다음을 설정한다.

1. 근처 기기와 일반 알림 권한 허용.
2. **다른 앱 알림 읽기 허용**에서 **FoldBridge Local 알림 전달**의 알림 접근 허용.
3. 기존 Android FoldBridge 앱을 실행 중이면 연결 중지.
4. 처음 연결할 때 Local의 **새 워치 등록 (2분)**을 누르고 워치와 코드를 비교해 양쪽 확인.
5. 일반 사용 시 연결 시작. 충전 상태 알림 전달은 기본 꺼짐.

## Apple Watch

Mac에 전체 Xcode를 설치하고 Apple 계정/서명 Team과 개발용 기기 등록을 준비한다. 프로젝트에는 개인 Team을 지정하지 않았다.

```sh
python3 watch/build_watch.py --team YOUR_TEAM_ID
```

또는 `watch/FoldBridge.xcodeproj`를 Xcode에서 열어 Team과 실제 워치를 선택하고 Run으로 설치한다. 기본 bundle ID는 `dev.foldbridge.watch`이며 업데이트할 때 bundle ID와 서명 Team을 유지한다. 워치 개발자 모드와 Mac 개발용 페어링을 먼저 완료한다. 기기 발견 문제가 있으면 워치와 페어링된 아이폰을 USB로 연결하는 초기 개발 설정이 필요할 수 있다. 앱 통신 자체는 Galaxy–Watch BLE를 사용한다.

워치 앱에서 **새 Local 앱 연결 → 휴대폰 찾기 → Galaxy 선택**으로 등록한다. **알림 표시 허용**을 처리하고, 필요한 경우 **위치 연결 유지 시작**을 선택해 위치 권한을 허용한다. 위치 모드는 배터리를 더 사용할 수 있고 상시 수신을 보장하지 않는다. 무료 개발 Team의 설치는 프로비저닝 만료에 따라 재서명이 필요할 수 있다.

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
