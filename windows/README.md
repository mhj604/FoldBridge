# Windows에서 FoldBridge 진행하기

Windows 10과 11에서 갤럭시 앱 빌드, APK 설치, 진단 로그 수집, APNs 중계 서버 실행을 진행하기 위한 도구입니다. 휴대폰과 워치에서 실행하는 앱은 기존 FoldBridge와 같습니다. Windows PC를 알림 중계의 필수 장치로 추가하지 않습니다.

**watchOS 앱의 네이티브 컴파일과 서명은 여전히 Mac의 Xcode가 필요합니다.** Windows용 Swift를 설치하는 것으로 watchOS SDK가 생기지는 않습니다. Windows에서 워치 프로젝트를 준비한 뒤 보유한 Mac으로 옮길 수 있습니다.

현재 실행 환경은 Linux입니다. Windows 실행 파일 선택, 공백이 있는 경로, PowerShell 구문과 명령 전달을 검사하고 공통 빌드 경로를 실행합니다. Windows 네이티브 실행과 실제 기기 연결은 별도 확인이 필요합니다. 구체적인 검사 결과는 최상위 `VERIFICATION.json`을 확인하세요.

## 준비

압축을 풀고 `FoldBridge` 폴더에서 PowerShell을 엽니다.

| 작업 | 필요한 도구 |
| --- | --- |
| 포함된 APK를 갤럭시에 설치 | Python 3.11 이상, Android SDK Platform-Tools |
| Android 앱을 직접 빌드 | 위 도구와 JDK 17 이상, SDK Platform 36, Build Tools 36.0.0 |
| 중계 서버 실행 | Python 3.11 이상, 본인 APNs 설정과 HTTPS 주소 |
| 워치 앱 설치 | 기존 아이폰으로 설정된 워치, 전체 Xcode가 설치된 Mac |

Python은 [공식 Windows 설치 파일](https://www.python.org/downloads/windows/)을 사용할 수 있습니다. SDK는 [Android Studio](https://developer.android.com/studio)에서 준비하고 SDK Manager에서 Platform 36, Build Tools 36.0.0과 Platform-Tools를 선택합니다. Android Studio에 포함된 JDK도 컴파일러가 있으면 사용할 수 있습니다.

PowerShell 실행 정책 때문에 스크립트가 차단되면 다음처럼 해당 프로세스에서 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\FoldBridge.ps1 Doctor
```

이후 예시는 스크립트를 실행할 수 있는 PowerShell에서의 명령입니다. 같은 방법으로 `-File` 뒤에 다른 명령을 전달해도 됩니다. 관리자 권한이나 전역 실행 정책 변경을 요구하지 않습니다.

## 환경 확인

```powershell
.\windows\FoldBridge.ps1 Doctor
```

SDK는 `ANDROID_HOME`, `ANDROID_SDK_ROOT`, 기본 Android Studio SDK 경로 순서로 찾습니다. Windows의 일반적인 기본 위치는 `%LOCALAPPDATA%\Android\Sdk`입니다. JDK는 `JAVA_HOME`, PATH의 `javac`, Android Studio의 `jbr` 순서로 찾습니다.

경로를 직접 지정할 수도 있습니다.

```powershell
.\windows\FoldBridge.ps1 Doctor -SdkRoot "C:\Users\사용자\AppData\Local\Android\Sdk" -JavaHome "C:\Program Files\Android\Android Studio\jbr"
```

`Doctor`의 Android 빌드 도구 오류가 있더라도, Platform-Tools와 Python이 있다면 포함된 APK 설치는 별도로 진행할 수 있습니다.

## 갤럭시에 APK 설치

갤럭시에서 개발자 옵션의 USB 디버깅을 켜고 USB 케이블로 연결합니다. 휴대폰 잠금을 풀고 PC의 디버깅 키를 승인합니다.

```powershell
.\windows\FoldBridge.ps1 Install
```

연결된 기기가 여러 대라면 정확한 ADB serial을 지정합니다. 승인되지 않은 기기나 여러 기기 중 하나를 임의로 선택하지 않습니다.

```powershell
.\windows\FoldBridge.ps1 Install -Serial "휴대폰_ADB_SERIAL"
```

설치 후 갤럭시에서 FoldBridge를 열고 근처 기기 권한, 알림 접근과 전달할 앱을 설정합니다. 워치 연결은 기존 안내대로 양쪽 FoldBridge 앱에서 진행합니다. 갤럭시의 일반 블루투스 설정에서 워치를 먼저 연결하지 않습니다.

## Windows에서 직접 빌드

```powershell
.\windows\FoldBridge.ps1 Build
```

결과는 최상위 폴더의 `FoldBridge-Windows-debug.apk`입니다. 이 APK를 설치하려면 파일을 명시합니다.

```powershell
.\windows\FoldBridge.ps1 Install -Apk .\FoldBridge-Windows-debug.apk
```

Windows SDK의 `aapt2.exe`와 `zipalign.exe`를 사용하며 D8과 apksigner는 Java JAR로 직접 실행합니다. 공백이 있는 SDK와 JDK 경로도 인수 배열로 전달하며 `.bat` 파일이나 `cmd.exe`를 거치지 않습니다.

직접 빌드할 때 생성되는 `android\.build\debug.keystore`를 보관하세요. Mac에서 빌드한 APK나 포함된 개발용 APK와 서명이 다르면 덮어쓰기 설치가 거부될 수 있습니다. 도구가 앱을 자동 삭제하거나 워치 등록 데이터를 지우지 않습니다.

## 진단 로그

갤럭시에서 FoldBridge를 실행한 상태로 다음 명령을 사용합니다.

```powershell
.\windows\FoldBridge.ps1 Logs -Output .\foldbridge-log.txt
```

현재 FoldBridge 프로세스의 Android 로그 스냅샷을 저장합니다. 워치 수신 지연은 휴대폰 앱의 전달 확인 수치와 실제 워치 표시를 별도로 확인해야 합니다.

## Windows에서 중계 서버 실행

```powershell
.\windows\FoldBridge.ps1 RelaySetup
notepad .\windows\.env
```

기존 설정 파일은 덮어쓰지 않습니다. `.env`에 Team ID, Key ID, 워치 Bundle Identifier, 서버 접근 토큰, `.p8` 키 경로를 입력합니다. Windows 키 경로는 다음과 같이 입력할 수 있습니다.

```text
APNS_KEY_FILE=C:\Private Keys\AuthKey.p8
```

이 파일을 PowerShell 코드로 실행하지 않습니다. 경로의 역슬래시나 `$` 문자를 그대로 읽습니다. 키와 토큰을 문서나 압축 파일에 넣지 마세요.

```powershell
.\windows\FoldBridge.ps1 RelayStart
```

서버는 기본적으로 `127.0.0.1:8787`에서 실행됩니다. 휴대폰이 접속할 유효한 HTTPS 주소는 별도로 준비해야 합니다. 포함된 `relay\Caddyfile`을 사용할 수 있습니다. Windows 방화벽이나 공유기 설정은 자동으로 변경하지 않습니다. 자세한 APNs 설정은 최상위 README의 Push 설정을 따릅니다.

## 워치 소스를 Mac으로 넘기기

```powershell
.\windows\FoldBridge.ps1 PrepareWatch
```

생성된 `FoldBridge-watch-for-Mac.zip`을 Mac으로 옮기고 압축을 풉니다. 해당 패키지의 `FoldBridge` 폴더에서:

```sh
python3 watch/build_watch.py
```

그다음 Xcode 프로젝트를 열고 Team과 실제 애플워치를 선택해 설치합니다. 내보내기에는 빌드 결과, 개인 키와 Xcode 사용자 설정이 포함되지 않습니다.

## PowerShell 없이 실행

동일한 작업을 Python으로 직접 실행할 수도 있습니다.

```powershell
py -3 .\windows\foldbridge_windows.py doctor
py -3 .\windows\foldbridge_windows.py build
py -3 .\windows\foldbridge_windows.py install
py -3 .\windows\foldbridge_windows.py prepare-watch
```

PowerShell 래퍼에는 `-Python "C:\Python312\python.exe"`처럼 Python 경로를 직접 지정할 수 있습니다.

## 근거

- [Android SDK 기본 경로](https://developer.android.com/studio/intro/studio-config)
- [D8](https://developer.android.com/tools/d8)
- [apksigner](https://developer.android.com/tools/apksigner)
- [PowerShell의 네이티브 명령 인수 처리](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing)
- [Xcode와 macOS 요구 사항](https://developer.apple.com/xcode/system-requirements)
