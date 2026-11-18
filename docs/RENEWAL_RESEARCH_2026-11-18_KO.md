# 워치 단독 무료 갱신 — 2026-11-18 후속 조사

**한국어** · [English](RENEWAL_RESEARCH_2026-11-18_EN.md) · [현재 버전·우선순위](CURRENT_STATUS_KO.md)

목표는 기존 앱·등록·차량 설정을 유지하면서 Mac·PC·아이폰 없이 워치 인터넷만으로 무료 서명을 자동 갱신하고 적용하는 것입니다. 이번 조사는 Exa로 관련 프로젝트를 찾고 GitHub 커넥터로 실제 갱신 경로를 읽었습니다. 다른 도구 설치·기기 재등록·새 서명 발급은 하지 않았습니다.

## 발견한 코드와 조건

| 자료 | 실제 지원과 부족한 부분 |
| --- | --- |
| [AdminZachary/WatchBridge](https://github.com/AdminZachary/WatchBridge) | 이 저장소와 이름만 같은 별개 iLoader 파생 프로젝트입니다. README는 PC에서 아이폰과 `Watch/*.app`이 함께 들어 있는 IPA를 설치하는 흐름을 설명합니다. 기존 독립형 워치 앱에 바로 적용하는 흐름이 아닙니다. |
| [동 프로젝트 갱신 백엔드](https://github.com/AdminZachary/WatchBridge/blob/main/src-tauri/src/renewal/live.rs#L167-L173) | 실제 `connect_device`는 `watch.is_some()`이면 **`Failure::WatchNotSupported`**를 반환합니다. `prepare`와 `discover`도 `require_phone_job`을 호출합니다. README의 자동 갱신 소개만으로 Watch 자동 갱신 지원이라고 판단하면 안 됩니다. |
| [TetherlessiOS](https://github.com/pwnapplehat/TetherlessiOS) | README의 무료 자동 갱신은 아이폰의 LocalDevVPN·개인 자동화에 의존합니다. 조회한 공개 루트에는 README·웹사이트·assets가 있으며 워치 설치/갱신 앱의 구현은 확인하지 못했습니다. “컴퓨터 없음”을 “워치 단독”으로 해석할 수 없습니다. |
| [SideStore](https://github.com/SideStore/SideStore) | iOS 앱과 LocalDevVPN/로컬 장치 연결 경로입니다. 현재 워치 앱 안에서 무료 프로파일을 교체하는 구현으로 사용할 근거가 없습니다. |
| [Sideloadly 변경 기록](https://sideloadly.io/changelog.html) | 조회된 v0.71.0은 Developer Program 계정의 Watch 서명 처리를 설명하며 무료 Watch 지원은 후속 예정으로 안내합니다. PC 자동 갱신과 워치 단독 갱신은 별개입니다. |
| [idevice 원격 페어링 도구](https://github.com/jkcoxson/idevice/blob/a64b8867/tools/src/pair_rsd_ios.rs) | 장치 서비스에 연결하는 Rust 도구 구성 요소입니다. 이 코드가 존재한다는 사실은 watchOS 앱 내부에서 자신을 갱신·설치할 권한이나 자동 실행 경로가 있다는 뜻이 아닙니다. |
| [Apple Watch MDM 배포](https://support.apple.com/guide/deployment/deploy-apple-watch-dep04f0c5414/web) | 관리형 아이폰을 통한 워치 등록과 앱 관리 경로입니다. 기존 개인 페어링을 유지하는 무료 Personal Team 앱의 워치 단독 갱신 대체로 제시하지 않습니다. |

## 결론과 구현상 빠진 부분

**이번에 읽은 공개 코드에서는 목표 조건을 충족하는 워치 단독 무료 자동 갱신 경로를 확보하지 못했습니다.** 서명용 프로파일을 Apple에서 발급받는 것뿐 아니라, 워치의 설치 서비스에 그 프로파일을 적용할 통로와 만료 전에 실행할 기회가 모두 필요합니다. 아이폰 설치 코드를 복사하거나 프로파일만 다운로드하는 기능을 추가해도 이 단계를 대신하지 못합니다. 모든 미래 구현이 불가능하다고 단정하는 결론은 아닙니다.

따라서 앱에 작동하지 않는 “인터넷 자동 갱신” 토글을 추가하거나 다른 프로젝트의 아이폰 자동 갱신을 워치 지원으로 표시하지 않았습니다. 실제 워치 설치/프로파일 교체를 수행하는 새 코드가 확보되면 해당 경로부터 다시 조사합니다.

## 기존 주간 Mac 구성

설정 파일의 현재 기록은 Watch **0.5.26 / 빌드 60**, 커밋 **95577b5**입니다. 가장 이른 기록상 만료는 **2026-11-20 17:10:54 KST**, macOS 기본 예약은 **매주 금요일 16:00**입니다. 이 작업에서는 갱신 실행·예약 변경을 하지 않았습니다. 구성 파일이 존재한다는 사실과 새 서명·설치의 실제 성공을 구분합니다. Mac이 깨어 있고 워치 개발 연결과 잠금 해제가 가능해야 하는 조건은 여전히 남습니다. [자동 갱신 사용 조건](AUTO_RENEW_KO.md).
