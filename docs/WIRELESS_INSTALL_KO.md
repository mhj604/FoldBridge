# 갤럭시 앱을 케이블 없이 업데이트하기

**한국어** · [English](WIRELESS_INSTALL_EN.md) · [전체 문서](README.md)

일상적인 알림 전달은 Galaxy–Watch Bluetooth를 사용한다. 아래 Wi-Fi 연결은 Mac에서 갤럭시 APK를 설치하거나 앱 상태를 읽을 때만 사용한다.

## APK를 직접 설치하는 방법

갤럭시에서 [최신 릴리스](https://github.com/mhj604/FoldBridge/releases/latest)의 APK를 내려받고 **내 파일 → 다운로드**에서 연다. 기존 FoldBridge Local 위에 업데이트한다. Mac 연결이나 개발자 옵션은 필요하지 않다. 기존 설치와 서명 키가 같은 APK를 사용한다.

## Mac에서 무선으로 설치하는 방법

Android 11 이상에서는 USB 없이 ADB 페어링과 설치가 가능하다. Mac과 갤럭시를 같은 Wi-Fi에 연결하고 최신 Android SDK Platform Tools를 준비한다.

처음 한 번:

1. 갤럭시 **설정 → 개발자 옵션 → 무선 디버깅**을 켠다.
2. **페어링 코드로 기기 페어링**을 열고, 그 화면의 IP:포트로 연결한다.

   ```sh
   adb pair PHONE_IP:PAIRING_PORT
   ```

3. 요청이 나오면 화면의 일회용 6자리 코드를 입력한다.
4. 페어링 화면을 닫고 **무선 디버깅 기본 화면**의 IP:포트를 사용한다. 연결용 포트는 페어링용 포트와 다를 수 있다.

   ```sh
   adb connect PHONE_IP:CONNECT_PORT
   adb -s PHONE_IP:CONNECT_PORT install -r /absolute/path/to/FoldBridge-Local-0.5.4.apk
   ```

## 다음 업데이트

같은 Wi-Fi에서 무선 디버깅을 켠다. 자동 연결이 되지 않으면 기본 화면의 현재 IP:포트로 `adb connect`를 실행한다. 주소나 포트가 바뀌어도 Mac 등록이 유지돼 있으면 페어링 코드를 다시 입력하지 않는다. 이 방법에는 USB가 필요하지 않다.

재부팅이나 네트워크 변경 후 무선 디버깅을 다시 켜야 할 수 있다. `adb mdns services`가 비어 있어도 현재 IP:연결포트를 직접 지정할 수 있다. Mac의 등록을 삭제하거나 디버깅 승인을 취소했다면 처음 페어링 절차를 반복한다.

`install -r`은 기존 앱의 데이터를 유지하는 업데이트다. 서명 불일치 오류가 나면 기존 서명 키로 만든 APK를 사용한다. 연결을 복구하려고 앱을 삭제하면 저장된 워치 등록도 사라진다.

이 Mac 개발용 등록은 FoldBridge 내부의 Galaxy–Watch 코드 확인과 별개다. 공개 안내나 이슈에 자신의 페어링 코드와 ADB 키를 올리지 않는다.

[Android 공식 무선 ADB 안내](https://developer.android.com/tools/adb#connect-to-a-device-over-wi-fi)
