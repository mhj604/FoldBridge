package dev.foldbridge;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.*;
import android.graphics.Color;
import android.os.*;
import android.provider.Settings;
import android.view.*;
import android.widget.*;
import java.util.*;

public final class MainActivity extends Activity {
    private final Handler handler=new Handler(Looper.getMainLooper());
    private LinearLayout root; private TextView state,details,code; private Button confirm; private Switch allApps;
    private final int ink=Color.rgb(233,242,240), muted=Color.rgb(153,174,168), accent=Color.rgb(84,222,173);
    private final Runnable update=new Runnable(){@Override public void run(){renderState();handler.postDelayed(this,400);}};
    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        ScrollView scroll=new ScrollView(this); root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setPadding(28,30,28,30);root.setBackgroundColor(Color.rgb(12,24,22));scroll.addView(root);setContentView(scroll);
        root.setOnApplyWindowInsetsListener((view,insets)->{android.graphics.Insets bars=insets.getInsets(WindowInsets.Type.systemBars());int pad=(int)(20*getResources().getDisplayMetrics().density);root.setPadding(pad+bars.left,pad+bars.top,pad+bars.right,pad+bars.bottom);return insets;});
        label("FOLDBRIDGE LOCAL",14,accent); label("모든 앱 알림을\nBluetooth로 직접",30,ink);
        label("Galaxy → Apple Watch",15,muted);
        state=label("",22,accent);details=label("",14,muted);code=label("",30,ink);
        confirm=button("워치의 코드와 같습니다",()->BridgeService.confirmPair());
        button("연결 시작",()->start(false));button("새 워치 등록 (2분)",()->start(true));
        button("1. 다른 앱 알림 읽기 허용",this::openNotificationAccess);
        allApps=new Switch(this);allApps.setText("모든 앱 알림 전달");allApps.setTextColor(ink);
        allApps.setChecked(getSharedPreferences("settings",MODE_PRIVATE).getBoolean("all_apps",true));root.addView(allApps);
        allApps.setOnCheckedChangeListener((button,checked)->{getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("all_apps",checked).apply();if(checked)NotificationRelay.replayActive();});
        Switch chargingStatus=new Switch(this);chargingStatus.setText("충전 상태 알림 전달");chargingStatus.setTextColor(ink);
        chargingStatus.setChecked(getSharedPreferences("settings",MODE_PRIVATE).getBoolean("forward_charging_status",false));root.addView(chargingStatus);
        chargingStatus.setOnCheckedChangeListener((button,checked)->{getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("forward_charging_status",checked).apply();NotificationRelay.replayActive();});
        button("2. 전달할 앱 선택",this::selectApps);
        button("3. 테스트 알림 보내기",()->{if(BridgeService.instance==null)toast("먼저 연결을 시작하세요.");else BridgeService.test();});
        label("서버 없이 Bluetooth로 직접 전달합니다. 워치에서 Local 앱 연결과 위치 연결 유지를 켜 주세요. 미전달 알림은 최대 24시간·1024개 보관합니다. Android가 가린 내용은 전달할 수 없습니다.",14,muted);
        button("연결 중지",()->{getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("connection_enabled",false).apply();stopService(new Intent(this,BridgeService.class));});
        button("등록한 워치 해제",()->new AlertDialog.Builder(this).setTitle("등록한 워치를 해제할까요?").setMessage("다시 연결하려면 두 기기에서 보안 코드를 확인해야 합니다.").setPositiveButton("해제",(d,w)->BridgeService.forget(this)).setNegativeButton("취소",null).show());
    }
    private TextView label(String value,int size,int color) {TextView v=new TextView(this);v.setText(value);v.setTextSize(size);v.setTextColor(color);v.setPadding(0,10,0,14);root.addView(v);return v;}
    private Button button(String title,Runnable action) {Button b=new Button(this);b.setText(title);b.setAllCaps(false);b.setTextColor(ink);b.setBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.rgb(29,51,45)));LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2);p.setMargins(0,5,0,5);root.addView(b,p);b.setOnClickListener(v->{try{action.run();}catch(Exception e){toast("설정을 확인하세요: "+e.getClass().getSimpleName());}});return b;}
    private void toast(String text){Toast.makeText(this,text,Toast.LENGTH_LONG).show();}
    private void openNotificationAccess() {
        Intent intent=new Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
            .putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,new ComponentName(this,NotificationRelay.class).flattenToString());
        try { startActivity(intent); } catch(ActivityNotFoundException error) { startActivity(new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)); }
    }
    private void renderState() {
        boolean access=NotificationRelay.hasAccess(this), bound=NotificationRelay.instance!=null;
        state.setText(access?BridgeService.status:"다른 앱의 알림 접근 권한이 필요합니다");
        String timing=BridgeService.lastRtt<0?"아직 없음":BridgeService.lastRtt+" ms";
        details.setText("Bluetooth: "+BridgeService.status+"\n알림 접근: "+(access?"허용됨":"꺼짐 · 1번 버튼에서 Local 알림 전달 허용")+"\n알림 수집 서비스: "+(bound?"연결됨":access?"연결 대기 중":"권한 필요")+"\n실시간 알림 수집 "+NotificationRelay.received+"개\n알림 전달 요청 "+NotificationRelay.forwarded+"개\n워치 수신 확인 "+BridgeService.acknowledged+"개\n전달 대기 "+BridgeService.waiting+"개\n최근 전달 확인 시간 "+timing+(BridgeService.error.isEmpty()?"":"\n"+BridgeService.error));
        boolean all=getSharedPreferences("settings",MODE_PRIVATE).getBoolean("all_apps",true);if(allApps.isChecked()!=all)allApps.setChecked(all);
        code.setText(BridgeService.pairingCode);confirm.setVisibility(BridgeService.pairingCode.isEmpty()?View.GONE:View.VISIBLE);
        BridgeService.recordState(this);
    }
    private void start(boolean pair) {
        if(checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED||checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE)!=PackageManager.PERMISSION_GRANTED) {requestPermissions(new String[]{Manifest.permission.BLUETOOTH_CONNECT,Manifest.permission.BLUETOOTH_ADVERTISE,Manifest.permission.POST_NOTIFICATIONS},7);toast("권한을 허용한 뒤 연결 버튼을 다시 누르세요.");return;}
        if(checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},8);
        getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("connection_enabled",true).apply();
        Intent i=new Intent(this,BridgeService.class);if(pair)i.setAction("pair");startForegroundService(i);
        NotificationRelay.reconnectIfAllowed(this);
        if(!NotificationRelay.hasAccess(this))new AlertDialog.Builder(this).setTitle("다른 앱 알림을 읽는 권한이 꺼져 있습니다")
            .setMessage("Bluetooth 연결만으로는 다른 앱의 알림을 전달할 수 없습니다. 설정에서 ‘FoldBridge Local 알림 전달’의 알림 접근을 허용해 주세요.")
            .setPositiveButton("알림 접근 설정",(d,w)->openNotificationAccess()).setNegativeButton("닫기",null).show();
    }
    private void selectApps() {
        TreeMap<String,String> names=new TreeMap<>(); Intent launcher=new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
        for(ResolveInfo r:getPackageManager().queryIntentActivities(launcher,PackageManager.ResolveInfoFlags.of(0)))if(!r.activityInfo.packageName.equals(getPackageName()))names.put(r.activityInfo.packageName,r.loadLabel(getPackageManager()).toString());
        if(NotificationRelay.instance!=null)for(var n:NotificationRelay.instance.getActiveNotifications())names.putIfAbsent(n.getPackageName(),n.getPackageName());
        List<Map.Entry<String,String>> apps=new ArrayList<>(names.entrySet());apps.sort(Comparator.comparing(Map.Entry::getValue));
        Set<String> selected=new HashSet<>(getSharedPreferences("settings",MODE_PRIVATE).getStringSet("apps",Collections.emptySet()));
        String[] titles=new String[apps.size()];boolean[] checked=new boolean[apps.size()];
        for(int i=0;i<apps.size();i++){titles[i]=apps.get(i).getValue();checked[i]=selected.contains(apps.get(i).getKey());}
        new AlertDialog.Builder(this).setTitle("선택한 앱만 전달").setMultiChoiceItems(titles,checked,(dialog,index,isChecked)->{String id=apps.get(index).getKey();if(isChecked)selected.add(id);else selected.remove(id);}).setPositiveButton("저장",(d,w)->getSharedPreferences("settings",MODE_PRIVATE).edit().putStringSet("apps",selected).putBoolean("all_apps",false).apply()).setNegativeButton("취소",null).show();
    }
    @Override public void onResume(){
        super.onResume();
        if(BridgeService.instance==null&&getSharedPreferences("settings",MODE_PRIVATE).getBoolean("connection_enabled",false)
                &&checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)==PackageManager.PERMISSION_GRANTED
                &&checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE)==PackageManager.PERMISSION_GRANTED) {
            startForegroundService(new Intent(this,BridgeService.class));
        }
        NotificationRelay.reconnectIfAllowed(this);handler.post(update);
    }
    @Override public void onPause(){handler.removeCallbacks(update);super.onPause();}
}
