# FoldBridge Watch 0.4.1 — 알림 상세 화면 복원

- Watch: **0.4.1 / build 12**
- Android: **0.5.0-local 유지** — 기존 앱을 그대로 사용합니다.

## 수정 내용

알림 센터 카드는 정상이지만 누른 뒤 펼친 상세 화면이 깨지는 문제에 대응해 사용자 정의 SwiftUI 알림 화면 자체를 제거했습니다. 초기 버전과 동일하게 watchOS 기본 알림 화면이 제목·본문·줄바꿈·스크롤을 처리합니다.

원본 앱 아이콘은 표준 이미지 첨부로 넘깁니다. 직접 그리는 아이콘 헤더는 사용하지 않습니다. 첨부 실패 시에도 텍스트 알림은 별도로 등록합니다. 기존 알림을 지우거나 다시 울리지 않고, 언어·등록 키·대기열을 유지합니다.

## 설치

[local-ble 브랜치](https://github.com/mhj604/FoldBridge/tree/local-ble)나 소스 ZIP에서 `watch/FoldBridge.xcodeproj`를 열어 기존 Team과 Bundle ID로 워치 앱을 업데이트합니다. 처음 설치는 [한국어 빠른 시작](https://github.com/mhj604/FoldBridge/blob/local-ble/docs/QUICK_START_KO.md)을 따릅니다. Apple 서명 프로파일은 배포하지 않습니다.

배포에 포함한 Android APK는 기존 0.5.0과 같은 파일입니다. 이 수정은 워치 앱에 적용됩니다.
