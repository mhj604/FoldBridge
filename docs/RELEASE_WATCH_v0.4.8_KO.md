# Watch 0.4.8 / Android 0.5.3 — 첫 등록 알림 정리와 자동 재연결

**한국어** · [English](RELEASE_WATCH_v0.4.8_EN.md) · [전체 문서](README.md)

- Watch **0.4.8 / build 22**
- Android **0.5.3-local / versionCode 14**

## 바뀐 동작

첫 신규 워치 등록이 성공하는 순간 Android가 그 전에 쌓인 미전달 알림을 비웁니다. 등록 시각은 암호화 저장소에 보관하고, 서비스 재시작 뒤 활성 알림을 다시 수집할 때도 등록 전 알림을 걸러냅니다. 그래서 새 등록 뒤에는 그 시점 이후 게시된 알림부터 워치로 보냅니다. 이미 등록된 기기의 연결을 복구할 때는 대기 알림을 지우지 않습니다.

저장된 상대에 연결할 때 watchOS Core Bluetooth 자동 재연결을 요청합니다. OS가 재연결 중이라고 알리면 워치는 같은 연결 객체를 유지해 자체 유지보수 타이머가 시스템 연결 시도를 취소하지 않습니다. 연결이 돌아오면 GATT 특성을 다시 찾고 새 nonce로 기기를 인증합니다. Android는 기존 BLE 광고와 재시도·재검색 경로를 유지합니다.

## 설치

기존 앱 위에 업데이트하려면 이전 설치 때 사용한 Android 서명 키, Android 앱 ID, 워치 Bundle ID와 Apple Team을 유지합니다. 등록을 새로 할 필요는 없습니다. 새 사용자는 첫 등록 완료 뒤부터 알림을 받습니다.

- [Android APK 다운로드](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.8/FoldBridge-Local-0.5.3.apk)
- [워치 소스 ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.8/FoldBridge-watch-0.4.8-source.zip)
- [한글·영어 안내 ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.8/FoldBridge-0.4.8-guides-ko-en.zip)

## 연결 범위

두 기기가 가까워지면 저장된 연결로 자동 복구를 시도합니다. 물리 Bluetooth 링크는 거리, 전파 간섭, 배터리·전원 상태에 따라 끊길 수 있고, watchOS가 앱이나 Bluetooth 동작을 제한하면 복구가 늦어질 수 있습니다. 이 변경은 자동 재연결 요청과 재시도 경로를 추가하며, 끊김 방지나 즉시 재연결을 보장하지는 않습니다.

일반 연결 문제는 양쪽에서 반복해서 누르지 말고 한 기기에서만 **연결 새로고침**을 누른 뒤 상태가 바뀔 때까지 기다립니다. [문제 해결](TROUBLESHOOTING_KO.md) · [BLE 프로토콜과 복원 경로](PROTOCOL.md)
