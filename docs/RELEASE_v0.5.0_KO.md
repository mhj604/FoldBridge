# FoldBridge Local 0.5.0 — 앱 내 한국어 / English 선택

- Galaxy: **0.5.0-local / versionCode 10**
- Watch: **0.4.0 / build 11**
- 사용 브랜치: [local-ble](https://github.com/mhj604/FoldBridge/tree/local-ble)
- 설치 순서: [한국어 빠른 시작](https://github.com/mhj604/FoldBridge/blob/local-ble/docs/QUICK_START_KO.md)

## 언어 변경

양쪽 앱의 **설정 → 언어 / Language**에서 **시스템 설정·한국어·English**를 선택합니다. 기기마다 따로 저장되며 재시작 후에도 유지됩니다. 영어 화면에서는 **Settings → Language / 언어**로 들어갈 수 있습니다.

버튼·설정·연결 상태·오류·진단·앱 자체 연결 알림에 영어를 추가했습니다. 받은 메시지와 원본 앱 이름은 번역하지 않습니다. 언어를 바꿔도 등록과 미전달 알림을 유지합니다.

## 설치

첨부 APK는 Android용입니다. 같은 배포 서명을 사용해 기존 Local APK 위에 업데이트합니다. 워치 앱은 소스의 Xcode 프로젝트를 자신의 Team/Bundle ID로 빌드·설치합니다. 다른 사람의 Apple 서명 프로파일은 배포하지 않습니다.

서버·인터넷·아이폰 중계 없이 BLE로 알림을 전달합니다. 워치 초기 설정과 설치에는 Apple 개발 환경이 필요하며, watchOS 실행 제한으로 모든 알림의 상시·즉시 수신을 보장하지는 않습니다.
