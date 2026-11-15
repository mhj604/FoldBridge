# 워치 인터넷만의 무료 갱신 — 2026-11-15 추가 조사

[English](WATCH_ONLY_RENEWAL_2026-11-15_EN.md)

최우선 조건은 **기존 앱·등록 유지, 무료, 자동, Mac·아이폰 없이 워치 인터넷만 사용**입니다. 이번에는 Exa에서 다섯 검색 관점의 26개 결과를 읽고 관련 원문을 추가로 열었습니다. 아래는 결과 수가 아니라 서로 다른 후보의 요약입니다. 이 조건을 모두 충족하는 적용 가능한 구현은 확보하지 못했습니다.

| 후보 | 실제 범위와 남는 문제 |
| --- | --- |
| [SideStore](https://github.com/SideStore/SideStore) | iOS 앱이며 LocalDevVPN과 장치 내부 서비스 연결을 사용합니다. native watchOS 대상이 아닙니다. |
| [SideInstaller](https://github.com/FrizzleM/SideInstaller/blob/main/NOTES.md) | 같은 로컬 VPN·RPPairing 경로를 구현한 iOS 프로젝트입니다. 워치 지원의 근거는 아닙니다. |
| [WatchBridge](https://github.com/AdminZachary/WatchBridge) | Windows/macOS 프로그램입니다. 준비에 페어링된 아이폰을 요구하고, 문서에서 Watch-only 패키지를 제외합니다. 컴퓨터 없는 워치 단독 경로가 아닙니다. |
| [iLoader 자동 갱신](https://github.com/AndreySemjonov/iloader/blob/main/docs/automatic-renewal.md) | 해당 분기의 문서는 자동 Watch 갱신을 지원하지 않는다고 명시합니다. 다른 분기의 설치 지원과 혼동하지 않습니다. |
| [JAS](https://github.com/jkcoxson/jas) | 서버에서 iOS 앱을 갱신합니다. Mac을 대신할 서버는 될 수 있지만 워치 단독 구현이 아니며, 이 워치에 대한 적용 결과도 없습니다. |
| [iOS Signer Service FAQ](https://github.com/oh-me/ios-signer-service/blob/master/FAQ.md) | 클라우드 서명 기능과 별개로 무료 계정의 OTA 설치를 지원하지 않는다고 설명합니다. 웹 다운로드만 추가해서는 이 목표가 해결되지 않습니다. |
| [idevice](https://github.com/jkcoxson/idevice/) | RSD·장치 프로파일 관리 등의 구성 요소입니다. 라이브러리 기능 목록 자체가 워치 앱 안에서 자동 갱신을 완료했다는 근거는 아닙니다. |

설치된 Xcode의 watchOS SDK에서 [NEPacketTunnelProvider](https://developer.apple.com/documentation/networkextension/nepackettunnelprovider)는 `API_UNAVAILABLE(watchos)`로 선언돼 있습니다. 따라서 SideStore의 로컬 VPN 확장 구조를 같은 API로 워치에 그대로 옮길 수 없습니다. **새 프로파일을 발급받는 것**과 **워치의 설치 서비스에 적용하는 것**은 별도 단계이며, 후자의 워치 단독 경로가 아직 없습니다. 이 결론은 조사한 경로의 현재 제한이며 모든 미래 구현이 불가능하다는 증명은 아닙니다.

개발 후보는 Galaxy/Linux 같은 외부 호스트로 서명·RSD 설치를 옮기는 것입니다. 그러나 이는 ‘워치 인터넷만’ 조건과 다르고, 이 저장소에 동작한다고 가장하는 갱신 코드를 추가하지 않았습니다. 기존 주간 Mac 예약을 워치 단독 갱신이라고 설명하지 않습니다.
