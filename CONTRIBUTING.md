# 기여 방법

**한국어** · [English](CONTRIBUTING.en.md) · [전체 문서](docs/README.md)

`local-ble`은 서버 없는 BLE 사용 구성을 찾기 위한 브랜치입니다. `main`에도 현재 변경을 반영합니다. 수정할 때는 최신 브랜치에서 자신의 작업 브랜치를 만들어 PR을 보내 주세요.

```sh
git clone --branch local-ble https://github.com/mhj604/FoldBridge.git
cd FoldBridge
git switch -c fix/your-change
```

## 코드 위치

| 경로 | 역할 |
| --- | --- |
| `android/app/src/main/java/dev/foldbridge/` | 알림 접근·GATT 서버·암호화·미전달 대기열·Android UI |
| `watch/FoldBridge/` | GATT 클라이언트·인증·알림 표시·연결 유지·SwiftUI |
| `watch/generate_project.py` | Xcode 프로젝트와 Info.plist 생성 |
| `tools/generate-app-icon.swift` | 두 앱의 공통 아이콘 생성 |
| `docs/` | 한국어·영어 설치·문제 해결·구조·프로토콜 |
| `relay/`, `windows/`, `legacy/` | 과거 구성 보존. 현재 Local 실행 경로에서 제외 |

빌드 준비는 [빌드 문서](docs/BUILD_AND_SETUP.md), 처음 설치는 [빠른 시작](docs/QUICK_START_KO.md)을 따릅니다. 자신의 Android 서명 키와 Apple Team을 사용합니다. `generate_project.py`가 생성하는 설정을 바꾼 경우 생성 코드에도 같은 변경을 반영합니다.

현재 실행 구성에는 서버·인터넷·운동/오디오 세션·루팅을 넣지 않습니다. 원래 기능의 한계를 없앴다고 표현하지 말고 watchOS 실행 조건을 문서에 함께 설명합니다. 알림 본문·기기 식별자·개인 로그·서명 키·프로비저닝 파일은 이슈나 PR에 포함하지 마세요. 오류를 공유할 때는 권한/연결 단계와 관련 오류 문구만 남겨 주세요.

## 앱 번역 수정

`localization/en.json`을 편집하고 `python3 tools/generate-localization.py`를 실행한다. 한국어 문구는 원본 키이며 Android와 워치가 같은 번역 카탈로그를 사용한다. 생성된 문자열 파일과 `I18n.java`는 직접 수정하지 않는다. 새로운 Swift 파일/언어 리소스 구성이 바뀌면 `python3 watch/generate_project.py`도 실행한다. 메시지 본문, 원본 앱 표시명, 사용자가 붙인 기기 이름은 번역 대상으로 바꾸지 않는다.


## 문서와 문의

[전체 문서](docs/README.md)에서 한국어·영어 문서 쌍을 찾을 수 있습니다. 현재 설치 방법·버전·다운로드·동작 범위를 바꾸면 두 언어에 함께 반영합니다. 이전 릴리스 원문은 이력으로 보존합니다. 한국어나 영어로 이슈를 남길 수 있으며, 이슈 작성 화면에 문제 보고·기능 및 문서 제안 양식을 제공합니다.
