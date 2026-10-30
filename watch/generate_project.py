#!/usr/bin/env python3
"""Generate a dependency-free Xcode project. Also keep project.yml for XcodeGen users."""
from pathlib import Path
import argparse
import hashlib
import json
import plistlib
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parent
def identifier(name): return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def quoted(value): return json.dumps(str(value),ensure_ascii=False)

def generate(push=False,bundle_id='dev.foldbridge.watch'):
    info={'CFBundleDisplayName':'FoldBridge','CFBundleName':'$(PRODUCT_NAME)','CFBundleExecutable':'$(EXECUTABLE_NAME)',
          'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.2.1','CFBundleVersion':'6',
          'WKApplication':True,'WKWatchOnly':True,
          'NSBluetoothAlwaysUsageDescription':'갤럭시 휴대폰의 알림을 받기 위해 블루투스를 사용합니다.',
          'NSLocationWhenInUseUsageDescription':'선택한 위치 기반 연결 유지 모드에서 백그라운드 실행을 시도하기 위해 위치 업데이트를 사용합니다. 위치 좌표는 저장하거나 전송하지 않습니다.',
          'UIBackgroundModes':['bluetooth-central','location'],'FoldBridgePushEnabled':False}
    (ROOT/'FoldBridge/Info.plist').write_bytes(plistlib.dumps(info))
    info['FoldBridgePushEnabled']=True
    (ROOT/'FoldBridge/InfoPush.plist').write_bytes(plistlib.dumps(info))
    (ROOT/'FoldBridge/Push.entitlements').write_bytes(plistlib.dumps({'aps-environment':'development'}))
    objects=[]
    def add(name,body): objects.append(f'\t\t{identifier(name)} = {{ {body} }};')
    files=sorted((ROOT/'FoldBridge').glob('*.swift'))
    for f in files:
        add('file:'+f.name,f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quoted(f.name)}; sourceTree = "<group>";')
        add('build:'+f.name,f'isa = PBXBuildFile; fileRef = {identifier("file:"+f.name)};')
    add('file:assets','isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>";')
    add('build:assets',f'isa = PBXBuildFile; fileRef = {identifier("file:assets")};')
    add('product','isa = PBXFileReference; explicitFileType = wrapper.application; path = FoldBridge.app; sourceTree = BUILT_PRODUCTS_DIR;')
    add('sourcegroup','isa = PBXGroup; children = ('+','.join([*(identifier('file:'+f.name) for f in files),identifier('file:assets')])+'); path = FoldBridge; sourceTree = "<group>";')
    add('products',f'isa = PBXGroup; children = ({identifier("product")}); name = Products; sourceTree = "<group>";')
    add('group',f'isa = PBXGroup; children = ({identifier("sourcegroup")},{identifier("products")}); sourceTree = "<group>";')
    add('sources','isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(identifier('build:'+f.name) for f in files)+'); runOnlyForDeploymentPostprocessing = 0;')
    add('Frameworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
    add('Resources',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({identifier("build:assets")}); runOnlyForDeploymentPostprocessing = 0;')
    add('target',f'isa = PBXNativeTarget; buildConfigurationList = {identifier("targetconfig")}; buildPhases = ({identifier("sources")},{identifier("Frameworks")},{identifier("Resources")}); buildRules = (); dependencies = (); name = FoldBridge; productName = FoldBridge; productReference = {identifier("product")}; productType = "com.apple.product-type.application";')
    for scope in ['project','target']:
        for config in ['Debug','Release']:
            settings={'SWIFT_VERSION':'5.0','SDKROOT':'watchos','WATCHOS_DEPLOYMENT_TARGET':'10.0','CLANG_ENABLE_MODULES':'YES','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if config=='Debug' else '-O'}
            if scope=='target':
                settings.update({'PRODUCT_BUNDLE_IDENTIFIER':bundle_id,'PRODUCT_NAME':'$(TARGET_NAME)','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','TARGETED_DEVICE_FAMILY':'4','CODE_SIGN_STYLE':'Automatic','GENERATE_INFOPLIST_FILE':'NO','INFOPLIST_FILE':'FoldBridge/InfoPush.plist' if push else 'FoldBridge/Info.plist','SUPPORTED_PLATFORMS':'watchos watchsimulator','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks','SKIP_INSTALL':'NO','ENABLE_USER_SCRIPT_SANDBOXING':'YES'})
                if push: settings['CODE_SIGN_ENTITLEMENTS']='FoldBridge/Push.entitlements'
            add(scope+config,'isa = XCBuildConfiguration; buildSettings = {'+' '.join(f'{k} = {quoted(v)};' for k,v in settings.items())+'}; name = '+config+';')
        add(scope+'config','isa = XCConfigurationList; buildConfigurations = ('+','.join(identifier(scope+c) for c in ['Debug','Release'])+'); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;')
    capability='SystemCapabilities = { com.apple.Push = { enabled = 1; }; };' if push else ''
    add('project',f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; TargetAttributes = {{ {identifier("target")} = {{ CreatedOnToolsVersion = 16.0; ProvisioningStyle = Automatic; {capability} }}; }}; }}; buildConfigurationList = {identifier("projectconfig")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = ko; hasScannedForEncodings = 0; knownRegions = (ko,en,Base); mainGroup = {identifier("group")}; productRefGroup = {identifier("products")}; projectDirPath = ""; projectRoot = ""; targets = ({identifier("target")});')
    project=ROOT/'FoldBridge.xcodeproj';project.mkdir(exist_ok=True)
    (project/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {identifier("project")}; }}\n')
    scheme=ET.Element('Scheme',{'LastUpgradeVersion':'1600','version':'1.3'})
    def reference(parent): ET.SubElement(parent,'BuildableReference',{'BuildableIdentifier':'primary','BlueprintIdentifier':identifier('target'),'BuildableName':'FoldBridge.app','BlueprintName':'FoldBridge','ReferencedContainer':'container:FoldBridge.xcodeproj'})
    action=ET.SubElement(scheme,'BuildAction',{'parallelizeBuildables':'YES','buildImplicitDependencies':'YES'})
    entry=ET.SubElement(ET.SubElement(action,'BuildActionEntries'),'BuildActionEntry',{'buildForTesting':'YES','buildForRunning':'YES','buildForProfiling':'YES','buildForArchiving':'YES','buildForAnalyzing':'YES'});reference(entry)
    launch=ET.SubElement(scheme,'LaunchAction',{'buildConfiguration':'Debug','selectedDebuggerIdentifier':'Xcode.DebuggerFoundation.Debugger.LLDB','selectedLauncherIdentifier':'Xcode.IDEFoundation.Launcher.LLDB','launchStyle':'0','useCustomWorkingDirectory':'NO','ignoresPersistentStateOnLaunch':'NO','debugDocumentVersioning':'YES','allowLocationSimulation':'YES'});reference(ET.SubElement(launch,'BuildableProductRunnable',{'runnableDebuggingMode':'0'}))
    ET.SubElement(scheme,'AnalyzeAction',{'buildConfiguration':'Debug'});ET.SubElement(scheme,'ArchiveAction',{'buildConfiguration':'Release','revealArchiveInOrganizer':'YES'})
    dest=project/'xcshareddata/xcschemes';dest.mkdir(parents=True,exist_ok=True);ET.indent(scheme)
    ET.ElementTree(scheme).write(dest/'FoldBridge.xcscheme',encoding='utf-8',xml_declaration=True)
    print('Xcode project generated. Push:',push)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--push',action='store_true');parser.add_argument('--bundle-id',default='dev.foldbridge.watch');args=parser.parse_args();generate(args.push,args.bundle_id)
