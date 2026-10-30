# FoldBridge Local

갤럭시 알림을 Apple Watch로 직접 전달하는 개인용 Android·watchOS 앱입니다. 전송은 두 기기 사이의 BLE로 처리합니다. Android Local 앱에는 인터넷 권한이 없으며 APNs·중계 서버를 사용하지 않습니다. 운동·오디오 세션과 루팅은 사용하지 않습니다.

## 이번 배포

- Android: `FoldBridge-Local-0.2.2.apk`, 앱 ID `dev.foldbridge.local`, 버전 코드 5.
- watchOS: `dev.foldbridge.watch`, 버전 0.1.0, 빌드 4.
- 기존 갤럭시 FoldBridge와 별도로 설치합니다. 기존 앱의 데이터와 서명은 건드리지 않습니다.
- 워치는 기존 앱과 Local 앱의 휴대폰 ID·페어링 키를 별도로 보관합니다. 앱 전환으로 기존 수신 목록이나 페어링을 삭제하지 않습니다.

## 바뀐 전달 방식

- Samsung System UI의 `charging_state` / `CHR` 충전 상태 알림은 기본으로 전달하지 않습니다. 충전율이 변하며 반복 갱신되는 시스템 알림이 워치에서 계속 울리는 문제를 해결합니다. `충전 상태 알림 전달`을 켜면 다시 포함합니다. 다른 앱과 중요 시스템 알림을 일괄 제외하지 않습니다.
- Bluetooth 연결과 다른 앱의 알림을 읽는 **알림 접근**은 별개입니다. 일반 알림 권한만 허용하면 전달할 알림을 수집하지 못합니다. 이번 실기기 문제에서는 Local 알림 접근이 꺼져 있었고 수집 서비스도 연결되지 않았습니다. 권한 활성화 후 시스템의 수집 서비스 연결을 확인했습니다.
- 앱 상단에서 알림 접근 허용 여부·수집 서비스 연결·수집/전달 요청/워치 수신 확인 수를 따로 표시합니다. 알림 접근이 꺼져 있으면 연결 상태보다 권한 누락을 먼저 표시하고 해당 설정으로 안내합니다. 허용됐으나 서비스가 연결되지 않은 경우 재바인딩을 요청합니다.
- 워치 알림 표시 권한을 확인한 뒤 알림을 등록하고 수신 확인을 보냅니다. 권한이 꺼져 있을 때는 미확인 알림을 휴대폰에 남깁니다. 앱 전면에서도 배너·알림 목록·소리 표시를 요청합니다.
- 워치 백그라운드 작업의 임의 4초 종료를 제거했습니다. 수신 처리 완료 또는 watchOS 만료 통지에 맞춰 작업을 끝냅니다. 이는 OS 실행 예산을 늘리거나 제한을 우회하는 기능이 아닙니다.
- 진단 상태 파일에는 연결·권한·단계별 개수와 오류 상태만 기록하며 알림 제목·본문·보안 키·위치 좌표는 넣지 않습니다. Android는 앱의 외부 파일 폴더, 워치는 `Documents/foldbridge-status.json`에 저장합니다.
- `모든 앱 알림 전달`이 기본으로 켜집니다. 선택한 앱만 전달하는 설정도 있습니다. 충전 상태 알림은 위의 별도 설정을 따릅니다.
- 앱 코드에서 진행 중 알림·로컬 전용 알림·그룹 요약·비밀 표시 알림을 일괄 제외하던 필터를 제거했습니다. Android가 알림 접근 서비스에 실제 제공하는 제목·본문만 전달합니다. OS가 숨긴 내용은 복원하지 않습니다. 자체 연결 상태 알림은 반복 전달을 막기 위해 제외합니다.
- GATT indication으로 패킷 전송 확인을 받고, 워치의 메시지 수신 확인 후 다음 알림을 보냅니다. 미확인 메시지를 조용히 버리지 않고 재시도·재연결 대상으로 남깁니다.
- 미전달 알림은 암호화해 최대 24시간·1024개 보관합니다. 같은 알림 ID의 갱신은 최신 내용으로 대체합니다. 한도 초과 시 가장 오래된 항목부터 비웁니다.
- 서비스·알림 접근 재연결 때 현재 남아 있는 알림을 다시 가져옵니다. 워치가 기억하는 수신 기록으로 중복을 줄입니다.
- 사용자가 연결을 시작해 둔 경우 휴대폰 재부팅·Bluetooth 복구 시 자동 시작을 요청합니다. Android의 강제 종료·백그라운드 제한까지 무시하는 기능은 아닙니다.

## 갤럭시에서 설정

1. `FoldBridge-Local-0.2.2.apk`를 설치하고 **FoldBridge Local**을 엽니다. 기존 FoldBridge는 삭제할 필요가 없습니다. Local 이전 버전에서 업데이트할 때는 동일 서명 키를 사용합니다. 연결 시작 설정을 켜 둔 경우 업데이트 뒤 앱을 열면 서비스를 재개합니다.
2. 근처 기기와 알림 권한을 허용합니다.
3. `1. 다른 앱 알림 읽기 허용`에서 **FoldBridge Local 알림 전달**을 허용합니다. APK 설치 정책에 따라 앱 정보에서 제한된 설정 허용이 먼저 필요할 수 있습니다.
4. 기존 FoldBridge에서 `연결 중지`를 누릅니다. 두 BLE 서비스를 함께 켜면 간섭할 수 있으므로 기존 앱은 보관하되 연결은 중지합니다. Local 앱의 `모든 앱 알림 전달`을 켜 두고 `새 워치 등록 (2분)`을 누릅니다.
5. 워치에 표시되는 코드와 같을 때 양쪽에서 확인합니다. 평소에는 `연결 시작`으로 서비스를 유지합니다.

## 워치에서 설정

1. FoldBridge의 `새 Local 앱 연결`을 누릅니다. 화면에 **FoldBridge Local**이 표시됩니다.
2. `휴대폰 찾기`에서 갤럭시를 선택합니다. 양쪽 보안 코드를 비교하고 확인합니다.
3. 워치 알림 권한을 허용합니다.
4. `위치 연결 유지 시작`을 선택하고 위치 권한을 허용합니다. 이 모드는 워치 위치 세션으로 실행 시간을 확보하는 실험입니다. 좌표는 읽어 저장하거나 전송하지 않고, 위치 콜백을 받은 시각만 표시합니다.
5. 이 빌드부터 연결 유지 설정을 저장합니다. 앱을 다시 전면에서 열면 사용자가 켜 둔 설정을 재개합니다. `위치 연결 유지 중지`를 누르면 설정과 세션을 끕니다.
6. 위치 세션을 요청한 동안 30초 간격과 위치 콜백에서 연결·미전달 동기화를 시도합니다. 타이머 자체가 중단된 앱을 깨우는 기능은 아닙니다.

기존 앱으로 돌아가려면 `기존 앱으로 전환`을 누릅니다. 전환 과정에서 Local 앱의 페어링도 남겨 둡니다.

## 남는 한계

위치 세션을 이용하는 백그라운드 수신은 실험 기능이며, 모든 알림의 무제한·즉시 수신은 보장하지 않습니다. watchOS는 앱을 중단하거나 종료할 수 있고, 위치 수신·권한·시스템 상태에 따라 실행 시간이 달라집니다. 워치에서는 위치 자동 일시중지를 끄는 iOS 속성을 사용할 수 없습니다. 일반 Bluetooth 백그라운드 검색·알림 실행에는 24시간당 5회의 합산 예산이 적용됩니다. 위치 모드가 이 제한을 언제나 우회한다고 주장하지 않습니다.

Android의 알림 접근 제한, 사용자가 선택한 필터, 보관 한도, Bluetooth 통신 범위 및 두 기기의 알림·집중 모드 설정도 영향을 줍니다. 읽음·삭제의 양방향 동기화는 포함하지 않습니다. 워치의 `워치에서 삭제`는 워치 목록과 로컬 알림만 삭제합니다.

실제 설치 및 수신 문제의 원인과 적용 이력은 [구축 이력](docs/DEVELOPMENT_HISTORY.md)에 기록했습니다. 별도의 테스트 스위트나 자동 CI는 실행하지 않았습니다.

## 소스와 빌드

- `android/`: Local 앱 Java 소스와 빌드 도구. Java 패키지는 `dev.foldbridge`, 설치 앱 ID는 `dev.foldbridge.local`입니다.
- `watch/FoldBridge.xcodeproj`: 현재 워치 앱 Xcode 프로젝트.
- `relay/`, `windows/`, `legacy/`: 과거 배포 구성입니다. 이번 Local APK의 동작에는 사용하지 않습니다. 과거 검사 결과는 이번 변경의 결과를 뜻하지 않습니다.

Android SDK Platform 36, Build Tools 36.0.0, JDK 17 이상으로 빌드합니다. 예:

```sh
python3 android/build_android.py --sdk /path/to/sdk --java-home /path/to/jdk --keystore /path/to/debug.keystore --output FoldBridge-Local.apk --skip-signature-check
```

향후 Android 업데이트에는 이번에 생성한 동일한 서명 키를 사용해야 합니다. 서명 키는 저장소에 포함하지 않습니다. 로컬의 `FoldBridge-Local-signing-backup.zip`에 이번 키를 별도로 보관했습니다. 이 개발용 키의 alias는 `androiddebugkey`, store/key password는 `android`입니다.

워치는 무료 Personal Team으로 서명합니다. 앱 ID·Team을 유지하면 기존 저장 데이터를 사용하는 업데이트가 가능합니다. 개발용 서명의 만료 조건은 Apple의 프로비저닝 정책을 따릅니다.

## 근거

- [Apple 백그라운드 위치 업데이트](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background)
- [Apple Bluetooth 백그라운드 작업](https://developer.apple.com/documentation/watchkit/using-background-tasks)
- [Android foreground service 시작 제한](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start)

## 문서와 배포 파일

- [구조](docs/ARCHITECTURE.md)
- [현재 BLE 프로토콜](docs/PROTOCOL.md)
- [빌드와 설치](docs/BUILD_AND_SETUP.md)
- [구축 이력과 문제 해결](docs/DEVELOPMENT_HISTORY.md)
- [Android APK](artifacts/android/FoldBridge-Local-0.2.2.apk)

`relay/`, `windows/`, `legacy/`는 초기 구성의 소스와 문서를 보존한 것입니다. 현재 Local 앱은 이 구성에 의존하지 않습니다. 원본 ZIP이나 기기 로그, 페어링 키, Android 서명 키, Apple 프로비저닝 프로파일은 포함하지 않습니다. Xcode Team은 각자 선택합니다.
