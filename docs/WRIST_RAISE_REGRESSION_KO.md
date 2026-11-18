# 손목 들기 화면 복귀 — 변경 이력 조사

> 버전별 조사·변경 기록입니다. 여기의 “현재/완료/미해결”은 해당 시점 기준이며 최신 설치 안내가 아닙니다. [현재 버전과 작업 상태](CURRENT_STATUS_KO.md).

> 후속 정정: 거리 복귀 시 앱 표시 없는 자동 연결과 새 REA 기록이 확보됐습니다. 위치 복원을 확정 원인으로 보거나 롤백을 우선 적용하지 않습니다. [현재 조사와 기록 보완](DISPLAY_INVESTIGATION_0.5.26_KO.md).


[English](WRIST_RAISE_REGRESSION_EN.md)

2026-11-18 KST. 설치본은 Android 0.6.19 / 코드 41, Watch·위젯 0.5.25 / 빌드 59입니다. 이번 작업은 저장된 소스·앱 자체 기록·공식 문서 조사이며 앱 코드 변경이나 기기 재연결은 하지 않았습니다. 사용자가 중지한 연결과 기존 등록을 유지했습니다.

## 결론과 확실성

유력한 변경점은 **0.5.21 / 빌드 47의 위치 활동 복원 변경**입니다. 앱이 새로 실행되는 문제와 기존 앱이 손목 들기에 다시 표시되는 문제를 구분해야 합니다. 기존 설정 안내만으로 해결된다고 한 설명은 충분하지 않았습니다.

현재 사용 중인 프로세스는 11월 17일 실제 `background`였다가 18일 `inactive` 상태로 기록됐고 프로세스 식별자는 같았습니다. 따라서 수집된 두 기록 사이의 증상은 새 프로세스 생성 없이도 설명됩니다. 이 사실만으로 모든 표시 전환의 원인이나 전환을 일으킨 특정 watchOS 이벤트를 확정하지 않습니다.

## 어떤 변경이 있었나

| 변경 | 이전과 이후 | 의미 |
| --- | --- | --- |
| 11월 8일 `a3f245d` | `CLBackgroundActivitySession`과 위치 활동 복원 추가 | 위치 활동을 명시적으로 보관하는 경로가 처음 이력에 나타남 |
| 같은 날 `bb7751b` | 위 변경을 되돌림 | 이후 한동안 기존 `CLLocationManager` 방식 사용 |
| 11월 15일 `1087ab9`, Watch 0.5.21 | 기존 전면 시작 `CLLocationManager.startUpdatingLocation()`에서 보관된 `CLBackgroundActivitySession` + `CLLocationUpdate.liveUpdates()`로 변경; 앱 시작 직후 세션 재참여 추가 | 앱을 다시 열지 않아도 기존 위치 활동이 이어지도록 실행 수명 변경 |
| 0.5.24의 읽기 수신 | 현재 읽기 모드에서 2초 간격으로 알림 조각을 가져옴 | 실행 시간을 제공하는 위치 세션을 단순 제거하면 수신 방식에도 영향 |
| 11월 17일 `0a29976` | Mac 설치·갱신 실행 명령에 `--no-activate` 추가 | 유지보수 명령의 전면 활성화 경로는 이미 제거; 오늘은 실행하지 않음 |

원본 비교: `1087ab9^..1087ab9`, `watch/FoldBridge/FoldBridgeApp.swift`. 해당 변경의 `Info.plist`는 버전 번호만 바뀌었습니다. `UIBackgroundModes`의 `location`은 그전부터 있었습니다. 차량 위젯의 `openAppWhenRun=true`는 이 기간 새로 추가된 동작이 아니며 사용자가 위젯을 눌렀을 때의 전면 실행과 구분합니다.

## 보관 기록과의 대조

- 이전에 보관한 앱 자체 상태 파일의 실제 빌드 44·46은 `continuousRequested=false`였습니다. 빌드 44는 연결됐고 46은 연결되지 않은 표본입니다. 이 파일들은 과거 수집 기록이며 이번에 새 REA 수집을 수행한 것이 아닙니다. 전체 이전 버전의 모든 시점에서 위치 기능이 꺼져 있었다는 뜻도 아닙니다.
- 0.5.21 최초 준비 전에는 `needs-foreground-setup`, `continuousRequested=false`였습니다. 최초 준비 후에는 `eligible` 위치 활동이 유지되는 것으로 바뀌었습니다.
- REA로 수집한 현재 빌드 59는 `continuousRequested=true`, 위치 `eligible`이며 위치 콜백이 계속 누적됐습니다. 즉, 앞선 표본과 현재의 위치 활동 상태는 실제로 다릅니다.

현재 Evidence: 11월 17일 `ev_2e83e5295639bd8aa1fecf4779a413a8dd0c4643cab7aeb307ed3070d6e5858b`, 18일 `ev_c54d763f7ce352d8e58987d6ea6f1d5f6baf1ae5386b632ac5b1a4d1280a166f`, 이벤트 `ev_56bf488a356909c1275e41abb99bcdfa635f3e5c54aaf9f1d5946918fe72b676`. REA는 Apple devicectl을 감싼 수집이며 watchOS 시스템 내부 호출을 추적한 자료는 아닙니다.

## 해결 후보와 한계

1. **위치 처리만 0.5.20 방식으로 되돌리는 수정 후보.** 현재의 인증·읽기 수신·거리 복구·알림 필터·등록 형식은 보존하고 `LocationKeepAlive` 변경만 분리합니다. 새 활동 객체의 지속 복원이 원인인지 좁힐 수 있는 최소 범위지만, 기존 방식도 연속 백그라운드 위치를 사용합니다. 따라서 이전 방식을 복원하면 화면 문제가 반드시 사라진다고 단정할 수 없으며 프로세스 재실행 후 위치 복원은 약해질 수 있습니다. 전체 앱 버전 롤백은 불필요합니다.
2. **위치 없이 Core Bluetooth 배경 이벤트를 사용하는 구조.** 화면을 앞에 유지하는 위치 세션에 의존하지 않는 방향입니다. 다만 현재 읽기 폴링은 앱 정지 중 작동하지 않으므로 구독 기반 수신과 재연결을 함께 설계해야 합니다. Apple은 배경 검색과 timely alert의 공동 기회를 이동 24시간 동안 5회로 제한하므로 모든 알림의 무제한 즉시 수신을 대체한다고 주장할 수 없습니다.
3. **기존 실행 시간은 보존하고 표시만 숨기는 설정/API.** 실제 기기의 사용자화→항상은 이미 적용됐고 Return to App 토글은 없었습니다. 현재 SDK에서 `showsBackgroundLocationIndicator`는 watchOS 사용 불가입니다. Always On만 끄는 변경, 폐기된 `isFrontmostTimeoutExtended` 변경은 손목 들기 복귀의 해결로 취급하지 않습니다. 위치 활동을 종료하거나 프로세스를 종료해서 감추는 방식은 연결 목표와 충돌합니다.

우선순위는 전체 롤백보다 **위치 수명 변경만 분리한 후보**입니다. 다만 이번 요청은 원인 조사와 해결 방법 모색이므로 후보를 설치하거나 기본 동작을 변경하지 않았습니다. 별도 QA·강제 연결 단절·거리 실험·시스템 로그·관리자 인증·차량 제어는 진행하지 않았습니다. 자동 표시와 연결 안정성의 동시 해결은 아직 완료되지 않았습니다.

## 공식 근거

- [백그라운드 세션과 손목 들기 표시](https://developer.apple.com/documentation/watchkit/enabling-background-sessions)
- [위치 활동 객체와 가시성](https://developer.apple.com/documentation/corelocation/clbackgroundactivitysession-3mzv3)
- [위치 서비스 재실행 시 복원](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background)
- [watchOS Bluetooth 배경 작업과 예산](https://developer.apple.com/documentation/watchkit/using-background-tasks)
