# Android 0.6.21 — 진단 버전과 연결 안내

**한국어** · [English](ANDROID_UI_0.6.21_EN.md) · [현재 상태](CURRENT_STATUS_KO.md)

2026-11-18 KST. Android **0.6.21-local / 코드 43**. 워치 **0.5.28 / 빌드 62**는 변경하지 않았습니다.

- 연결 진단은 화면을 열 때 설치 패키지의 버전명·빌드 번호를 읽습니다. 이번 설치본은 `WatchBridge 0.6.21-local (43)`으로 표시됩니다.
- 폰 메인 안내를 **“휴대폰과 워치를 연결해보세요.”**로 변경했습니다. 영어는 “Connect your phone and watch.”입니다.
- 기존 Android 서명 키·앱 ID `dev.foldbridge.local`을 사용해 삭제 없이 덮어 설치했습니다. 등록·설정 초기화나 새 페어링은 진행하지 않았습니다.
- REA 설치 뒤 앱 자체 상태에서 실제 빌드 **43**, 알림 접근·알림 수집 서비스 연결을 읽었습니다. 연결 방식·암호화·워치 코드는 바꾸지 않았으며 별도 거리·장시간 잠금 시험은 수행하지 않았습니다.

[APK 다운로드](https://github.com/mhj604/WatchBridge/releases/download/android-v0.6.21/WatchBridge-0.6.21.apk). 기존 사용자는 삭제하지 않고 업데이트합니다.

REA Evidence: 덮어 설치 `ev_5870520e329a137dc1c2b1bda18ca4db06fd1ca81be33ad7b2b8213a02e11cf6`, 실행 `ev_13318131405b69c17c88e1bedcbf6fb06808ed7c95d185f183dee2cfe24afdac`, 설치 후 빌드 43 `ev_362c45d341a7973d6939134291cc84074a1583d91b6759d75dd5dd78d4b64fd4`. 원본 기록과 서명 키는 로컬에만 보관합니다.

설치 후 기존 등록으로 인증 링크·읽기 수신도 자동 복원됐습니다. 폰 새로고침은 0회였으며 오류는 없었습니다. Evidence: `ev_df5c592042ec4be77c3c4acf0d72862576c76c902f0855d622ad77084a4ec710`.
