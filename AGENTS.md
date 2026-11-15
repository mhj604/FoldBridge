# WatchBridge development

- 원인 조사는 [REA](https://github.com/morluto/rea)를 우선 사용한다. 기존 MCP가 없으면 REA CLI를 사용하며 Evidence를 보관한다. REA가 직접 지원하지 않는 watchOS 기기 조작은 별도 도구 사용임을 명시한다. 소스 검색만으로 REA 동적 분석을 수행했다고 표현하지 않는다.
- 기존 등록·차량 설정을 유지한다. 표시 이름은 WatchBridge이지만 설치 ID, 키체인/저장 키, BLE UUID, 암호화 문맥, 위젯 kind와 기존 소스 경로는 호환성을 위해 유지한다.
- 등록 삭제나 전체 초기화를 자동 복구 방법으로 사용하지 않는다. 실제 차량 명령을 디버깅 과정에서 실행하지 않는다.
- 시스템 로그 수집·관리자 암호 요청은 진행하지 않는다. 앱 자체 상태/이벤트 기록에서 관측 사실과 추정을 구분한다.
- 잠금 인증 성공, 알림 수신, 지속 연결, 장시간 잠금, 실제 거리 이탈/복귀는 다른 조건이다. 관측하지 않은 조건을 해결됐다고 기록하지 않는다.
- 현 소유자 기기에서 작업을 마칠 때는 저장된 등록은 유지하고 폰의 ‘설정 → 연결 중지’로 실제 Galaxy–Watch 연결을 종료한다. 이어 Mac 디버깅/미러링을 종료한다. 처리하지 못한 조작은 구체적으로 남긴다.

English: Use REA evidence for runtime investigation. Preserve pairing and stable installation/protocol identifiers when changing visible branding. Do not collect system logs, request administrator passwords, reset registrations, or execute vehicle commands. Report observations and remaining conditions honestly. When working on the owner's devices, stop the actual phone service while retaining registration, then close Mac debugging.
