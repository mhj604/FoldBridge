# 무료 계정 워치 앱 자동 갱신

**한국어** · [English](AUTO_RENEW_EN.md) · [문서](README.md)

무료 Personal Team의 7일 유효기간을 없애는 기능이 아닙니다. Mac에서 기존 Xcode 계정으로 새 프로파일을 요청하고 같은 앱·위젯을 다시 서명해 덮어 설치하는 작업을 자동화합니다. 앱 등록과 설정은 유지하며 앱을 삭제하지 않습니다.

## 구성

- 실행 도구: [`tools/watch-auto-renew.py`](../tools/watch-auto-renew.py), Python 표준 라이브러리와 Xcode만 사용합니다.
- 예약: 이 채팅의 Codex 자동 실행이 **6시간마다** 도구를 실행합니다. 다른 사용자에게 이 예약이 함께 설치되지는 않습니다.
- 갱신 조건: 앱·포함된 확장 중 가장 이른 만료까지 **72시간 이내**일 때만 빌드합니다.
- Mac과 Codex 앱이 켜져 있고, Xcode가 로그인되어 있어야 합니다. 갱신할 때 워치가 Mac과 개발용 무선 연결이 가능하고 잠금 해제 상태여야 합니다.
- 워치가 없거나 잠겼으면 기존 앱을 유지하고 다음 실행에서 재시도합니다. Mac 전원이 꺼져 있거나 장기간 워치와 떨어져 있으면 만료를 막을 수 없습니다.

## 실제 갱신 처리

1. 현재 설치된 앱의 빌드 번호와 저장소에 커밋된 빌드 번호가 같은지 확인합니다. 다른 버전을 자동으로 설치하지 않습니다.
2. 저장소의 커밋된 `watch/`만 별도 작업 폴더에 추출합니다. 작성 중인 로컬 변경은 빌드하지 않습니다.
3. 지정한 Team의 FoldBridge 앱·위젯에 해당하는 프로파일만 백업하고 Xcode 캐시에서 옮깁니다. 다른 앱의 프로파일은 변경하지 않습니다.
4. `xcodebuild -allowProvisioningUpdates`로 새 프로파일을 요청하고 빌드합니다.
5. 실제 새 만료일이 연장된 경우에만 갱신본으로 취급합니다. 워치가 연결되지 않으면 빌드 결과를 보관하고 다음 실행에서 설치를 재시도합니다.
6. `devicectl`로 같은 앱에 덮어 설치한 뒤 FoldBridge를 실행해 연결 복구를 시작합니다. 차량 명령은 실행하지 않습니다.

[Apple의 프로파일 갱신 절차](https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles)와 [무료 계정 유효기간 안내](https://developer.apple.com/help/account/basics/about-your-developer-account)를 따릅니다.

## 다른 Mac에서 설정하기

자신의 Team으로 빌드해 실제 워치에 설치한 `.app` 경로와 워치 UDID를 사용합니다. Bundle ID와 Team은 해당 서명본에서 읽습니다.

```sh
python3 tools/watch-auto-renew.py \
  --setup-from-app /absolute/path/to/FoldBridge.app \
  --device YOUR_WATCH_UDID
```

기본 설정·상태 경로는 `~/Library/Application Support/FoldBridge/AutoRenew/`입니다. `config.json`에는 저장소·Xcode 경로, Team·기기·Bundle ID, 설치본의 만료일만 기록합니다. 비밀번호나 인증서는 저장하지 않습니다. 프로파일 백업과 빌드 로그도 이 로컬 폴더에 보관하며 공개 저장소에 올리지 않습니다.

예약할 실행 명령:

```sh
/usr/bin/python3 /absolute/path/to/FoldBridge/tools/watch-auto-renew.py
```

Codex에 위 명령을 6시간마다 실행하도록 요청하면 됩니다. 예약에는 유효기간이 충분하면 조용히 종료하고, 실제 갱신 완료·인증 조작 필요·만료 임박 때만 알려 달라는 조건을 포함합니다. 예약은 Mac과 Codex가 실행 중일 때 동작합니다. [OpenAI 예약 실행 안내](https://learn.chatgpt.com/docs/scheduled-tasks)

`--force`는 최초 적용 등 즉시 새 프로파일을 요청할 때만 사용합니다. 정기 실행에는 붙이지 않습니다.

## 상태와 필요한 조작

| 상태 | 의미 |
| --- | --- |
| `not_due` | 유효기간이 충분해 아무것도 변경하지 않음 |
| `renewed` | 새 서명 발급·설치·앱 실행 완료 |
| `waiting_watch_connection`, `waiting_watch_unlock` | 워치 연결 또는 잠금 해제 대기 |
| `renewed_waiting_watch`, `install_pending` | 새 빌드를 보관하고 설치 재시도 대기 |
| `renewed_waiting_app_launch`, `waiting_app_launch` | 설치 후 앱 실행을 다음 기회에 재시도 |
| `build_failed`, `renewal_not_extended` | 빌드/프로파일 발급 문제. 로컬 `build.log`에 원인 기록 |
| `source_version_differs` | 설치본과 커밋된 소스 버전이 달라 갱신 중지 |

Apple 재로그인·2단계 인증·Mac 키체인 승인이 필요하면 그때는 사용자가 직접 처리해야 합니다. 이를 자동으로 통과시키지 않습니다. 서명 갱신은 watchOS의 백그라운드 실행 조건이나 마이현대 인증 조건을 바꾸지 않습니다.

최초 적용에서는 Watch 0.5.2의 서명을 새로 발급받아 같은 기기에 덮어 설치하고 앱을 실행했습니다. 매 빌드가 자동으로 유효기간을 연장하는 것은 아니므로, 도구는 빌드 결과의 실제 만료일을 사용합니다.
