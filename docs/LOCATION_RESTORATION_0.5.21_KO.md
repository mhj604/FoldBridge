# Watch 0.5.21 — 위치 연결 유지 세션의 재실행 복원

[English](LOCATION_RESTORATION_0.5.21_EN.md) · [문서 목록](README.md)

2026-11-15, Watch·차량 위젯 **0.5.21 / 빌드 47**. Android **0.6.15-local / 코드 33**은 유지합니다. 기존 등록·키·차량 설정을 지우지 않습니다. [Android APK](https://github.com/mhj604/FoldBridge/releases/download/connection-v0.5.19/FoldBridge-Local-0.6.15.apk).

## 기존 위치 유지의 누락

0.5.20까지는 사용자가 위치 기반 연결 유지를 켜도 `CLLocationManager` 세션을 앱이 전면에 있을 때만 시작했습니다. 프로세스가 사라진 뒤 재실행되면 저장된 의도를 즉시 복원하지 않았습니다. 앞선 기록의 `continuousRequested=false`는 이 실행 경로와 관련된 누락이며, 기존 등록이 지워졌다는 뜻은 아닙니다.

이번에는 공식 `CLBackgroundActivitySession`과 `CLLocationUpdate.liveUpdates()`를 사용합니다. 최초 세션은 전면에서 준비하고, OS가 프로세스를 다시 실행하면 시작 직후 이전 세션에 다시 참여합니다. 네이티브 세션과 업데이트 Task를 기능이 켜진 동안 보관하고 사용자가 끄면 무효화합니다. [Apple 세션 재참여 설명](https://developer.apple.com/videos/play/wwdc2023/10180/) · [백그라운드 위치 처리](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background).

## 적용 조건

기존 **연결 유지** 설정이 켜져 있고 위치 권한이 이미 허용된 경우에만 복원합니다. 새 기능으로 이전하는 최초 한 번은 워치에서 앱을 열어 준비해야 합니다. 등록 해제나 새 페어링은 필요 없습니다. 이후의 일반 재연결은 앱을 열도록 요구하는 구조가 아니라 네이티브 세션 복원·BLE 연결 요청·위치 실행 기회를 함께 이용합니다.

저장된 준비 표시만으로 시스템 세션이 실제로 활성화됐다고 간주하지 않습니다. 네이티브 세션이 더 이상 없으면 백그라운드에서 새 활성 세션을 강제로 만들지 못합니다. 진단이 `insufficientlyInUse`이면 앱에 최초 준비 안내를 남깁니다. 권한 거부·기기 위치 서비스 꺼짐도 구분합니다. 운동·오디오 세션·서버·아이폰 중계를 추가하지 않습니다.

위치 좌표는 읽거나 저장·전송하지 않습니다. 업데이트 스트림의 콜백 도착 시각/횟수만 연결 복구에 사용합니다. 기본 위치 스트림은 OS가 정지/재개를 관리할 수 있고 배터리 사용이 달라질 수 있습니다. 끊임없는 CPU 실행을 보장하는 장치는 아닙니다.

## 코드 변경

- 앱 시작의 다른 지연 작업보다 먼저 저장된 위치 활동의 재참여를 요청합니다. 권한 미선택 상태에서 백그라운드 권한 창을 띄우지 않습니다.
- 최초 전면 준비 여부와 사용자의 연결 유지 의도를 따로 저장합니다. 정리·권한 해제는 기능 설정만 처리하며 상대 등록을 건드리지 않습니다.
- 전면으로 재진입한 경우 기존 네이티브 세션을 명시적으로 무효화하지 않고 재참여합니다. 이전 Task의 늦은 콜백은 generation으로 제외합니다.
- 일시적인 업데이트 스트림 종료는 저장된 의도를 끄지 않고 재시도합니다. 이 재시도 지연 자체가 watchOS를 깨우는 것은 아닙니다.
- 진단의 `locationActivityState`, `locationActivityCallbacks`, `applicationStateName`을 추가했습니다. `eligible`은 Core Location의 세션 자격 진단이며 무기한 실행이나 장시간 잠금 성공을 뜻하지 않습니다. `inactive`와 `background`는 별도 문자열로 표시합니다.
- 기존 BLE 자동 재연결·빠른 인증·전달 cutoff·차량 버튼·알림 레이아웃은 유지합니다.

## 실제 설치와 준비

빌드와 덮어 설치가 성공했습니다. 최초 앱 기록은 빌드 47, `locationActivityState=needs-foreground-setup`, `applicationStateName=inactive`였습니다. Mac의 최초 준비용 앱 실행 명령이 시간 초과돼 사용자가 워치를 한 번 직접 열었습니다. 이후 사용자는 시계 화면으로 돌아왔습니다. 이번에 앱을 전혀 열지 않았다고 주장하지 않습니다. 이는 설치 후 최초 준비 단계입니다.

최초 준비 뒤 `locationActivityState=eligible`, 위치 콜백 36회, 인증 연결이 읽혔습니다. 사용자가 시계 화면으로 돌아간 뒤에는 `applicationStateName=background` (`applicationState=2`), `connected=true`, `continuousRequested=true`, 콜백 130회가 기록됐습니다. 앱의 연결 취소·오류·조각 폐기는 0이었습니다. 이는 실제 백그라운드에서 실행 기회가 이어진 결과이며 장시간 암호 잠금이나 실제 거리 이탈을 뜻하지 않습니다. 폰의 `watchActive=true`는 위치 실행 요청도 포함하므로 워치 UI가 전면이라는 뜻으로 해석하지 않습니다. 재실행 후 활동 재참여 분기를 강제로 유도하지 않았습니다.

시스템 로그·관리자 암호·실제 차량 명령·별도 장시간 잠금/거리 이동 QA는 사용하지 않았습니다. 이 경로의 설치·초기 연결을 장시간 잠금·실제 거리 복귀의 완전 해결 근거로 확대하지 않습니다. 기존 네이티브 세션의 강제 종료/상실·재부팅·권한·OS 실행 정책의 영향은 남습니다.

## 작업 종료

기존 종료 방침대로 폰 **설정 → 연결 중지**를 선택했습니다. 폰 기록은 `bridgeRunning=false`, `centralPresent=false`, `subscribed=false`, `authenticated=false`, `status=중지됨`입니다. 등록·키·차량 설정은 보존합니다. Mac 무선 디버깅도 종료합니다.

일상 자동 연결을 사용하려면 폰에서 **워치 연결**을 한 번 켜 두어야 합니다. **연결 중지**는 서비스의 자동 연결 시도도 끄는 명시적인 정지이며, 거리 이탈로 발생하는 일시적인 Bluetooth 단절과 다릅니다. 이후 정상 사용에서 매번 워치 앱을 열어야 한다는 뜻은 아닙니다.

기존 주 1회 Mac 서명 갱신 소스를 설치한 빌드 47의 커밋으로 맞춥니다. 갱신은 지금 실행하지 않습니다. 워치 인터넷만의 무료 자동 서명 목표는 별도 미완료입니다.
