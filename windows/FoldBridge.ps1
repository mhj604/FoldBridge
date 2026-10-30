#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('Help','Doctor','Build','Install','Logs','RelaySetup','RelayStart','PrepareWatch')]
    [string]$Action='Help',
    [string]$SdkRoot,
    [string]$JavaHome,
    [string]$Serial,
    [string]$Apk,
    [string]$Output,
    [string]$EnvFile,
    [string]$BuildDir,
    [string]$Python
)
$ErrorActionPreference='Stop'
if ($Action -eq 'Help') {
    Write-Output 'FoldBridge Windows tools (PowerShell 5.1 or newer, Python 3.11 or newer)'
    Write-Output '.\windows\FoldBridge.ps1 Doctor'
    Write-Output '.\windows\FoldBridge.ps1 Build -SdkRoot "C:\Users\you\AppData\Local\Android\Sdk"'
    Write-Output '.\windows\FoldBridge.ps1 Install'
    Write-Output '.\windows\FoldBridge.ps1 Logs -Output ".\foldbridge-log.txt"'
    Write-Output '.\windows\FoldBridge.ps1 RelaySetup'
    Write-Output '.\windows\FoldBridge.ps1 RelayStart'
    Write-Output '.\windows\FoldBridge.ps1 PrepareWatch'
    Write-Output 'Native watchOS compilation and signing require a Mac with full Xcode.'
    return
}
$prefix=@()
if ($Python) {
    $launcher=$Python
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $launcher=(Get-Command py).Source
    $prefix=@('-3')
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $launcher=(Get-Command python).Source
} else {
    throw 'Install Python 3.11 or newer, or pass -Python with the full python.exe path.'
}
$commands=@{Doctor='doctor';Build='build';Install='install';Logs='logs';RelaySetup='relay-setup';RelayStart='relay-start';PrepareWatch='prepare-watch'}
$cli=Join-Path $PSScriptRoot 'foldbridge_windows.py'
$invokeArgs=$prefix+@($cli,$commands[$Action])
if ($SdkRoot) {$invokeArgs+=@('--sdk',$SdkRoot)}
if ($JavaHome) {$invokeArgs+=@('--java-home',$JavaHome)}
if ($Serial) {$invokeArgs+=@('--serial',$Serial)}
if ($Apk) {$invokeArgs+=@('--apk',$Apk)}
if ($Output) {$invokeArgs+=@('--output',$Output)}
if ($EnvFile) {$invokeArgs+=@('--env-file',$EnvFile)}
if ($BuildDir) {$invokeArgs+=@('--build-dir',$BuildDir)}
& $launcher @invokeArgs
if ($LASTEXITCODE -ne 0) {exit $LASTEXITCODE}
