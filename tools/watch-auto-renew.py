#!/usr/bin/env python3
"""Renew the existing watch app with Xcode; config/state stay on the owner's Mac."""
import argparse
import datetime as dt
import fcntl
import io
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tarfile

UTC=dt.timezone.utc
DEFAULT=Path.home()/'Library/Application Support/FoldBridge/AutoRenew/config.json'

def now(): return dt.datetime.now(UTC)
def stamp(value): return value.astimezone(UTC).isoformat()
def date(value): return dt.datetime.fromisoformat(value.replace('Z','+00:00')).astimezone(UTC)
def save(path,value):
    temp=path.with_suffix('.tmp');temp.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n');temp.chmod(0o600);temp.replace(path)
def profile(path):
    result=subprocess.run(['/usr/bin/security','cms','-D','-i',str(path)],capture_output=True,timeout=30)
    if result.returncode: raise RuntimeError('Cannot decode provisioning profile: '+str(path))
    return plistlib.loads(result.stdout)
def expirations(app):
    bundles=[app]+sorted((app/'PlugIns').glob('*.appex'))
    return {plistlib.loads((b/'Info.plist').read_bytes())['CFBundleIdentifier']:stamp(profile(b/'embedded.mobileprovision')['ExpirationDate'].replace(tzinfo=UTC)) for b in bundles}

class Renewal:
    def __init__(self,config):
        self.config=config;self.folder=Path(config['state_dir']).expanduser();self.folder.mkdir(parents=True,exist_ok=True);self.folder.chmod(0o700)
        self.state_path=self.folder/'state.json'
        self.state=json.loads(self.state_path.read_text()) if self.state_path.exists() else {'installed_profiles':config['installed_profiles']}
        self.env=dict(os.environ,DEVELOPER_DIR=config['developer_dir'])
        self.device=config['device'];self.bundle=config['bundle_id']
    def finish(self,status,**values):
        self.state.update(status=status,checked_at=stamp(now()),**values);save(self.state_path,self.state)
        result={'status':status,'expires':min(self.state.get('installed_profiles',{}).values(),default=None)}
        result.update(values);print(json.dumps(result,ensure_ascii=False));return 0
    def command(self,args,timeout=30):
        return subprocess.run(args,env=self.env,capture_output=True,timeout=timeout)
    def device_json(self,arguments,tag):
        dest=self.folder/(tag+'.json')
        result=self.command(['/usr/bin/xcrun','devicectl',*arguments,'--device',self.device,'--json-output',str(dest),'--timeout','20'],timeout=30)
        if result.returncode:return None
        return json.loads(dest.read_text()).get('result',{})
    def unlocked(self):
        state=self.device_json(['device','info','lockState'],'lock-state')
        if state is None:return None
        return state.get('passcodeRequired') is False and state.get('unlockedSinceBoot') is True
    def launch(self):
        result=self.command(['/usr/bin/xcrun','devicectl','device','process','launch','--device',self.device,self.bundle,'--timeout','20'],timeout=30)
        self.state['pending_launch']=result.returncode!=0
        return result.returncode==0
    def run(self,force=False):
        current=now();installed=self.state['installed_profiles'];minimum=min(date(x) for x in installed.values())
        due=minimum<=current+dt.timedelta(hours=self.config.get('renew_before_hours',72))
        if not due and not force and not self.state.get('pending_launch'):
            return self.finish('not_due')
        lock=self.unlocked()
        if lock is None:return self.finish('waiting_watch_connection')
        if not lock:return self.finish('waiting_watch_unlock')
        if self.state.get('pending_launch'):
            if not self.launch():return self.finish('waiting_app_launch')
            if not due and not force:return self.finish('app_resumed')
        repo=Path(self.config['repo']).expanduser()
        tree=self.command(['/usr/bin/git','-C',str(repo),'rev-parse','HEAD:watch'])
        if tree.returncode:return self.finish('source_unavailable')
        tree=tree.stdout.decode().strip()
        revision=self.command(['/usr/bin/git','-C',str(repo),'rev-parse','HEAD']).stdout.decode().strip()
        info=self.command(['/usr/bin/git','-C',str(repo),'show','HEAD:watch/FoldBridge/Info.plist'])
        if info.returncode:return self.finish('source_unavailable')
        source_info=plistlib.loads(info.stdout)
        if source_info['CFBundleIdentifier']!='$(PRODUCT_BUNDLE_IDENTIFIER)':return self.finish('unexpected_source_bundle')
        device_apps=self.device_json(['device','info','apps','--bundle-id',self.bundle],'installed-app')
        if device_apps is None:return self.finish('waiting_watch_connection')
        apps=device_apps.get('apps',[])
        app=next((a for a in apps if a.get('bundleIdentifier')==self.bundle),None)
        if app is None:return self.finish('installed_app_unavailable')
        if str(app.get('bundleVersion'))!=str(source_info['CFBundleVersion']):
            return self.finish('source_version_differs',source_build=source_info['CFBundleVersion'],installed_build=app.get('bundleVersion'))
        candidate=self.state.get('candidate',{})
        candidate_path=Path(candidate.get('path','/nonexistent'))
        reusable=(candidate.get('tree')==tree and candidate_path.is_dir() and
                  min((date(x) for x in candidate.get('profiles',{}).values()),default=current)>current+dt.timedelta(hours=24) and
                  min((date(x) for x in candidate.get('profiles',{}).values()),default=current)>minimum+dt.timedelta(hours=1))
        if not reusable:
            attempt=self.state.get('last_build_attempt')
            if not force and attempt and current-date(attempt)<dt.timedelta(hours=6):return self.finish('waiting_build_retry')
            self.state['last_build_attempt']=stamp(current);save(self.state_path,self.state)
            source=self.folder/'sources'/tree
            if not source.exists():
                source.mkdir(parents=True)
                archive=self.command(['/usr/bin/git','-C',str(repo),'archive','--format=tar','HEAD','watch'])
                if archive.returncode:return self.finish('source_unavailable')
                with tarfile.open(fileobj=io.BytesIO(archive.stdout)) as tar:
                    # Archive contains only the committed watch directory, never the worktree.
                    for member in tar.getmembers():
                        target=(source/member.name).resolve()
                        if not target.is_relative_to(source.resolve()):raise RuntimeError('Unexpected archive path')
                    tar.extractall(source)
            backup=self.folder/'profile-backups'/current.strftime('%Y%m%dT%H%M%SZ')
            backup.mkdir(parents=True,exist_ok=True)
            moved=[]
            targets={self.config['team']+'.'+self.bundle,self.config['team']+'.'+self.bundle+'.widgets'}
            try:
                for directory in [Path.home()/'Library/Developer/Xcode/UserData/Provisioning Profiles',Path.home()/'Library/MobileDevice/Provisioning Profiles']:
                    for path in directory.glob('*.mobileprovision'):
                        try: details=profile(path)
                        except Exception:continue
                        if details.get('Entitlements',{}).get('application-identifier') in targets:
                            dest=backup/(str(len(moved))+'-'+path.name);shutil.move(path,dest);moved.append((path,dest))
                log=self.folder/'build.log'
                args=['/usr/bin/xcodebuild','-quiet','-project',str(source/'watch/FoldBridge.xcodeproj'),'-scheme','FoldBridge',
                      '-configuration','Debug','-destination','generic/platform=watchOS','-derivedDataPath',str(self.folder/'build'),
                      '-allowProvisioningUpdates','DEVELOPMENT_TEAM='+self.config['team'],'build']
                with log.open('wb') as output:
                    try:result=subprocess.run(args,env=self.env,stdout=output,stderr=subprocess.STDOUT,timeout=900)
                    except subprocess.TimeoutExpired:return self.finish('build_timed_out',build_log=str(log))
                if result.returncode:return self.finish('build_failed',build_log=str(log))
                candidate_path=self.folder/'build/Build/Products/Debug-watchos/FoldBridge.app'
                fresh=expirations(candidate_path)
                newminimum=min(date(x) for x in fresh.values())
                if newminimum<=minimum+dt.timedelta(hours=1):return self.finish('renewal_not_extended',build_log=str(log))
                self.state['candidate']={'tree':tree,'revision':revision,'path':str(candidate_path),'profiles':fresh}
                save(self.state_path,self.state)
            finally:
                for original,saved in moved:
                    if not original.exists():shutil.copy2(saved,original)
        if not self.unlocked():return self.finish('renewed_waiting_watch',candidate_expires=min(self.state['candidate']['profiles'].values()))
        install_log=self.folder/'install.log'
        with install_log.open('wb') as output:
            try:
                result=subprocess.run(['/usr/bin/xcrun','devicectl','device','install','app','--device',self.device,str(candidate_path),'--timeout','90'],
                                      env=self.env,stdout=output,stderr=subprocess.STDOUT,timeout=100)
            except subprocess.TimeoutExpired:return self.finish('install_timed_out',install_log=str(install_log))
        if result.returncode:return self.finish('install_pending',install_log=str(install_log))
        self.state['installed_profiles']=self.state['candidate']['profiles'];self.state['installed_at']=stamp(now())
        self.state['installed_revision']=self.state['candidate']['revision'];self.state['pending_launch']=True
        save(self.state_path,self.state)
        launched=self.launch()
        return self.finish('renewed' if launched else 'renewed_waiting_app_launch')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config',type=Path,default=DEFAULT);parser.add_argument('--force',action='store_true')
    parser.add_argument('--setup-from-app',type=Path,help='Seed local configuration from the signed app currently installed on the watch')
    parser.add_argument('--device',help='The paired physical watch UDID for initial setup')
    parser.add_argument('--repo',type=Path,default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--developer-dir',default='/Applications/Xcode.app/Contents/Developer')
    args=parser.parse_args()
    if args.setup_from_app:
        if not args.device:parser.error('--device is required for setup')
        config_path=args.config.expanduser()
        if config_path.exists():parser.error('Configuration already exists; retain its installed-profile state')
        app=args.setup_from_app.expanduser().resolve();details=profile(app/'embedded.mobileprovision')
        if args.device not in details.get('ProvisionedDevices',[]):parser.error('The signed app does not include this watch UDID')
        info=plistlib.loads((app/'Info.plist').read_bytes())
        config_path.parent.mkdir(parents=True,exist_ok=True);config_path.parent.chmod(0o700)
        config={'repo':str(args.repo.expanduser().resolve()),'state_dir':str(config_path.parent),'device':args.device,
                'bundle_id':info['CFBundleIdentifier'],'team':details['TeamIdentifier'][0],
                'developer_dir':args.developer_dir,'renew_before_hours':72,'installed_profiles':expirations(app)}
        save(config_path,config);print(json.dumps({'status':'configured','config':str(config_path)}));return 0
    config=json.loads(args.config.expanduser().read_text());renewal=Renewal(config)
    with (renewal.folder/'run.lock').open('a') as lock:
        try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:print('{"status":"already_running"}');return 0
        try:return renewal.run(args.force)
        except Exception as error:
            # Local path/logs may identify the owner's machine; never commit the state directory.
            return renewal.finish('error',error_type=type(error).__name__,error=str(error))
if __name__=='__main__':raise SystemExit(main())
