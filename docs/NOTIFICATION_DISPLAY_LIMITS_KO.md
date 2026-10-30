# 알림 표시 요청의 현재 미해결 범위

Watch 0.4.3 / 빌드 14 기준. 상세 본문의 작은 원본 아이콘과 텍스트는 사용자가 정상 표시된다고 보고했다. 다음 두 요청은 아직 구현되지 않았다.

- 첫 요약 팝업과 눌러 펼친 화면을 동일한 레이아웃으로 표시하기
- 첫 팝업·알림 센터 카드·상세 화면 모두에서 원본 Android 앱 아이콘 사용하기

## 화면마다 누가 표시하는가

| 영역 | 표시 주체 | 현재 표시 | 앱에서 가능한 변경 |
| --- | --- | --- | --- |
| 첫 요약 팝업(short-look) | watchOS | FoldBridge 아이콘·이름, 알림 제목 | 제목 제공. 시스템 템플릿 자체는 변경 불가 |
| 알림 센터의 기본 카드 | watchOS | FoldBridge 앱에 속한 알림 | 제목·내용·묶음 ID 제공. 일반 알림별 원본 앱 아이콘 지정 API는 없음 |
| 펼친 화면의 상단 sash | watchOS | FoldBridge 아이콘·이름 | 지원되는 색상·흐림 속성. 다른 앱으로 발신 주체 교체 불가 |
| 펼친 화면의 본문 | FoldBridge SwiftUI | 원본 앱 이름·제목·본문, 24pt 원본 아이콘 | 본문 레이아웃·이미지 변경 가능 |

Apple은 short-look을 시스템이 생성하며 사용자 정의할 수 없다고 명시한다. long-look은 별도의 스크롤 화면이고 본문을 사용자 정의할 수 있다. 따라서 SwiftUI 본문을 수정하는 것으로 두 단계의 전체 레이아웃을 같게 만들 수는 없다. [알림 표시 구조](https://developer.apple.com/documentation/watchos-apps/presenting-notifications-on-apple-watch)

## 추가로 조사한 통신 알림

`UNNotificationContent.updating(from:)`와 `INSendMessageIntent`의 알림 콘텐츠 제공은 watchOS 8 이상에서 지원된다. 메시지 발신자의 아바타를 시스템 알림에 표현하는 별도 경로다. API가 SDK에 있다는 사실만으로 현재 서명 계정에서 사용할 수 있다는 뜻은 아니다. [콘텐츠 업데이트 API](https://developer.apple.com/documentation/usernotifications/unnotificationcontent/updating(from:))

Apple 구현 문서는 Communication Notifications 기능, 지원하는 intent의 `NSUserActivityTypes` 선언, 발신자·참여자 정보와 상호작용 기부를 요구한다. 목적은 사람 간 메시지·통화이며 모든 일반 앱 알림의 아이콘 교체 기능이 아니다. 모든 시스템·쇼핑·금융 알림을 사람의 메시지로 바꾸면 알림의 의미와 Focus 처리가 달라진다. [통신 알림 구현](https://developer.apple.com/documentation/usernotifications/implementing-communication-notifications)

Apple의 watchOS 지원표에서 Communication Notifications는 유료 프로그램에 지원 표시가 있고 무료 Apple Developer 열에는 없다. 현재 Personal Team으로는 이 경로를 사용할 수 없다. 유료 가입을 하더라도 모든 알림 단계의 아이콘·배치를 요구대로 제어할 수 있다는 근거는 없다. [watchOS 권한 지원표](https://developer.apple.com/help/account/reference/supported-capabilities-watchos/)

## 다시 사용하지 않는 방식

- 원본 앱 그림을 `UNNotificationAttachment`에 넣기: 시스템이 미디어로 표시해 팝업의 그림이 커지고 카드 썸네일에 재사용됐던 방식이다. PNG 크기를 줄이는 것으로 시스템 표시 영역을 제어할 수 없다.
- 상세 본문의 그림 변경을 시스템 앱 아이콘 교체로 설명하기: 서로 다른 영역이며 전체 요청을 해결한 것이 아니다.
- 일반 알림을 모두 사람 간 메시지로 취급하기: 일반 알림을 원래 앱에서 온 시스템 알림으로 바꾸는 API가 아니다.

## 현재 배포 상태

이 조사는 앱 수정·설치 완료를 의미하지 않는다. 설치된 Watch 0.4.3 / 빌드 14와 Galaxy 0.5.0은 유지한다. 작동 중인 상세 본문을 다시 변경하거나 테스트 알림을 보내지 않았다. 무료 서명·일반 watchOS 앱·서버와 아이폰 없는 사용이라는 현재 조건에서 두 요청을 모두 충족하는 지원 API 경로는 찾지 못했다.
