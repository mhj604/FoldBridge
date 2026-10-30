#!/usr/bin/env python3
"""Windows workflow for the Galaxy and Apple Watch notification apps."""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'android'))
from build_android import Toolchain, find_sdk


def run(*command,**kwargs):
    return subprocess.run([str(x) for x in command],check=True,**kwargs)


def find_adb(sdk=None,windows=None):
    windows=os.name=='nt' if windows is None else windows
    name='adb.exe' if windows else 'adb'
    try:
        candidate=find_sdk(sdk)/'platform-tools'/name
        if candidate.is_file():return candidate
    except ValueError:
        if sdk:raise
    found=shutil.which(name)
    if found and not sdk:return Path(found)
    raise ValueError('ADB not found. Install Android SDK Platform-Tools and pass --sdk if needed.')


def select_device(output,serial=None):
    devices={}
    for line in output.splitlines():
        columns=line.split()
        if len(columns)>=2 and not line.startswith(('List of devices','*')):
            devices[columns[0]]=columns[1]
    if serial:
        if devices.get(serial)!='device':
            raise ValueError(f'Device {serial!r} is {devices.get(serial,"not found")}. Unlock the phone and approve its USB debugging prompt.')
        return serial
    if len(devices)!=1:
        raise ValueError('Connect exactly one phone, or pass --serial with its ID from adb devices -l.')
    serial,state=next(iter(devices.items()))
    if state!='device':raise ValueError(f'Device is {state}. Unlock the phone and approve USB debugging.')
    return serial


def connected_device(adb,serial):
    result=run(adb,'devices','-l',capture_output=True,text=True,encoding='utf-8',errors='replace')
    return select_device(result.stdout,serial)


def doctor(args):
    print('FoldBridge host:',platform.system(),platform.machine())
    print('Python:',platform.python_version())
    failed=False
    try:
        tools=Toolchain.resolve(args.sdk,args.java_home)
        run(sys.executable,ROOT/'android/build_android.py','--sdk',tools.sdk,'--java-home',tools.jdk,'--check')
    except (ValueError,subprocess.CalledProcessError) as error:
        print('Android build:',error);failed=True
    try:print('ADB:',find_adb(args.sdk))
    except ValueError as error:print('USB install:',error)
    apk=ROOT/'FoldBridge-debug.apk'
    if apk.is_file():
        actual=hashlib.sha256(apk.read_bytes()).hexdigest()
        expected=(ROOT/'SHA256SUMS').read_text(encoding='utf-8').split()[0]
        print('Packaged APK checksum:','OK' if actual==expected else 'MISMATCH')
        if actual!=expected:failed=True
    else:print('Packaged APK: missing');failed=True
    print('watchOS compilation and signing require a Mac with full Xcode.')
    if platform.system()!='Windows':print('This command is running outside Windows; it is not native Windows validation.')
    return 1 if failed else 0


def build(args):
    command=[sys.executable,ROOT/'android/build_android.py','--output',Path(args.apk or ROOT/'FoldBridge-Windows-debug.apk').resolve()]
    if args.sdk:command+=['--sdk',args.sdk]
    if args.java_home:command+=['--java-home',args.java_home]
    if args.build_dir:command+=['--build-dir',args.build_dir]
    run(*command)


def install(args):
    apk=Path(args.apk or ROOT/'FoldBridge-debug.apk').resolve()
    if not apk.is_file():raise ValueError(f'APK not found: {apk}')
    if apk==(ROOT/'FoldBridge-debug.apk').resolve():
        expected=(ROOT/'SHA256SUMS').read_text(encoding='utf-8').split()[0]
        if hashlib.sha256(apk.read_bytes()).hexdigest()!=expected:raise ValueError('Packaged APK checksum mismatch. Use the original package or pass a separately named APK.')
    adb=find_adb(args.sdk);serial=connected_device(adb,args.serial)
    try:run(adb,'-s',serial,'install','-r',apk)
    except subprocess.CalledProcessError:
        print('Installation failed. If signatures differ, use the original signing key. This tool does not uninstall the app or erase its pairing data.')
        raise
    print('Installed. Open FoldBridge on the phone and grant Nearby devices and notification access.')


def logs(args):
    adb=find_adb(args.sdk);serial=connected_device(adb,args.serial)
    result=run(adb,'-s',serial,'shell','pidof','-s','dev.foldbridge',capture_output=True,text=True)
    pid=result.stdout.strip()
    if not re.fullmatch(r'\d+',pid):raise ValueError('Open FoldBridge on the phone before collecting logs.')
    command=[adb,'-s',serial,'logcat','-d','--pid',pid,'-v','threadtime']
    if args.output:
        destination=Path(args.output).resolve();destination.parent.mkdir(parents=True,exist_ok=True)
        with destination.open('wb') as output:run(*command,stdout=output)
        print('Diagnostic log:',destination)
    else:run(*command)


def venv_python(folder):
    return folder/('Scripts/python.exe' if os.name=='nt' else 'bin/python')


def relay_setup(args):
    folder=ROOT/'relay/.venv'
    if not venv_python(folder).is_file():run(sys.executable,'-m','venv',folder)
    run(venv_python(folder),'-m','pip','install','-r',ROOT/'relay/requirements.txt')
    settings=Path(args.env_file or ROOT/'windows/.env').resolve()
    if not settings.exists():
        settings.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/'relay/.env.example',settings)
    print('Relay environment:',settings)
    print('Edit this file with your own APNs settings. An existing file is never overwritten.')


def read_env(path):
    values={}
    allowed={'RELAY_TOKEN','APNS_TEAM_ID','APNS_KEY_ID','APNS_TOPIC','APNS_KEY_FILE','APNS_ENVIRONMENT','RELAY_HOST','RELAY_PORT','RELAY_DOMAIN'}
    for number,line in enumerate(Path(path).read_text(encoding='utf-8-sig').splitlines(),1):
        line=line.strip()
        if not line or line.startswith('#'):continue
        key,separator,value=line.partition('=');key=key.strip();value=value.strip()
        if not separator or key not in allowed:raise ValueError(f'Invalid environment setting on line {number}.')
        if value.startswith(('"',"'")):
            if len(value)<2 or value[-1]!=value[0]:raise ValueError(f'Unclosed quote on line {number}.')
            value=value[1:-1]
        # Preserve Windows backslashes and dollar signs literally; never evaluate the file as code.
        values[key]=value
    return values


def relay_start(args):
    settings=Path(args.env_file or ROOT/'windows/.env').resolve()
    if not settings.is_file():raise ValueError('Relay environment file missing. Run RelaySetup, then edit windows/.env.')
    values=read_env(settings)
    required=['RELAY_TOKEN','APNS_TEAM_ID','APNS_KEY_ID','APNS_TOPIC','APNS_KEY_FILE']
    for key in required:
        value=values.get(key,'')
        if not value or value.startswith(('YOUR_','REPLACE_')):raise ValueError(f'Configure {key} in the environment file first.')
    key_file=Path(values['APNS_KEY_FILE']).expanduser()
    if not key_file.is_absolute():key_file=settings.parent/key_file
    if not key_file.is_file():raise ValueError('APNS_KEY_FILE does not identify an existing private key file.')
    values['APNS_KEY_FILE']=str(key_file.resolve())
    python=venv_python(ROOT/'relay/.venv')
    if not python.is_file():raise ValueError('Relay runtime missing. Run RelaySetup first.')
    child_environment=os.environ.copy();child_environment.update(values)
    run(python,ROOT/'relay/server.py',env=child_environment,cwd=ROOT/'relay')


def prepare_watch(args):
    destination=Path(args.output or ROOT/'FoldBridge-watch-for-Mac.zip').resolve()
    destination.parent.mkdir(parents=True,exist_ok=True)
    allowed={'.swift','.py','.plist','.entitlements','.yml','.pbxproj','.xcscheme'}
    excluded={'.build','build','DerivedData','xcuserdata','__pycache__'}
    with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED) as archive:
        for file in sorted((ROOT/'watch').rglob('*')):
            relative=file.relative_to(ROOT)
            if file.is_file() and file.suffix in allowed and not any(p in excluded for p in relative.parts):
                archive.write(file,Path('FoldBridge')/relative)
        archive.writestr('FoldBridge/README-MAC.txt','On the Mac with full Xcode, run: python3 watch/build_watch.py\nThen open watch/FoldBridge.xcodeproj, select your Team and the physical Watch, and press Run.\nWindows cannot compile or sign a native watchOS app.\n')
    print('Mac watch-source package:',destination)


def main(argv=None):
    parser=argparse.ArgumentParser(description='Windows build, install and relay tools for FoldBridge. watchOS still requires a Mac.')
    parser.add_argument('action',choices=['doctor','build','install','logs','relay-setup','relay-start','prepare-watch'])
    parser.add_argument('--sdk');parser.add_argument('--java-home');parser.add_argument('--serial')
    parser.add_argument('--apk');parser.add_argument('--output');parser.add_argument('--env-file')
    parser.add_argument('--build-dir')
    args=parser.parse_args(argv)
    if sys.version_info<(3,11):parser.error('Python 3.11 or newer is required.')
    try:return globals()[args.action.replace('-','_')](args) or 0
    except (ValueError,OSError,subprocess.CalledProcessError) as error:
        print('FoldBridge:',error,file=sys.stderr);return 1


if __name__=='__main__':raise SystemExit(main())
