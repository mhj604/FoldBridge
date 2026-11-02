# FoldBridge Local BLE 프로토콜

**한국어** · [English](PROTOCOL_EN.md) · [전체 문서](README.md)

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

암호화 envelope는 `{type:"sealed", seq:1, data:"base64(ciphertext || tag)"}`다. Local 실행 경로의 메시지는 `confirm`, `ready`, `state`, `sync`, `notification`, `ack`, `refresh`, `refreshed` (이전 버전 호환: `reconnect`, `ping`, `pong`)다. 기존 Push 지원 소스는 남아 있으나 Local은 APNs 토큰을 보내거나 서버를 사용하지 않는다.

## 알림과 수신 확인

`notification`에는 Android 알림 키의 해시 ID, 제목/본문의 해시 리비전, 앱 표시명, 제목, 본문, 게시 시각을 넣는다. 최초 양쪽 확인 전에는 전달하지 않는다.

미확인 목록은 현재 인증된 연결의 메모리에만 최대 24시간/1,024개 유지한다. 한 메시지씩 ACK를 기다리며 90초 간격으로 최대 3회 시도한다. ACK 지연만으로 BLE를 취소하지 않는다. 연결 해제·프로세스 재시작 때 대기열을 비우고, 매 인증 완료 시점을 새로운 게시 시각 기준으로 사용한다. 활성 알림 재수집도 그 시점 이전 항목을 제외하므로 밀린 알림을 재전송하지 않는다.

워치는 표시 권한을 확인한 뒤 로컬 알림을 등록하고 성공 시 ACK한다. 이미 기억하는 동일 리비전은 다시 표시하지 않고 ACK한다. ACK는 표시 요청 수락/기존 수신 기록 확인이며 화면 표시·진동·열람을 보장하지 않는다. 워치는 제목·본문이 담긴 별도 수신함을 저장하지 않는다. 중복 판별용 ID/리비전 해시 512개만 Keychain에 보관한다. 알림 내용은 watchOS 알림 센터에서 관리한다.

충전 상태 필터는 Android의 수집 단계에 적용하므로 wire 형식 변경이 없다. 앱 내부의 `state`/`sync` 메시지는 사용자에게 알림을 만드는 메시지가 아니다.

## 실행 한계

이 프로토콜은 OS 실행 예산을 늘리지 않는다. 위치 기반 연결 유지에서도 watchOS의 중단/종료나 Bluetooth 범위 이탈로 지연될 수 있다. 정적 ECDH 신원 키를 사용하므로 신원 키 유출 이후의 전방향 안전성을 주장하지 않는다. 초기 APNs 설계는 `legacy/docs/PROTOCOL-0.1.0.md`에 별도 보존했다.

## 선택적 아이콘 메타데이터 (Local 0.3.0)

`notification`에 `app_id`(Android 패키지), `icon_key`(PNG SHA-256 hex), `icon_png`(PNG base64)가 추가된다. PNG는 최대 3,072바이트, 디코딩 크기는 최대 64×64다. 워치는 해시를 확인하고 기기 내 캐시에 저장한다. 아이콘 메타데이터는 내용 리비전에 포함하지 않는다.

휴대폰은 현재 연결에서 해당 아이콘을 보낸 메시지가 ACK되면 같은 `icon_key`의 `icon_png`를 생략한다. 재연결하면 첫 전송에 다시 포함한다. 일반 텍스트+아이콘이 크기 상한에 가까워지면 아이콘 본문을 생략해 알림 텍스트 전달을 우선한다. 기존 버전은 모르는 필드를 무시할 수 있으며 아이콘 필드가 없는 알림도 처리한다.

watchOS 0.4.3은 캐시된 원본 아이콘이 있는 알림에 `FOLDBRIDGE_COMPACT_ICON_ALERT` 카테고리를 사용한다. 이 카테고리의 long-look 본문만 고정 폭 SwiftUI 화면으로 표시하며 원본 아이콘은 24pt다. 아이콘이 없으면 `FOLDBRIDGE_NATIVE_ALERT` 카테고리의 시스템 텍스트 화면을 사용한다. 두 경로 모두 원본 앱 thread ID와 기존 ACK/중복 판별을 유지한다.

이미지 첨부를 생성하지 않으므로 아이콘을 시스템 미디어 미리보기나 카드 썸네일로 사용하지 않는다. 팝업/카드/상단 sash의 시스템 발송 앱 표시는 FoldBridge다. 이전 버전 알림의 카테고리와 시스템에 저장된 첨부를 강제로 변경하거나 재등록하지 않는다.


## 과거 동작: Android 0.5.1 / Watch 0.4.6

아래 방식은 0.4.7/0.5.2에서 대체했다. 특히 주기적 ping과 짧은 시간 초과 취소는 현재 사용하지 않는다.

- 폰에서 새로고침을 누르면 인증된 세션에 `reconnect`를 보낸다. 워치는 저장된 상대 키를 유지하고 연결 취소 → 검색 → 새 nonce로 인증을 진행한다. 폰은 GATT 서비스와 특성 객체를 유지해 워치 캐시의 무효화를 줄인다. 요청 후 1.5초간 같은 세션이 남으면 폰도 해당 연결을 취소한다. 이전 세션용 예약 작업은 generation이 바뀌면 무시한다.
- 워치에서 새로고침을 누르면 기존 연결을 취소하고, 폰의 실행 중인 peripheral 서비스로 재접속한다. 폰 버튼을 누를 필요는 없다.
- 폰의 `ready`에 `liveness:1`을 넣어 응답 확인을 지원함을 알린다. 이를 받은 워치만 암호화된 `ping`을 보내며, 폰은 같은 `nonce`의 `pong`으로 응답한다. 이전 폰 버전에는 이 기능을 적용하지 않는다.
- 워치가 실행 중이거나 연결 유지 실행 기회를 받는 동안 5초 주기로 상태를 살핀다. 인증된 메시지가 15초 이상 없으면 ping을 보내고, ping 이후 수신 조각도 없이 20초 이상 멈추면 재연결한다. 조각이 계속 들어오는 큰 알림은 중간에 끊지 않는다. 등록된 기기의 연결·서비스 검색·인증이 20초 이상 멈춘 경우도 재시도한다. 최초 코드 등록의 120초 대기는 유지한다.
- 서비스 변경은 Core Bluetooth의 `didModifyServices`로 처리한다. 모든 새 연결은 기존 고정 공개 키 확인과 새 세션 키 파생을 그대로 수행한다.
- 제어 메시지는 watchOS 알림을 생성하지 않는다. 강제 종료·Bluetooth 꺼짐·범위 이탈·OS의 실행 중단을 해제하는 프로토콜은 아니다.

서비스 무효화 처리는 [Apple CBPeripheralDelegate](https://developer.apple.com/documentation/corebluetooth/cbperipheraldelegate/peripheral(_:didmodifyservices:))를 따른다. 연결 취소는 [Android BluetoothGattServer](https://developer.android.com/reference/android/bluetooth/BluetoothGattServer#cancelConnection(android.bluetooth.BluetoothDevice)) API를 사용한다.


## 이전 페어링·복원 (Android 0.5.3 / Watch 0.4.8)

- 최초 신규 등록이 완료되는 순간 Android는 기존 대기열을 비우고 암호화 저장소에 게시 시각 cutoff를 저장한다. `NotificationRelay`는 실제 `StatusBarNotification.postTime`을 사용하며, 재시작 뒤 활성 알림 replay도 cutoff 이전 알림을 제외한다. 이미 고정된 상대가 재연결할 때는 대기열을 유지한다.
- 저장된 상대 연결에는 watchOS 10+의 `CBConnectPeripheralOptionEnableAutoReconnect`를 사용한다. OS가 자동 연결을 진행 중이라고 알리면 워치는 같은 `CBPeripheral`을 유지하고, 다시 연결되면 GATT 특성을 검색하고 새 nonce로 인증한다. Android GATT 광고는 연결 해제 뒤에도 계속 유지한다. 이 동작은 자동 재연결을 요청하지만 Bluetooth 범위·간섭·전원·OS 스케줄링에 따른 끊김이나 지연을 없애지는 않는다.

## 이전 갱신·복원 (Android 0.5.2 / Watch 0.4.7)

- 정상 연결에서 한쪽 새로고침은 암호화된 `refresh`를 보낸다. 폰은 `refreshed`로 응답하고 워치는 `state`/`sync`로 응답한다. 연결·세션·등록 키를 보존한다.
- 자동 ping을 생성하지 않으며 `ready.liveness`는 0이다. 워치가 백그라운드에서 실행되지 않은 시간을 통신 오류로 간주해 연결을 취소하지 않는다. 전면 유지보수는 15초 주기이고 전면 복구 시간 여유를 따로 둔다.
- Core Bluetooth가 보존한 연결은 서비스/특성을 복원하고 CCC를 명시적으로 다시 설정한다. 프로세스가 사라졌다면 새 nonce와 저장된 상대 공개 키로 같은 BLE 연결에서 다시 인증한다. 인증된 상태에서 서비스 무효화가 오면 다른 Android 시스템 서비스의 변경일 수 있으므로 세션을 보존한 채 특성/구독만 다시 구성한다. 실제 프로세스 복원은 새 nonce 인증을 수행한다.
- 저장된 상대의 pending connect는 백그라운드에서 유지한다. 연속 물리 끊김에는 앱 재시도 간격을 최대 30초로 늘려 반복 접속을 줄이고 인증 성공 시 초기화한다. 재검색은 캐시가 없거나 전면에서 연결 대기가 길어진 경우에 사용한다.
- 폰의 암호화 상태가 사라졌지만 구독이 남은 경우 평문 `wake`/v1은 새 인증만 요청한다. 어떤 알림도 이 메시지만으로 허용하지 않는다. 등록된 워치의 인증 대기만으로 물리 연결을 120초 뒤 취소하지 않는다. 미등록 상대의 코드 등록 시간 제한은 유지한다.
- 같은 링크의 재인증 때 이전 ATT indication/write 응답은 기존 전송 슬롯만 해제하며 새 세션 첫 조각을 제거하지 않는다. 폰은 실제 수신된 정상 ATT write 길이로 MTU 하한도 복구한다.
- 앱 ACK 지연은 미전달 대기로 남긴다. Bluetooth 전송 실패와 앱 표시 확인 지연을 구분한다. 수동 갱신/동기화 때 대기 항목을 재시도한다.
- 진단에는 프로세스 식별용 임의 값, 연결 단계·카운터·오류 코드만 기록한다. 알림 본문·개인 키·위치 좌표는 기록하지 않는다.

BLE 특성 변경으로 백그라운드 실행 기회를 받는 것은 watchOS가 제어한다. 이 프로토콜은 강제 실행 API나 실행 예산 우회가 아니다. [Apple 백그라운드 작업](https://developer.apple.com/documentation/watchkit/using-background-tasks)

## 현재 연결·전달 (Android 0.5.4 / Watch 0.4.9)

- 최초 등록과 모든 재연결에서 인증 완료 시각을 새 cutoff로 사용한다. 연결 전·중단 중 알림을 수집/복원하지 않고 이전 디스크 outbox를 제거한다. 워치도 이전 세션의 미표시 알림과 지연 표시 콜백을 새 세션으로 넘기지 않는다.
- Android는 연결 후 광고를 멈추고 끊김 후 같은 GATT 서버에서 다시 시작한다. 광고 실패는 별도로 재시도하며 정상 링크를 닫지 않는다.
- watchOS 자동 재연결과 서비스 필터 검색을 함께 유지한다. 복구 검색은 전면 상태나 20초 타이머로 중단하지 않는다. 백그라운드 끊김 콜백에서는 앱 타이머를 기다리지 않고 OS에 저장된 상대 연결을 요청한다.
- 정상 연결의 새로고침은 세션을 유지한다. 물리 단절·전원·OS 실행 제한을 제거하거나 즉시 복구를 보장하지는 않는다.

## 차량 제어 (Android 0.6.0 / Watch 0.5.0)

기존 인증 완료 후 같은 암호화 채널만 사용합니다.

| 메시지 | 방향 | 필드 |
| --- | --- | --- |
| `vehicle_list` | 워치 → 폰 | `type` |
| `vehicle_catalogue` | 폰 → 워치 | `status`, `revision`, `actions:[{id,label}]` |
| `vehicle_command` | 워치 → 폰 | UUID `id`, `revision`, `action` |
| `vehicle_result` | 폰 → 워치 | 요청 `id`, `status` |

목록은 최대 12개이며 사용자가 선택한 공식 위젯의 이름 있는 버튼만 제공합니다. 폰은 활성 상태·현재 리비전·선택 여부를 확인하고 요청 ID를 저장한 뒤 위젯을 한 번 호출합니다. 최근 64개 ID를 중복 억제에 사용합니다. 실행 간격은 최소 3초입니다. `widget_invoked`는 위젯 호출이며 차량 성공을 뜻하지 않습니다. `duplicate`, `invalid`, `not_ready`, `stale`, `busy`, `unavailable`은 실행/전달 상태입니다. 워치는 30초 후 응답 미확인을 표시하지만 자동 재전송하지 않습니다. 재연결은 대기 차량 명령을 복원하지 않습니다.

### 결과 안내 자동 복구 (Android 0.6.3 / Watch 0.5.6)

`vehicle_catalogue.status`는 `loading`, `busy`, `auth_required`, `result_pending`, `no_controls`를 구분합니다. `result_pending`은 공식 위젯 결과 화면의 유일한 확인/닫기 버튼이 있는 경우입니다. 제어 탭을 처리하는 워치는 `vehicle_command` 형식에서 `action:"dismiss_notice"`와 현재 `revision`, 새 UUID를 전달합니다. 갤럭시는 안내 확인을 한 번 호출하고 `notice_dismissed`를 반환합니다. 워치는 이 응답과 복구된 최신 목록을 모두 받은 뒤 현재 탭에 대응하는 차량 명령을 새 UUID로 한 번 전달합니다. 이 준비는 원래 탭의 15초 이내로 제한되고 화면 종료 시 취소됩니다. 이전 차량 요청 ID를 재전송하지 않습니다.

### 버튼 식별자 유지 (Android 0.6.2 / Watch 0.5.4)

액션 ID는 `SHA256(widgetID + ":label:" + 정확한 표시 이름)`의 URL-safe Base64 값입니다. 같은 이름의 클릭 대상이 여러 개면 해당 항목을 목록에서 제외합니다. View ID나 화면 순서를 영속 식별자로 사용하지 않습니다. 최신 revision과 현재 선택 여부는 실행 시 계속 확인합니다.
