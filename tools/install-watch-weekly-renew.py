#!/usr/bin/env python3
"""Install FoldBridge's once-weekly macOS LaunchAgent without running renewal now."""
import argparse
import datetime as dt
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess

LABEL = 'dev.foldbridge.weekly-renew'
DEFAULT = Path.home() / 'Library/Application Support/FoldBridge/AutoRenew/config.json'


def command(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True)


def save_json(path, value):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')
    temporary.chmod(0o600)
    temporary.replace(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, default=DEFAULT)
    parser.add_argument('--weekday', type=int, choices=range(1, 8), default=5,
                        help='Local weekday: Monday=1 ... Sunday=7 (default Friday)')
    parser.add_argument('--hour', type=int, choices=range(24), default=16)
    parser.add_argument('--minute', type=int, choices=range(60), default=0)
    parser.add_argument('--remove', action='store_true', help='Remove only this weekly schedule')
    args = parser.parse_args()
    config_path = args.config.expanduser().resolve()
    config = json.loads(config_path.read_text())
    folder = Path(config['state_dir']).expanduser().resolve()
    folder.mkdir(parents=True, exist_ok=True)
    folder.chmod(0o700)
    launch_domain = 'gui/' + str(os.getuid())
    job = launch_domain + '/' + LABEL
    agent = Path.home() / 'Library/LaunchAgents' / (LABEL + '.plist')

    if args.remove:
        subprocess.run(['/bin/launchctl', 'bootout', job], capture_output=True)
        agent.unlink(missing_ok=True)
        if config.get('scheduler', {}).get('label') == LABEL:
            config['scheduler']['enabled'] = False
            save_json(config_path, config)
        print(json.dumps({'status': 'weekly_schedule_removed', 'registration_preserved': True}))
        return

    source_repo = Path(__file__).resolve().parent.parent
    revision = command('/usr/bin/git', '-C', str(source_repo), 'rev-parse', 'HEAD').stdout.strip()
    snapshot = folder / 'source.git'
    if not snapshot.exists():
        # No hardlinks/alternates: background runs need not access the Documents folder.
        command('/usr/bin/git', 'clone', '--bare', '--no-hardlinks', '--', str(source_repo), str(snapshot))
    command('/usr/bin/git', '-C', str(snapshot), 'fetch', '--no-tags', str(source_repo),
            '+HEAD:refs/heads/weekly-renew-source')
    command('/usr/bin/git', '-C', str(snapshot), 'symbolic-ref', 'HEAD', 'refs/heads/weekly-renew-source')
    runner = folder / 'watch-auto-renew.py'
    shutil.copy2(source_repo / 'tools/watch-auto-renew.py', runner)
    runner.chmod(0o700)

    backup = folder / ('config-before-weekly-' + dt.datetime.now().strftime('%Y%m%dT%H%M%S') + '.json')
    shutil.copy2(config_path, backup)
    backup.chmod(0o600)
    config['repo'] = str(snapshot)
    # The LaunchAgent runs once per week. This threshold does not create polling;
    # it lets that single scheduled run renew even after an intervening app update.
    config['renew_before_hours'] = 168
    config['scheduler'] = {'kind': 'launchd', 'label': LABEL, 'enabled': True,
                           'interval_days': 7, 'weekday': args.weekday,
                           'hour': args.hour, 'minute': args.minute,
                           'source_repo': str(source_repo), 'source_revision': revision}
    save_json(config_path, config)

    agent.parent.mkdir(parents=True, exist_ok=True)
    if agent.exists():
        shutil.copy2(agent, folder / 'weekly-agent-before-install.plist')
    plist = {
        'Label': LABEL,
        'ProgramArguments': ['/usr/bin/caffeinate', '-i', '/usr/bin/python3', str(runner),
                             '--config', str(config_path)],
        'StartCalendarInterval': {'Weekday': args.weekday, 'Hour': args.hour, 'Minute': args.minute},
        'LimitLoadToSessionType': 'Aqua',
        'EnvironmentVariables': {'PYTHONUNBUFFERED': '1', 'PATH': '/usr/bin:/bin:/usr/sbin:/sbin'},
        'StandardOutPath': str(folder / 'weekly.stdout.log'),
        'StandardErrorPath': str(folder / 'weekly.stderr.log'),
    }
    # No RunAtLoad, KeepAlive, StartInterval, --force or short-interval retry job.
    temporary = agent.with_suffix('.tmp')
    temporary.write_bytes(plistlib.dumps(plist))
    temporary.chmod(0o600)
    temporary.replace(agent)
    subprocess.run(['/bin/launchctl', 'bootout', job], capture_output=True)
    command('/bin/launchctl', 'enable', job)
    command('/bin/launchctl', 'bootstrap', launch_domain, str(agent))
    print(json.dumps({'status': 'weekly_schedule_installed', 'weekday': args.weekday,
                      'hour': args.hour, 'minute': args.minute, 'interval_days': 7,
                      'agent': str(agent), 'renewal_run_now': False}, ensure_ascii=False))


if __name__ == '__main__':
    main()
