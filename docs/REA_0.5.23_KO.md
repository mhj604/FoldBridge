# WatchBridge 0.5.23 — REA 연결 조사와 이름 변경

[English](REA_0.5.23_EN.md) · [문서 목록](README.md)

2026-11-15. Android **0.6.17-local / 코드 39**, Watch·위젯 **0.5.23 / 빌드 55** 수정 후보입니다. **반복 끊김은 미해결이며 안정 버전으로 표시하지 않습니다.**

## 이름과 호환성

표시 이름을 WatchBridge로 바꿨습니다. 앱 목록·워치 탐색 제목·설정·차량 제어 안내·알림 접근 서비스·연결 알림·위젯의 앱 이름·한국어/영어 리소스와 GitHub 저장소·문서에 반영합니다. 저장소는 [mhj604/WatchBridge](https://github.com/mhj604/WatchBridge)입니다.

덮어 설치로 기존 등록을 유지합니다. Android `dev.foldbridge.local`, Watch `dev.foldbridge.watch`, 위젯 식별자, 키체인·설정 키, BLE UUID, 암호화 문맥과 위젯 kind는 그대로입니다. `watch/FoldBridge.xcodeproj` 등 기존 빌드 경로와 과거 배포 파일명도 호환성을 위해 남깁니다. 이 내부 이름이 화면의 앱 이름을 결정하지 않습니다. Git 기록·태그·과거 바이너리는 다시 작성하지 않습니다.

## 안내 문구의 실제 원인과 수정

폰의 이전 `renderState()`는 연결되지 않은 모든 상태의 마지막 분기에서 “워치에서 FoldBridge를 열어 주세요.”를 표시했습니다. 따라서 사용자가 폰 서비스를 중지했거나, 이미 등록돼 자동 재연결 중이거나, 최초 등록 중이어도 같은 안내가 나왔습니다.

이제 서비스 중지, 최초 등록, 저장된 기기 인증, 자동 재연결 대기, 연결 완료, 알림 수집 서비스 대기를 구분합니다. 새로고침은 성공을 단정하지 않고 재연결 요청을 보냈다고 알립니다. 워치도 암호 인증만 끝난 상태와 `ready` 수신·알림 구독까지 완료된 상태를 구분합니다. 재연결 전에 발생한 알림을 나중에 모두 동기화한다는 오해를 주는 문구도 바꿨습니다.

위치 권한·최초 위치 세션 준비 또는 실제 watchOS 수신 예산 소진에 따른 안내는 해당 상태에서만 남깁니다. 사용자가 앱을 한 번 열어야 하는 실제 조건까지 숨기지는 않습니다.

## REA 사용 범위

[REA](https://github.com/morluto/rea)의 설치된 CLI를 사용했습니다. MCP는 이 세션에 노출되지 않았습니다. Android 기기 조회·설치 패키지 정보·앱 상태 파일 확보·덮어 설치는 REA ADB 기능을 사용합니다. watchOS 직접 기기 런타임 제공자는 없으므로 REA `capture-process`로 Apple `devicectl`의 앱 파일 복사와 설치 결과를 기록했습니다. 이것을 REA의 watchOS 화면 조작 기능이라고 표현하지 않습니다.

앱 자체 `foldbridge-status.json`, `foldbridge-events.json`의 메타데이터만 사용합니다. 시스템 로그·관리자 암호·메시지 본문·실제 차량 명령은 수집하거나 사용하지 않습니다. 원본 Evidence는 소유자 Mac에만 보관하며 공개 저장소에는 기기 식별자·네트워크 주소가 담긴 원본을 올리지 않습니다.

대표 Evidence:

| 관측 | REA Evidence ID |
| --- | --- |
| 설치된 Android 코드 38 패키지 조회 | `ev_2510a6b97801ac192b316f3f77338c92594a14c46f2f757ed1ed900de25d5403` |
| Watch 빌드 53 상태 파일 확보 | `ev_7af78c926d85bcfab815058d938bea537d9577730c0a7fa24b6f7504f8753273` |
| 빌드 53 반복 종료 이벤트 확보 | `ev_de7120946e11e2827542c289f18a5d5e5e38e8dca30dd081a90a9d8dd94a24f2` |
| Watch 빌드 54 설치 | `ev_fa171678d5574713163b4a761bd1ee57e3f49ca224041b2f85b61cacdedf9cf1` |
| 빌드 54 암호 잠금 상태 | `ev_ea6cac200cafd0f825e80e39e8027cf662c23e9058da30f0633e0831ea822e9f` |
| 최초 준비 후 빌드 54 앱 상태 | `ev_e8e9f9f63c00e768def8d2f7731c0dbfc636688c252cc8a1690a55aca0ee6b0f` |

## 관측 사실과 수정 범위

빌드 53의 백그라운드 기록은 인증·구독 완료 뒤 약 4초 후 오류 없는 네이티브 종료, 즉시 재연결, 일부 인증 도중 종료를 반복했습니다. 앱 자체 취소는 0회였고 위치 활동은 `eligible`이었습니다. 따라서 잠금 인증 성공을 지속 연결 성공으로 볼 수 없습니다.

저장된 기기의 네이티브 연결 요청이 이미 대기 중이어도 매번 백그라운드 검색을 새로 시작하는 코드가 있었습니다. 빌드 54부터 알려진 기기의 연결 대기는 Core Bluetooth에 남기고 이 중복 검색을 억제합니다. Apple은 백그라운드 검색과 Bluetooth 알림 실행 기회가 제한된 예산을 공유한다고 설명합니다. [Apple 문서](https://developer.apple.com/documentation/watchkit/using-background-tasks).

이 수정 후 빌드 54는 백그라운드 검색 0회, 중복 검색 억제 48회를 기록했지만 재인증 43회 중 완료 22회로 반복이 남았습니다. 최초 준비 후 실제 `background`, 위치 `eligible` 상태에서도 종료가 있었고, 한 기록은 `CBErrorDomain:6` 시간 초과였습니다. 해당 종료 당시 연결 후 약 18.5초, 구독 후 약 7.2초, 대기 쓰기 2개, 앱 백그라운드 작업 0개, 앱 취소 0개였습니다. 작업 완료·만료 카운터도 0이었습니다. 이는 **중복 검색만이 원인이 아니며 앱이 작업을 먼저 완료한 사례로도 설명되지 않는다**는 범위의 증거입니다. OS 예산 소진이나 특정 시스템 버그를 확정하는 증거는 아닙니다.

빌드 55는 연결 완료 공개를 실제 구독 완료 뒤로 옮기고, 잠금 중 유휴 재연결에서 차량 목록·상태·동기화 요청을 자동으로 연달아 보내지 않도록 줄였습니다. 차량 화면·위젯이 요청할 때는 새 목록을 가져옵니다. 알림 수신·전달 확인, 기존 암호 인증과 등록은 유지합니다. 이 변경을 네이티브 종료 원인의 확정 해결이라고 표시하지 않습니다.

## 남은 항목

- 인증·구독 뒤 네이티브 종료와 재인증 반복의 조건을 더 좁혀야 합니다.
- 장시간 암호 잠금 상태의 지속 연결·알림 전달을 완료로 표시하지 않습니다.
- 실제 거리 이탈과 복귀 후 앱·새로고침 없는 복구는 별도 현장 조건이며, 근거리 인증 기록으로 대신하지 않습니다.
- Mac 개발용 네트워크 터널의 시간 초과는 별개입니다. 파일 복사 명령이 실행됐다는 Evidence와 명령 내부의 실제 성공/실패를 구분합니다.

일반 사용에서는 폰의 연결 기능을 켜 두어야 합니다. 소유자 기기 작업을 마칠 때는 기존 방침대로 **설정 → 연결 중지**만 사용하고 등록은 삭제하지 않습니다. 이후 자동 재연결을 다시 사용하려면 **워치 연결**을 켭니다.

## 다음 조사에서 재사용할 명령

REA CLI와 Android Platform-Tools를 준비한 환경에서 아래 명령을 사용합니다. 경로·기기 ID는 본인의 값으로 지정합니다.

```sh
rea list-adb-devices --format json
rea inspect-adb-package DEVICE dev.foldbridge.local --format json
rea pull-adb-file DEVICE /sdcard/Android/data/dev.foldbridge.local/files/foldbridge-status.json --output-directory ./private-evidence --format json
```

워치는 REA `capture-process` 시나리오에서 `xcrun devicectl device copy from --device DEVICE --domain-type appDataContainer --domain-identifier dev.foldbridge.watch --source Documents/foldbridge-status.json --destination OUTPUT --timeout 25`를 실행합니다. Evidence 원본, 파일 해시, 실제 명령 종료 코드와 파일 안의 시각을 함께 보관합니다. 원본을 공개 Git에 추가하지 않습니다.
