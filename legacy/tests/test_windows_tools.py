import argparse
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
import zipfile

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'android'))
from build_android import Toolchain
spec=importlib.util.spec_from_file_location('foldbridge_windows',ROOT/'windows/foldbridge_windows.py')
windows=importlib.util.module_from_spec(spec);spec.loader.exec_module(windows)


class WindowsToolsTest(unittest.TestCase):
    def test_windows_sdk_and_jdk_with_spaces_use_exe_and_jar_not_batch_shell(self):
        with tempfile.TemporaryDirectory(prefix='FoldBridge & Windows ') as folder:
            root=Path(folder);sdk=root/'Android SDK';jdk=root/'JDK 21'
            for path in [sdk/'platforms/android-36/android.jar',sdk/'build-tools/36.0.0/aapt2.exe',sdk/'build-tools/36.0.0/zipalign.exe',sdk/'build-tools/36.0.0/lib/d8.jar',sdk/'build-tools/36.0.0/lib/apksigner.jar',jdk/'bin/java.exe',jdk/'bin/javac.exe',jdk/'bin/keytool.exe']:
                path.parent.mkdir(parents=True,exist_ok=True);path.touch()
            tools=Toolchain.resolve(sdk,jdk,windows=True)
            self.assertEqual(tools.java,jdk/'bin/java.exe')
            self.assertEqual(tools.aapt2.name,'aapt2.exe')
            self.assertEqual(tools.zipalign.name,'zipalign.exe')
            dex=tools.dex_command('--output',root/'APK output');sign=tools.signer_command('verify',root/'APK output/test.apk')
            self.assertIn(sdk/'build-tools/36.0.0/lib/d8.jar',dex)
            self.assertIn('com.android.tools.r8.D8',dex)
            self.assertIn('-jar',sign)
            self.assertNotIn('cmd.exe',[str(x) for x in dex+sign])
            self.assertFalse(any(str(x).endswith('.bat') for x in dex+sign))

    def test_missing_windows_tools_fail_with_required_files(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError,'aapt2.exe'):
                Toolchain.resolve(Path(folder)/'SDK',Path(folder)/'JDK',windows=True)

    def test_adb_rejects_unauthorized_offline_and_ambiguous_devices(self):
        for value in ['List of devices attached\nabc unauthorized\n','List of devices attached\nabc offline\n','List of devices attached\nabc device\ndef device\n']:
            with self.assertRaises(ValueError):windows.select_device(value)
        self.assertEqual(windows.select_device('List of devices attached\nabc device product:a\n'),'abc')
        self.assertEqual(windows.select_device('List of devices attached\nabc device\ndef device\n','def'),'def')
        with self.assertRaises(ValueError):windows.select_device('List of devices attached\nabc device\n','unknown')

    def test_windows_env_bom_quotes_backslashes_and_expressions_stay_literal(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'.env'
            path.write_text('APNS_KEY_FILE="C:\\Private Keys\\AuthKey.p8"\nRELAY_TOKEN=$(untrusted command)\nAPNS_TOPIC=dev.foldbridge.watch\n',encoding='utf-8-sig')
            values=windows.read_env(path)
            self.assertEqual(values['APNS_KEY_FILE'],'C:\\Private Keys\\AuthKey.p8')
            self.assertEqual(values['RELAY_TOKEN'],'$(untrusted command)')

    def test_unknown_env_keys_and_unclosed_quotes_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'.env'
            for text in ['UNEXPECTED=value','RELAY_TOKEN="unfinished']:
                path.write_text(text,encoding='utf-8')
                with self.assertRaises(ValueError):windows.read_env(path)

    def test_prepare_watch_excludes_credentials_build_output_and_user_data(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);watch=root/'watch'
            files=['FoldBridge/WatchLink.swift','FoldBridge/Info.plist','FoldBridge/Push.entitlements','FoldBridge.xcodeproj/project.pbxproj','FoldBridge.xcodeproj/xcshareddata/xcschemes/FoldBridge.xcscheme','FoldBridge.xcodeproj/xcuserdata/private.xcscheme','.build/generated.swift','AuthKey.p8','build_watch.py']
            for name in files:
                file=watch/name;file.parent.mkdir(parents=True,exist_ok=True);file.write_text('fixture',encoding='utf-8')
            output=root/'Mac package.zip'
            with mock.patch.object(windows,'ROOT',root),contextlib.redirect_stdout(io.StringIO()):windows.prepare_watch(argparse.Namespace(output=str(output)))
            with zipfile.ZipFile(output) as archive:
                names=archive.namelist()
                self.assertIn('FoldBridge/watch/FoldBridge/WatchLink.swift',names)
                self.assertIn('FoldBridge/watch/FoldBridge.xcodeproj/project.pbxproj',names)
                self.assertTrue(all('AuthKey' not in n and '/.build/' not in n and '/xcuserdata/' not in n for n in names))
                self.assertIn('FoldBridge/README-MAC.txt',names)

    def test_relay_setup_preserves_existing_environment_file(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);python=windows.venv_python(root/'relay/.venv');python.parent.mkdir(parents=True);python.touch()
            settings=root/'windows/.env';settings.parent.mkdir();settings.write_text('RELAY_TOKEN=keep-existing-value',encoding='utf-8')
            with mock.patch.object(windows,'ROOT',root),mock.patch.object(windows,'run') as run,contextlib.redirect_stdout(io.StringIO()):
                windows.relay_setup(argparse.Namespace(env_file=None))
            self.assertEqual(settings.read_text(),'RELAY_TOKEN=keep-existing-value')
            self.assertEqual(run.call_count,1)


if __name__=='__main__':unittest.main(verbosity=2)
