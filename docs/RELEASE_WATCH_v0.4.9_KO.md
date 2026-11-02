# Watch 0.4.9 / Android 0.5.4 — 연결 이후 새 알림과 자동 복구

**한국어** · [English](RELEASE_WATCH_v0.4.9_EN.md) · [전체 문서](README.md)

- Watch **0.4.9 / build 23**
- Android **0.5.4-local / versionCode 15**

## 알림 전달 기준

첫 등록뿐 아니라 **모든 재연결의 인증 완료 시점** 이후에 게시된 알림만 전달합니다. 연결 이전의 활성 알림과 연결이 끊긴 동안의 알림은 나중에 몰아서 보내지 않습니다. Android의 실제 게시 시각으로 지연 콜백도 거릅니다.

미확인 알림은 현재 연결에서만 메모리로 재시도하고, 끊김이나 프로세스 재시작 때 비웁니다. 이전 버전의 암호화된 outbox도 업데이트 후 서비스가 시작될 때 제거합니다. 워치에서도 이전 연결의 아직 표시하지 않은 알림과 지연 표시 콜백을 폐기합니다. 이미 watchOS 알림 센터에 표시된 알림은 유지합니다.

## 연결 유지와 복구

- Android는 연결되면 광고를 멈추고, 끊기면 같은 GATT 서버에서 다시 광고합니다. 광고 준비 실패는 별도로 재시도하므로 정상 GATT 서버를 닫지 않습니다.
- 워치는 OS 자동 재연결 요청을 유지하고, 서비스 UUID로 제한한 복구 검색을 전면 실행 조건이나 20초 종료 타이머 때문에 취소하지 않습니다.
- 백그라운드 끊김 콜백에서 저장된 상대의 연결을 바로 OS에 요청합니다. 연결이 끊긴 캐시 객체 때문에 이후 재접속이 전부 생략되던 경로도 수정합니다.
- 정상 연결에서 한쪽 새로고침은 기존 연결과 암호화 세션을 보존합니다. 등록 키·언어·앱 선택·원본 아이콘·알림 상세 배치는 유지합니다.

Bluetooth 범위, 전파 간섭, 전원과 watchOS 실행 제한 때문에 물리적 연결이 끊기거나 복구가 지연될 수 있습니다. 이 변경은 불필요한 취소 경로를 줄이고 복구 요청을 유지하며, 무단절 또는 즉시 재접속을 보장하지는 않습니다.

## 업데이트

기존 앱을 삭제하지 않고 같은 Android 서명 키와 워치 Bundle ID/Team으로 업데이트합니다. 다시 코드로 등록할 필요는 없습니다.

- [Android APK](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-Local-0.5.4.apk)
- [워치 소스 ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-watch-0.4.9-source.zip)
- [한글·영어 문서 ZIP](https://github.com/mhj604/FoldBridge/releases/download/watch-v0.4.9/FoldBridge-0.4.9-guides-ko-en.zip)
- [케이블 없는 갤럭시 업데이트](WIRELESS_INSTALL_KO.md)
