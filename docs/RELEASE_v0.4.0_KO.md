# FoldBridge Local 0.4.0

갤럭시 알림을 Apple Watch로 BLE 직접 전달하는 Local 배포입니다.

- Galaxy 앱: **0.4.0-local / versionCode 9**
- Watch 앱: **0.3.0 / build 10**
- 사용 브랜치: [local-ble](https://github.com/mhj604/FoldBridge/tree/local-ble)
- 설치 순서: [한국어 빠른 시작](https://github.com/mhj604/FoldBridge/blob/local-ble/docs/QUICK_START_KO.md)

## 이번 변경

두 앱에 연결 새로고침을 추가했습니다. 기존 등록과 휴대폰 미전달 알림을 유지한 채 연결·인증 세션을 새로 준비합니다. 닫힌 GATT 서버의 콜백, 중복 인증 시작, 인증 성공 후 남는 과거 만료 오류를 정리했습니다.

워치 아이콘은 밝기·면적을 반영한 중심으로 다시 생성하고 리소스 이름도 변경했습니다. 한국어 설치·문제 해결·기여 안내를 함께 정리했습니다.

## 다운로드와 설치

첨부된 `FoldBridge-Local-0.4.0.apk`는 갤럭시용입니다. 기존 Local 배포 APK 위에 업데이트할 수 있습니다. 직접 다른 키로 빌드한 앱과는 서명이 다를 수 있습니다.

워치 앱은 소스의 `watch/FoldBridge.xcodeproj`를 자신의 Mac/Xcode에서 열어 자신의 Apple Team과 고유 Bundle ID로 빌드·설치합니다. 다른 사람의 워치에 바로 설치할 수 있는 Apple 서명 앱은 첨부하지 않습니다. 소스 ZIP 또는 브랜치에서 받으세요.

## 연결이 풀렸다면

두 기기를 가까이 두고 워치 잠금을 풉니다. Galaxy의 **연결 새로고침**, Watch의 **연결 새로고침** 순서로 누릅니다. 일반적인 재연결에는 새 등록이나 코드 확인이 필요하지 않습니다.

## 동작 조건

알림 전달에 서버·인터넷·아이폰 중계를 쓰지 않습니다. 워치 초기 설정·앱 설치에는 Apple 개발 환경이 필요합니다. 위치 연결 유지는 실험 기능이며 watchOS 중단·종료·실행 예산과 Bluetooth 범위에 영향을 받습니다. 모든 알림의 상시·즉시 수신을 보장하지 않습니다.
