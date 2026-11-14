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
          'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.5.16','CFBundleVersion':'42',
          'WKApplication':True,'WKWatchOnly':True,
          'NSBluetoothAlwaysUsageDescription':'갤럭시 휴대폰의 알림을 받기 위해 블루투스를 사용합니다.',
          'NSLocationWhenInUseUsageDescription':'선택한 위치 기반 연결 유지 모드에서 백그라운드 실행을 시도하기 위해 위치 업데이트를 사용합니다. 위치 좌표는 저장하거나 전송하지 않습니다.',
          'UIBackgroundModes':['bluetooth-central','location'],'FoldBridgePushEnabled':False,'CFBundleDevelopmentRegion':'en','CFBundleLocalizations':['en','ko']}
    (ROOT/'FoldBridge/Info.plist').write_bytes(plistlib.dumps(info))
    info['FoldBridgePushEnabled']=True
    (ROOT/'FoldBridge/InfoPush.plist').write_bytes(plistlib.dumps(info))
    (ROOT/'FoldBridge/Push.entitlements').write_bytes(plistlib.dumps({'aps-environment':'development'}))
    widget_info={'CFBundleDisplayName':'FoldBridge','CFBundleName':'$(PRODUCT_NAME)','CFBundleExecutable':'$(EXECUTABLE_NAME)',
                 'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundlePackageType':'XPC!',
                 'CFBundleShortVersionString':'0.5.16','CFBundleVersion':'42',
                 'CFBundleDevelopmentRegion':'en','CFBundleLocalizations':['en','ko'],
                 'NSExtension':{'NSExtensionPointIdentifier':'com.apple.widgetkit-extension'}}
    (ROOT/'FoldBridgeWidgets/Info.plist').write_bytes(plistlib.dumps(widget_info))
    objects=[]
    def add(name,body): objects.append(f'\t\t{identifier(name)} = {{ {body} }};')
    files=sorted((ROOT/'FoldBridge').glob('*.swift'))
    for f in files:
        add('file:'+f.name,f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quoted(f.name)}; sourceTree = "<group>";')
        add('build:'+f.name,f'isa = PBXBuildFile; fileRef = {identifier("file:"+f.name)};')
    shared_files=sorted((ROOT/'Shared').glob('*.swift'))
    widget_files=sorted((ROOT/'FoldBridgeWidgets').glob('*.swift'))
    for f in shared_files+widget_files:
        ref='shared:'+f.name if f in shared_files else 'widget:'+f.name
        add(ref,f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quoted(f.name)}; sourceTree = "<group>";')
        if f in shared_files: add('appbuild:'+f.name,f'isa = PBXBuildFile; fileRef = {identifier(ref)};')
        add('widgetbuild:'+f.name,f'isa = PBXBuildFile; fileRef = {identifier(ref)};')
    add('sharedgroup','isa = PBXGroup; children = ('+','.join(identifier('shared:'+f.name) for f in shared_files)+'); path = Shared; sourceTree = "<group>";')
    add('widgetgroup','isa = PBXGroup; children = ('+','.join(identifier('widget:'+f.name) for f in widget_files)+'); path = FoldBridgeWidgets; sourceTree = "<group>";')
    add('file:assets','isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>";')
    add('build:assets',f'isa = PBXBuildFile; fileRef = {identifier("file:assets")};')
    localized=[]
    for name in ['Localizable.strings','InfoPlist.strings']:
        children=[]
        for code in ['ko','en']:
            ref='locale:'+code+':'+name;children.append(identifier(ref))
            add(ref,f'isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {code}; path = {quoted(code+".lproj/"+name)}; sourceTree = "<group>";')
        group='localized:'+name;localized.append(group)
        add(group,'isa = PBXVariantGroup; children = ('+','.join(children)+'); name = '+quoted(name)+'; sourceTree = "<group>";')
        add('build:'+group,f'isa = PBXBuildFile; fileRef = {identifier(group)};')
    add('product','isa = PBXFileReference; explicitFileType = wrapper.application; path = FoldBridge.app; sourceTree = BUILT_PRODUCTS_DIR;')
    add('sourcegroup','isa = PBXGroup; children = ('+','.join([*(identifier('file:'+f.name) for f in files),identifier('file:assets'),*(identifier(group) for group in localized)])+'); path = FoldBridge; sourceTree = "<group>";')
    add('widgetproduct','isa = PBXFileReference; explicitFileType = wrapper.app-extension; path = FoldBridgeWidgets.appex; sourceTree = BUILT_PRODUCTS_DIR;')
    add('embedwidget',f'isa = PBXBuildFile; fileRef = {identifier("widgetproduct")}; settings = {{ ATTRIBUTES = (RemoveHeadersOnCopy); }};')
    add('widgetproxy',f'isa = PBXContainerItemProxy; containerPortal = {identifier("project")}; proxyType = 1; remoteGlobalIDString = {identifier("widgettarget")}; remoteInfo = FoldBridgeWidgets;')
    add('widgetdependency',f'isa = PBXTargetDependency; target = {identifier("widgettarget")}; targetProxy = {identifier("widgetproxy")};')
    add('embedphase',f'isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = ({identifier("embedwidget")}); name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;')
    add('products',f'isa = PBXGroup; children = ({identifier("product")},{identifier("widgetproduct")}); name = Products; sourceTree = "<group>";')
    add('group',f'isa = PBXGroup; children = ({identifier("sourcegroup")},{identifier("sharedgroup")},{identifier("widgetgroup")},{identifier("products")}); sourceTree = "<group>";')
    add('sources','isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join([*(identifier('build:'+f.name) for f in files),*(identifier('appbuild:'+f.name) for f in shared_files)])+'); runOnlyForDeploymentPostprocessing = 0;')
    add('Frameworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
    resource_files=','.join([identifier('build:assets'),*(identifier('build:'+group) for group in localized)])
    add('Resources',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({resource_files}); runOnlyForDeploymentPostprocessing = 0;')
    add('target',f'isa = PBXNativeTarget; buildConfigurationList = {identifier("targetconfig")}; buildPhases = ({identifier("sources")},{identifier("Frameworks")},{identifier("Resources")},{identifier("embedphase")}); buildRules = (); dependencies = ({identifier("widgetdependency")}); name = FoldBridge; productName = FoldBridge; productReference = {identifier("product")}; productType = "com.apple.product-type.application";')
    add('widgetsources','isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(identifier('widgetbuild:'+f.name) for f in shared_files+widget_files)+'); runOnlyForDeploymentPostprocessing = 0;')
    add('widgetframeworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
    for group in localized: add('widgetresource:'+group,f'isa = PBXBuildFile; fileRef = {identifier(group)};')
    add('widgetresources','isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(identifier('widgetresource:'+group) for group in localized)+'); runOnlyForDeploymentPostprocessing = 0;')
    add('widgettarget',f'isa = PBXNativeTarget; buildConfigurationList = {identifier("widgetconfig")}; buildPhases = ({identifier("widgetsources")},{identifier("widgetframeworks")},{identifier("widgetresources")}); buildRules = (); dependencies = (); name = FoldBridgeWidgets; productName = FoldBridgeWidgets; productReference = {identifier("widgetproduct")}; productType = "com.apple.product-type.app-extension";')
    for scope in ['project','target','widget']:
        for config in ['Debug','Release']:
            settings={'SWIFT_VERSION':'5.0','SDKROOT':'watchos','WATCHOS_DEPLOYMENT_TARGET':'10.0','CLANG_ENABLE_MODULES':'YES','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if config=='Debug' else '-O'}
            if scope=='target':
                settings.update({'PRODUCT_BUNDLE_IDENTIFIER':bundle_id,'PRODUCT_NAME':'$(TARGET_NAME)','ASSETCATALOG_COMPILER_APPICON_NAME':'FoldBridgeIcon','TARGETED_DEVICE_FAMILY':'4','CODE_SIGN_STYLE':'Automatic','GENERATE_INFOPLIST_FILE':'NO','INFOPLIST_FILE':'FoldBridge/InfoPush.plist' if push else 'FoldBridge/Info.plist','SUPPORTED_PLATFORMS':'watchos watchsimulator','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks','SKIP_INSTALL':'NO','ENABLE_USER_SCRIPT_SANDBOXING':'YES'})
                if push: settings['CODE_SIGN_ENTITLEMENTS']='FoldBridge/Push.entitlements'
            if scope=='widget':
                settings.update({'PRODUCT_BUNDLE_IDENTIFIER':bundle_id+'.widgets','PRODUCT_NAME':'$(TARGET_NAME)',
                    'WATCHOS_DEPLOYMENT_TARGET':'11.0','TARGETED_DEVICE_FAMILY':'4','CODE_SIGN_STYLE':'Automatic',
                    'GENERATE_INFOPLIST_FILE':'NO','INFOPLIST_FILE':'FoldBridgeWidgets/Info.plist',
                    'SUPPORTED_PLATFORMS':'watchos watchsimulator','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
                    'SKIP_INSTALL':'YES','APPLICATION_EXTENSION_API_ONLY':'YES','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'$(inherited) WIDGET_EXTENSION',
                    'ENABLE_USER_SCRIPT_SANDBOXING':'YES'})
            add(scope+config,'isa = XCBuildConfiguration; buildSettings = {'+' '.join(f'{k} = {quoted(v)};' for k,v in settings.items())+'}; name = '+config+';')
        add(scope+'config','isa = XCConfigurationList; buildConfigurations = ('+','.join(identifier(scope+c) for c in ['Debug','Release'])+'); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;')
    capability='SystemCapabilities = { com.apple.Push = { enabled = 1; }; };' if push else ''
    add('project',f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; TargetAttributes = {{ {identifier("target")} = {{ CreatedOnToolsVersion = 16.0; ProvisioningStyle = Automatic; {capability} }}; }}; }}; buildConfigurationList = {identifier("projectconfig")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (ko,en,Base); mainGroup = {identifier("group")}; productRefGroup = {identifier("products")}; projectDirPath = ""; projectRoot = ""; targets = ({identifier("target")},{identifier("widgettarget")});')
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
