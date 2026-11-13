# 매주 갱신하지 않는 구조: 배포 변경과 Watch 앱 대체

**한국어** · [English](NO_WEEKLY_SIGNING_ARCHITECTURE_EN.md) · 조사일 **2026-11-13**

추가 조사: [현재 watchOS 버전의 서명 우회 연구와 구현 가능성](WATCHOS_27_SIGNING_BYPASS_RESEARCH_KO.md). 과거 영구 서명 시연, Calif 원문, Brotli PoC, 가상 Watch 코드의 적용 범위와 누락된 구현을 정리했습니다.

## 후속 결정: 상시 USB 어댑터 제외

사용자는 시스템 프로토콜 방향을 선택했지만, 외장 어댑터가 최초 작업 때만 필요한 것이 아니라 **평소 통신 중에도 계속 연결돼 있어야 한다는 설명을 들은 뒤 상시 어댑터 방식을 제외**했습니다. 따라서 아래의 미루팅 USB PR은 채택된 구현 계획이 아닌 조사 이력입니다.

공개 소스를 로컬에 내려받고 PR #8·#12를 가져와 구조를 읽었습니다. 메인 소스 고정점은 `3af14e0226113d465d3ab84a9d30a16f84c968c0`입니다. [`RootBluetoothHalHost`](https://github.com/LordixDemon/apple_watch_connector/blob/3af14e0226113d465d3ab84a9d30a16f84c968c0/apple-watch-bridge/hal/src/main/java/dev/applewatchandroid/bridge/RootBluetoothHalHost.java)는 UID 0과 OnePlus CPH2653을 요구하고, [`AndroidBluetoothController`](https://github.com/LordixDemon/apple_watch_connector/blob/3af14e0226113d465d3ab84a9d30a16f84c968c0/apple-watch-bridge/hal/src/main/java/dev/applewatchandroid/bridge/AndroidBluetoothController.java)는 `IBluetoothHci`로 HCI 명령·ACL 패킷을 직접 주고받습니다. 모델명 제한만 제거해도 일반 앱의 접근 권한이 생기지는 않습니다. 루팅된 Fold7 지원도 이 소스의 지원 결과가 아닙니다.

Android의 일반 Bluetooth 연결 API나 CompanionDeviceManager를 이 전송부의 직접 대체로 삼을 구현 근거는 확보하지 못했습니다. 특히 CompanionDeviceManager의 기기 연결 등록은 통신 자체를 만들어 주는 기능이 아닙니다. [Android 공식 설명](https://developer.android.com/develop/connectivity/bluetooth/companion-device-pairing)

**현재 선택 조건인 미루팅 Fold7 내장 Bluetooth + 자체 Watch 앱 없음 + 상시 외장 장치 없음에 적용할 수 있는 네이티브 전송부는 미확보입니다.** APK 빌드·설치·프로토콜 결합은 진행하지 않았으며 기존 앱과 등록 정보를 유지했습니다. 이 방향을 구현 가능 상태로 만들려면 먼저 해당 조건에서 HCI/Apple 전송을 제공하는 다른 구현 또는 새로운 전송부가 필요합니다. 갱신 문제를 해결했다고 보거나 USB 개발을 계속하지 않습니다.

## 결론

Windows나 VS Code로 개발 장소를 옮겨도 watchOS 앱의 서명 요구는 사라지지 않습니다. 이번에는 **배포 경로를 바꾸거나 자체 Watch 실행 파일을 없애는 방법**을 조사했습니다. 무료·수동 갱신 없음·평소 아이폰 없음·외부 서버 없이 Bluetooth 알림·차량 제어라는 조건을 모두 만족하는 완성된 대체품은 찾지 못했습니다.

현재 기능을 유지하는 가장 현실적인 방향은 **FoldBridge의 App Store 배포**입니다. 사용자는 무료로 쓸 수 있지만 배포자의 멤버십 또는 회비 면제가 필요합니다. 자체 Watch 앱을 없애는 방향에서는 **시스템 프로토콜을 구현하는 Android 프로젝트**와 미루팅 USB 변경안을 발견했습니다. 현재 Fold7 / watchOS 27.2에서 사용 가능한 상태로 입증되지는 않았습니다.

Exa 검색 결과 65개 분량을 중복 포함해 조사하고 원저자 문서·소스와 Apple 문서를 읽었습니다. 제안과 실기기 성공 결과를 구분합니다. 기존 앱·페어링·기기 연결·중지된 갱신 예약은 변경하지 않았습니다. 시스템 로그 수집이나 차량 명령도 수행하지 않았습니다.

## 후보 비교

| 방향 | 매주 사용자 갱신 | 비용 | 기능과 남은 문제 |
| --- | --- | --- | --- |
| FoldBridge App Store 배포 | 없어짐 | 사용자 무료 가능. 배포자 멤버십 또는 면제 필요 | 기존 알림·차량 위젯 유지 방향. 심사·배포 작업 필요 |
| Android 시스템 프로토콜 | 자체 Watch 앱 제거 시 해당 갱신도 없어짐 | 무료 소프트웨어. 미루팅 후보는 USB Bluetooth 장치 필요 | 현재 기기 호환성 미입증. 차량 위젯은 별도 대체 필요 |
| 기본 단축어 → Galaxy 로컬 HTTP | 자체 Watch 앱 없이 제어 가능성 | 기본 단축어 무료 | 차량 제어만의 후보. 로컬 네트워크 필요. 백그라운드 알림 대체 불가 |
| 기존 무료 Watch Bluetooth 앱 | 사용자 개발용 갱신 없음 | 무료 후보 있음 | Berkanan Lite는 Watch 전면 실행 중에만 수신 |
| Merge | 사용자 개발용 갱신 없음 | 구독 필수 | 무료 조건에서 제외. 기존 차량 위젯 대체 미확인 |

## 1. 배포 변경: 현재 기능 유지

Apple은 **iOS 동반 앱 없는 watch-only 앱의 App Store 배포**를 지원합니다. 정상 사용에 아이폰 중계를 넣어야만 배포할 수 있는 것은 아닙니다. App Store 전환은 사용자 측의 Personal Team 7일 프로파일 갱신을 없애는 방향입니다. Apple의 코드 서명 자체는 남습니다. 배포 변경만으로 watchOS 백그라운드 실행 조건이나 Bluetooth 재연결 문제가 해결되는 것도 아닙니다. [Apple watch-only 배포 문서](https://help.apple.com/xcode/mac/current/en.lproj/devaba4602fd.html)

- **사용자가 무료로 사용:** 이미 멤버십이 있는 파트너가 무료 앱으로 배포할 수 있습니다. 비용과 운영 책임은 배포자에게 남으며 현재 확보된 파트너는 없습니다.
- **멤버십 회비도 면제:** 적격 비영리 법인·인가 교육기관·정부 기관이 Apple의 승인을 받는 경로입니다. 개인·개인 사업자·1인 사업자는 제외됩니다. 오픈소스 공개만으로 면제되지 않습니다. 면제 조직도 매년 자격을 확인해야 하므로 배포자 운영까지 무기한 무인화되지는 않습니다. [회비 면제 요건](https://developer.apple.com/help/account/membership/fee-waivers/)

TestFlight는 빌드 유효기간이 **90일**이어서 영구 대체가 아닙니다. Unlisted 배포도 App Store 심사를 거치는 방식이며 무료 개인 서명 우회가 아닙니다. [TestFlight](https://testflight.apple.com/) · [Unlisted 배포](https://developer.apple.com/support/unlisted-app-distribution/)

## 2. 자체 Watch 앱 제거: 시스템 Bluetooth 프로토콜

[`apple_watch_connector`](https://github.com/LordixDemon/apple_watch_connector)는 Android가 워치의 시스템 통신을 구현하는 프로젝트입니다. 자체 Watch 앱 대신 시스템 알림 경로를 사용하는 방향을 연구할 수 있습니다. 메인 문서의 실기기 기록은 Ultra 2 / watchOS 26.2이며 기본 Android 경로는 루팅과 특정 기기를 요구합니다. 현재 미루팅 Fold7 / watchOS 27.2 지원 결과로 볼 수 없습니다.

[PR #8: 미루팅 USB 모드](https://github.com/LordixDemon/apple_watch_connector/pull/8)는 Android USB Host API로 외장 Bluetooth 어댑터를 제어합니다. 조사일 기준 **미병합(open)**이고 작성자는 실기기 동작을 아직 확인하지 않았다고 명시합니다. 소프트웨어가 무료여도 어댑터를 새로 사야 한다면 총비용 0원은 아닙니다. Shizuku만으로 내장 Bluetooth 경로를 대체하는 변경도 아닙니다.

고정 소스: [`aa8578202e3ca4e5384aacf36f482d2272f54449` 설명](https://github.com/intragalactic-stranger/apple_watch_connector/blob/aa8578202e3ca4e5384aacf36f482d2272f54449/docs/NO_ROOT_USB.md). 설치 절차는 **초기화된 워치의 시스템 페어링 화면**을 요구합니다. 현재 시스템 페어링을 유지하는 업데이트가 아니므로 실행하지 않았습니다.

후속 [PR #12](https://github.com/LordixDemon/apple_watch_connector/pull/12)는 검색된 워치가 설정 목록에 표시되지 않는 파싱 문제를 수정합니다. 이것도 미병합이며 작성자의 실기기 확인은 없습니다. 검색 수정이 완전한 페어링·알림·watchOS 27.2 지원을 의미하지 않습니다.

차량 제어를 결합한다면 **Galaxy 차량 제어 알림의 동작 버튼 → 워치 알림 동작 → 기존 Galaxy 차량 코드**를 제안할 수 있습니다. 이는 새 개발 사항입니다. 현재 WidgetKit 위젯이 그대로 남거나 기존 워치 마이현대 버튼을 가로챌 수 있다는 뜻은 아닙니다.

## 3. 차량 제어만 분리: 기본 단축어

```text
워치 단축어 컴플리케이션 → 차량 제어 메뉴
  → 동일 Wi-Fi 또는 Galaxy 핫스팟의 로컬 HTTP
  → Galaxy 차량 제어 코드 → 공식 마이현대 위젯
```

Apple 기본 단축어 앱을 사용하면 자체 Watch 실행 파일을 배포하지 않는 구성을 연구할 수 있습니다. Apple은 워치 단축어와 컴플리케이션 실행을 지원하며 최초 표시 설정은 iPhone/iPad에서 합니다. 모든 동작이 워치에서 독립 실행되는 것은 아니므로 iPhone으로 위임되는 동작을 구분해야 합니다. [워치 단축어 안내](https://support.apple.com/guide/shortcuts/run-shortcuts-from-apple-watch-apd5888b0858/ios) · [로컬 실행·원격 위임 설명](https://developer.apple.com/videos/play/wwdc2020/10190/)

HTTP 요청을 사용하는 [원저자의 Watch 단축어 사례](https://github.com/iamsupersocks/siri-watch-repod-hermes-on-the-go)도 있습니다. **현재 watchOS 27.2에서 Galaxy 핫스팟의 차량 제어가 성공했다는 결과는 아닙니다.** Galaxy 로컬 수신부와 요청 인증을 새로 구현해야 합니다.

외부 중계 서버는 두지 않을 수 있지만 Bluetooth 전용 조건을 로컬 Wi-Fi로 바꿉니다. 사용자가 누르는 차량 제어 후보이며 잠긴 워치의 상시 알림 수신부를 대체하지 못합니다.

## 4. 기존 앱 대체 조사

- **Berkanan Messenger Lite:** 무료·오픈소스·독립형 Watch Bluetooth 앱이지만 제작자가 Watch 전면 실행 중에만 송수신한다고 명시합니다. 잠금·다른 앱 사용 중 수신 조건에 맞지 않습니다. [App Store 설명](https://apps.apple.com/us/app/berkanan-messenger-lite/id1479731429)
- **Merge:** 공식 설명상 구독 필수이며 무료 기간은 7일 체험입니다. 무료 상시 사용으로 분류하지 않습니다. [공식 Google Play 설명](https://play.google.com/store/apps/details?id=com.mergecorp.mergeandroid&hl=en)
- **wrist/off:** Watch HTTP 제어를 제공하지만 무료 범위는 버튼 하나입니다. 여러 차량 버튼의 완전한 무료 대체가 아닙니다. [제작자 안내](https://wristoff.com/)
- **Home Assistant / ntfy:** 전자는 서버 구조가 추가되고, 후자의 공식 Apple 앱은 iPhone/iPad 대상으로 독립 Watch 수신부가 확인되지 않았습니다. 현재 Bluetooth 수신부의 전체 대체 근거가 아닙니다. [HA Watch 문서](https://companion.home-assistant.io/docs/apple-watch/) · [ntfy 앱 안내](https://docs.ntfy.sh/subscribe/phone/)

## 다음 방향

**전체 기능 유지가 우선이면 App Store 배포 주체 확보**, **자체 Watch 앱 제거가 우선이면 네이티브 프로토콜의 미루팅 USB 후보 연구**가 다음 방향입니다. 차량 제어만 먼저 분리한다면 기본 단축어와 Galaxy 로컬 HTTP가 후보입니다.

무료·장치 추가 없음·시스템 페어링 유지·Bluetooth 전용·백그라운드 알림·차량 제어를 모두 유지하며 매주 갱신만 없애는 즉시 적용 가능한 경로는 확보하지 못했습니다. 이번 기록은 구조 선택을 위한 조사이며 앱 교체나 기능 완료 보고가 아닙니다.
