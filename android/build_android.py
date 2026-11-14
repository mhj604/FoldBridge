#!/usr/bin/env python3
"""Build with an installed Android SDK on Windows, macOS, or Linux."""
import argparse
from dataclasses import dataclass
import os
from pathlib import Path
import shutil
import subprocess
import zipfile
import xml.etree.ElementTree as ET

def run(*args):
    subprocess.run([str(x) for x in args], check=True)

def find_sdk(explicit=None):
    value=explicit or os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    if value:return Path(value).expanduser().resolve()
    local=os.environ.get('LOCALAPPDATA')
    candidates=([Path(local)/'Android'/'Sdk'] if local else [])+[Path.home()/'Library'/'Android'/'sdk',Path.home()/'Android'/'Sdk']
    for candidate in candidates:
        if candidate.is_dir():return candidate.resolve()
    raise ValueError('Android SDK not found. Set ANDROID_HOME or pass --sdk.')

def find_jdk(explicit=None,windows=None):
    windows=os.name=='nt' if windows is None else windows
    value=explicit or os.environ.get('JAVA_HOME')
    if value:return Path(value).expanduser().resolve()
    compiler=shutil.which('javac.exe' if windows else 'javac')
    if compiler:return Path(compiler).resolve().parent.parent
    program_files=os.environ.get('ProgramFiles')
    bundled=Path(program_files)/'Android'/'Android Studio'/'jbr' if program_files else None
    if windows and bundled and (bundled/'bin'/'javac.exe').is_file():return bundled.resolve()
    raise ValueError('JDK 17 or newer not found. Set JAVA_HOME or pass --java-home; a JRE is not enough.')

@dataclass(frozen=True)
class Toolchain:
    sdk: Path
    jdk: Path
    jar: Path
    aapt2: Path
    zipalign: Path
    java: Path
    javac: Path
    keytool: Path
    d8: Path
    signer: Path

    @classmethod
    def resolve(cls,sdk=None,jdk=None,windows=None):
        windows=os.name=='nt' if windows is None else windows
        sdk=find_sdk(sdk);jdk=find_jdk(jdk,windows);suffix='.exe' if windows else ''
        tools=sdk/'build-tools'/'36.0.0'
        result=cls(sdk,jdk,sdk/'platforms'/'android-36'/'android.jar',tools/('aapt2'+suffix),tools/('zipalign'+suffix),jdk/'bin'/('java'+suffix),jdk/'bin'/('javac'+suffix),jdk/'bin'/('keytool'+suffix),tools/'lib'/'d8.jar',tools/'lib'/'apksigner.jar')
        missing=[str(p) for name,p in vars(result).items() if name not in {'sdk','jdk'} and not p.is_file()]
        if missing:raise ValueError('Missing build tools. Install SDK Platform 36, Build Tools 36.0.0, and a full JDK:\n'+'\n'.join(missing))
        return result

    def dex_command(self,*args):return [self.java,'-Dfile.encoding=UTF-8','-cp',self.d8,'com.android.tools.r8.D8',*args]
    def signer_command(self,*args):return [self.java,'-Dfile.encoding=UTF-8','-jar',self.signer,*args]

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--sdk', default=os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT'))
    parser.add_argument('--output', default='FoldBridge-Local.apk')
    parser.add_argument('--application-id',default='dev.foldbridge.local')
    parser.add_argument('--keystore',help='Reuse the local signing key for future updates')
    parser.add_argument('--skip-signature-check',action='store_true')
    parser.add_argument('--build-dir',help='Optional directory for intermediate files and the local debug signing key')
    parser.add_argument('--java-home',help='JDK root directory, including paths with spaces')
    parser.add_argument('--check',action='store_true',help='Check SDK/JDK availability without changing build files')
    args=parser.parse_args()
    try:tools=Toolchain.resolve(args.sdk,args.java_home)
    except ValueError as error:parser.error(str(error))
    compiler=subprocess.run([str(tools.javac),'-version'],capture_output=True,text=True,encoding='utf-8',errors='replace',check=True)
    import re
    version=re.search(r'javac (\d+)',compiler.stdout+compiler.stderr)
    if not version or int(version.group(1))<17:parser.error('JDK 17 or newer is required.')
    if args.check:
        print('SDK:',tools.sdk);print('JDK:',tools.jdk);print((compiler.stdout+compiler.stderr).strip());return
    root=Path(__file__).resolve().parent;jar=tools.jar
    work=Path(args.build_dir).resolve() if args.build_dir else root/'.build'; work.mkdir(parents=True,exist_ok=True)
    for name in ['generated','classes','dex']:
        target=work/name
        if target.exists(): shutil.rmtree(target)
        target.mkdir()
    ET.register_namespace('android','http://schemas.android.com/apk/res/android')
    manifest=ET.parse(root/'app/src/main/AndroidManifest.xml');manifest.getroot().set('package',args.application_id)
    android_name='{http://schemas.android.com/apk/res/android}name'
    for element in manifest.getroot().findall('./application/*'):
        name=element.get(android_name,'')
        if name.startswith('.'):element.set(android_name,'dev.foldbridge'+name)
    manifest.write(work/'AndroidManifest.xml',encoding='utf-8',xml_declaration=True)
    run(tools.aapt2,'compile','--dir',root/'app/src/main/res','-o',work/'compiled-res.zip')
    run(tools.aapt2,'link','-I',jar,'--manifest',work/'AndroidManifest.xml','--java',work/'generated','--min-sdk-version','33','--target-sdk-version','36','--version-code','30','--version-name','0.6.12-local','-o',work/'base.apk',work/'compiled-res.zip')
    sources=sorted((root/'app/src/main/java').rglob('*.java'))+sorted((work/'generated').rglob('*.java'))
    run(tools.javac,'-encoding','UTF-8','--release','17','-classpath',jar,'-d',work/'classes',*sources)
    run(*tools.dex_command('--lib',jar,'--min-api','33','--output',work/'dex',*sorted((work/'classes').rglob('*.class'))))
    with zipfile.ZipFile(work/'base.apk','a',compression=zipfile.ZIP_DEFLATED) as archive:
        for dex in sorted((work/'dex').glob('*.dex')): archive.write(dex,dex.name)
    run(tools.zipalign,'-f','4',work/'base.apk',work/'aligned.apk')
    key=Path(args.keystore).expanduser().resolve() if args.keystore else work/'debug.keystore'
    if not key.exists():
        run(tools.keytool,'-genkeypair','-keystore',key,'-storepass','android','-keypass','android','-alias','androiddebugkey','-keyalg','RSA','-keysize','2048','-validity','3650','-dname','CN=FoldBridge Local Debug,O=Local,C=KR')
    output=Path(args.output).resolve(); output.parent.mkdir(parents=True,exist_ok=True)
    run(*tools.signer_command('sign','--ks',key,'--ks-pass','pass:android','--key-pass','pass:android','--out',output,work/'aligned.apk'))
    if not args.skip_signature_check:run(*tools.signer_command('verify','--verbose',output))
    print('APK:',output)

if __name__=='__main__': main()
