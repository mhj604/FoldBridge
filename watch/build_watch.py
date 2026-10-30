#!/usr/bin/env python3
import argparse
import subprocess
import sys
from pathlib import Path
from generate_project import generate

parser=argparse.ArgumentParser(description='Build FoldBridge with the full Xcode installation on a Mac.')
parser.add_argument('--team',help='Apple signing team ID; omit for simulator compilation')
parser.add_argument('--push',action='store_true',help='Enable APNs (paid Apple Developer membership required)')
parser.add_argument('--bundle-id',default='dev.foldbridge.watch',help='Your unique watch app bundle identifier; use the same value as APNS_TOPIC')
args=parser.parse_args()
if sys.platform!='darwin':parser.error('watchOS compilation requires macOS and full Xcode. The current host cannot compile Apple frameworks.')
if args.push and not args.team:parser.error('--push requires --team and a Push-capable Apple provisioning profile.')
root=Path(__file__).resolve().parent;generate(args.push,args.bundle_id)
command=['xcodebuild','-project',str(root/'FoldBridge.xcodeproj'),'-scheme','FoldBridge','-derivedDataPath',str(root/'.build')]
if args.team:command+=['-destination','generic/platform=watchOS','DEVELOPMENT_TEAM='+args.team,'-allowProvisioningUpdates']
else:command+=['-destination','generic/platform=watchOS Simulator','CODE_SIGNING_ALLOWED=NO']
subprocess.run(command+['build'],check=True)
print('Build finished. To install, open FoldBridge.xcodeproj, choose the paired physical Watch, and press Run.')
