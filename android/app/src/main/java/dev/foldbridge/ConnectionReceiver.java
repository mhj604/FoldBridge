package dev.foldbridge;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.content.*;
import android.content.pm.PackageManager;

public final class ConnectionReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context context, Intent intent) {
        String action=intent.getAction();
        if(BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)
                &&intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,-1)==BluetoothAdapter.STATE_OFF) {
            BridgeService.bluetoothOff();return;
        }
        boolean boot=Intent.ACTION_BOOT_COMPLETED.equals(action) || Intent.ACTION_MY_PACKAGE_REPLACED.equals(action);
        boolean bluetooth=BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)
                &&intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,-1)==BluetoothAdapter.STATE_ON;
        if(!boot&&!bluetooth)return;
        resumeIfEnabled(context);
    }
    static void resumeIfEnabled(Context context) {
        if(!context.getSystemService(android.os.UserManager.class).isUserUnlocked())return;
        if(!context.getSharedPreferences("settings",Context.MODE_PRIVATE).getBoolean("connection_enabled",false))return;
        if(context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED
                ||context.checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE)!=PackageManager.PERMISSION_GRANTED)return;
        if(BridgeService.instance!=null) {BridgeService.instance.resumeBluetooth();return;}
        try {context.startForegroundService(new Intent(context,BridgeService.class));}
        catch(RuntimeException error){BridgeService.error="연결 자동 시작이 제한됐습니다. Local 앱에서 연결 시작을 눌러 주세요.";}
    }
}
