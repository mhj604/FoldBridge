# FoldBridge Local BLE 프로토콜

Android는 GATT peripheral/server, watchOS는 central/client다. 앱 안에서 휴대폰을 선택하며 Android 시스템 Bluetooth 페어링을 별도로 요구하지 않는다.

## GATT와 프레임

| 용도 | Local UUID |
| --- | --- |
| 서비스 | `c62d0200-7de5-4c34-a432-7c838e687a40` |
| 휴대폰 → 워치 | `c62d0201-7de5-4c34-a432-7c838e687a40`, indication |
| 워치 → 휴대폰 | `c62d0202-7de5-4c34-a432-7c838e687a40`, write with response |

CCC는 `0x2902`이고 Local 구독 값은 indication 활성화다. 기존 FoldBridge 프로필은 `c62d0100/0101/0102` 계열을 사용한다.

각 ATT 값은 big-endian message ID(uint32), 조각 index(uint16), 전체 조각 수(uint16), payload로 구성한다. 조각은 협상된 ATT 크기와 200바이트 중 작은 값을 사용하며 헤더는 8바이트다. 메시지 상한은 16,384바이트, 조립 제한 시간은 120초다. 순서대로 조립하며 새 연결에서 조립/전송 상태를 초기화한다.

## 최초 등록과 암호화

각 기기는 영속 P-256 ECDH 키를 만든다. Android 개인 키는 Android Keystore, 워치 키는 기기 전용 Keychain에 둔다.

1. 워치가 새 32바이트 nonce로 `SHA256(SPKI_DER_public_key || nonce)` commit을 보낸다.
2. 휴대폰도 자신의 키와 새 nonce를 commit한다.
3. 워치가 공개 키/nonce를 reveal하고 휴대폰이 검증한 뒤 자신의 값을 reveal한다.
4. 워치도 commit을 검증한다. 이미 고정된 상대 공개 키가 바뀌면 연결을 거부한다.
5. ECDH 결과와 HKDF-SHA256(salt=`watch_nonce || phone_nonce`, info=`FoldBridge/v1`)으로 32바이트 세션 키를 만든다.
6. `SHA256(key || UTF8("compare"))` 앞 4바이트를 big-endian uint32로 읽어 1,000,000으로 나눈 나머지를 6자리 코드로 표시한다.
7. 처음에는 양쪽 사용자가 코드를 비교해 확인한다. 등록된 키는 다음 연결에서 자동 확인한다.

AES-256-GCM의 AAD는 `FoldBridge/v1`이다. 휴대폰 nonce prefix는 `FBP1`, 워치는 `FBW1`이며 뒤에 64비트 순번을 붙인다. 같은 방향의 반복/감소 순번을 거부한다. 연결마다 새로운 양쪽 nonce로 세션 키를 다시 파생한다.

암호화 envelope는 `{type:"sealed", seq:1, data:"base64(ciphertext || tag)"}`다. Local 실행 경로의 메시지는 `confirm`, `ready`, `state`, `sync`, `notification`, `ack`다. 기존 Push 지원 소스는 남아 있으나 Local은 APNs 토큰을 보내거나 서버를 사용하지 않는다.

## 알림과 수신 확인

`notification`에는 Android 알림 키의 해시 ID, 제목/본문의 해시 리비전, 앱 표시명, 제목, 본문, 게시 시각을 넣는다. 최초 양쪽 확인 전에는 전달하지 않는다.

미전달 목록은 암호화해 최대 24시간/1,024개를 보관하고 ID별 최신 리비전으로 대체한다. 한 메시지씩 보내며 앱 ACK를 기다린다. 90초 내 확인이 없으면 최대 3회 시도 후 연결을 다시 맺고 미확인 항목을 재전송한다. Android 서비스 시작/알림 접근 재연결 때 현재 알림을 다시 가져온다.

워치는 표시 권한을 확인한 뒤 로컬 알림을 등록하고 성공 시 ACK한다. 이미 기억하는 동일 리비전은 다시 표시하지 않고 ACK한다. ACK는 표시 요청 수락/기존 수신 기록 확인이며 화면 표시·진동·열람을 보장하지 않는다. 워치는 최근 알림 목록 100개와 중복 판별 기록 512개를 보관한다.

충전 상태 필터는 Android의 수집 단계에 적용하므로 wire 형식 변경이 없다. 앱 내부의 `state`/`sync` 메시지는 사용자에게 알림을 만드는 메시지가 아니다.

## 실행 한계

이 프로토콜은 OS 실행 예산을 늘리지 않는다. 위치 기반 연결 유지에서도 watchOS의 중단/종료나 Bluetooth 범위 이탈로 지연될 수 있다. 정적 ECDH 신원 키를 사용하므로 신원 키 유출 이후의 전방향 안전성을 주장하지 않는다. 초기 APNs 설계는 `legacy/docs/PROTOCOL-0.1.0.md`에 별도 보존했다.

## 선택적 아이콘 메타데이터 (Local 0.3.0)

`notification`에 `app_id`(Android 패키지), `icon_key`(PNG SHA-256 hex), `icon_png`(PNG base64)가 추가된다. PNG는 최대 3,072바이트, 디코딩 크기는 최대 64×64다. 워치는 해시를 확인하고 기기 내 캐시에 저장한다. 아이콘 메타데이터는 내용 리비전에 포함하지 않는다.

휴대폰은 현재 연결에서 해당 아이콘을 보낸 메시지가 ACK되면 같은 `icon_key`의 `icon_png`를 생략한다. 재연결하면 첫 전송에 다시 포함한다. 일반 텍스트+아이콘이 크기 상한에 가까워지면 아이콘 본문을 생략해 알림 텍스트 전달을 우선한다. 기존 버전은 모르는 필드를 무시할 수 있으며 아이콘 필드가 없는 알림도 처리한다.

watchOS 로컬 알림은 카테고리 `FOLDBRIDGE_ALERT`와 원본 앱의 thread ID를 사용한다. long-look 콘텐츠는 캐시된 `fb_icon` 키로 원본 아이콘을 표시한다. 시스템 short-look/sash의 발송 앱 표시는 그대로다.
