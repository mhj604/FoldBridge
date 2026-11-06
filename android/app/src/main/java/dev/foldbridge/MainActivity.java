package dev.foldbridge;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.*;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.RippleDrawable;
import android.os.*;
import android.provider.Settings;
import android.view.*;
import android.widget.*;
import java.util.*;

public final class MainActivity extends Activity {
    private final Handler handler=new Handler(Looper.getMainLooper());
    private LinearLayout root,pairCard;
    private TextView state,subtitle,receiptCount,waitingCount,code,statusDot;
    private Button connectButton,refreshButton,permissionButton,selectedAppsButton;
    private long lastRefresh=-3000;
    private Switch allApps;
    private final int ink=Color.rgb(239,245,248),muted=Color.rgb(147,166,180),accent=Color.rgb(130,230,209);
    private final int background=Color.rgb(9,15,21),surface=Color.rgb(20,30,40),line=Color.rgb(39,53,65);
    private final Runnable update=new Runnable(){@Override public void run(){renderState();handler.postDelayed(this,700);}};
    private int dp(float value){return Math.round(value*getResources().getDisplayMetrics().density);}
    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        getWindow().setStatusBarColor(background);getWindow().setNavigationBarColor(background);
        ScrollView scroll=new ScrollView(this);scroll.setFillViewport(true);scroll.setClipToPadding(false);scroll.setBackgroundColor(background);
        FrameLayout canvas=new FrameLayout(this);scroll.addView(canvas);
        root=column();root.setPadding(dp(24),dp(26),dp(24),dp(28));
        FrameLayout.LayoutParams content=new FrameLayout.LayoutParams(Math.min(getResources().getDisplayMetrics().widthPixels,dp(608)),-2,Gravity.TOP|Gravity.CENTER_HORIZONTAL);
        canvas.addView(root,content);setContentView(scroll);
        scroll.setOnApplyWindowInsetsListener((view,insets)->{
            android.graphics.Insets bars=insets.getInsets(WindowInsets.Type.systemBars());
            scroll.setPadding(bars.left,bars.top,bars.right,bars.bottom);
            WindowInsetsController controls=getWindow().getInsetsController();if(controls!=null)controls.setSystemBarsAppearance(0,WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS|WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS);
            return insets;
        });
        LinearLayout header=row();header.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout title=column();addText(title,"FOLDBRIDGE",11,accent,true);addText(title,L("가까이, 더 자연스럽게"),25,ink,true);
        header.addView(title,new LinearLayout.LayoutParams(0,-2,1));
        Button settings=action(L("설정"),this::showSettings,false);header.addView(settings,new LinearLayout.LayoutParams(dp(84),dp(42)));root.addView(header);
        TextView intro=addText(root,L("휴대폰의 알림을 손목에서 만나세요."),14,muted,false);intro.setPadding(0,dp(8),0,dp(26));

        LinearLayout connection=card();LinearLayout headline=row();headline.setGravity(Gravity.CENTER_VERTICAL);
        statusDot=addText(headline,"●",17,accent,false);statusDot.setPadding(0,0,dp(9),0);
        state=addText(headline,L("연결 준비 중"),20,ink,true);connection.addView(headline);
        subtitle=addText(connection,"",13,muted,false);subtitle.setPadding(0,dp(9),0,dp(4));
        permissionButton=action(L("알림 접근 허용"),this::openNotificationAccess,true);connection.addView(permissionButton,buttonParams());
        connectButton=action(L("워치 연결"),()->start(false),true);connection.addView(connectButton,buttonParams());
        refreshButton=action(L("연결 새로고침"),this::refreshConnection,false);connection.addView(refreshButton,buttonParams());
        root.addView(connection,sectionParams(0));

        pairCard=card();addText(pairCard,L("처음 연결하는 워치인가요?"),13,muted,false);
        code=addText(pairCard,"",34,ink,true);code.setLetterSpacing(.14f);code.setPadding(0,dp(10),0,dp(8));
        addText(pairCard,L("워치의 코드와 같으면 확인해 주세요."),13,muted,false);
        pairCard.addView(action(L("코드가 같아요"),BridgeService::confirmPair,true),buttonParams());root.addView(pairCard,sectionParams(14));

        LinearLayout stats=row();LinearLayout received=card(),waiting=card();
        receiptCount=addText(received,"0",28,ink,true);addText(received,L("수신 확인"),12,muted,false);
        waitingCount=addText(waiting,"0",28,ink,true);addText(waiting,L("전달 대기"),12,muted,false);
        LinearLayout.LayoutParams first=new LinearLayout.LayoutParams(0,-2,1);first.setMargins(0,0,dp(6),0);stats.addView(received,first);
        LinearLayout.LayoutParams second=new LinearLayout.LayoutParams(0,-2,1);second.setMargins(dp(6),0,0,0);stats.addView(waiting,second);root.addView(stats,sectionParams(14));

        TextView section=addText(root,L("내 알림"),15,ink,true);section.setPadding(dp(2),dp(28),0,dp(12));
        LinearLayout preferences=card();
        allApps=toggle(preferences,L("모든 앱 알림"),L("앱을 선택하지 않고 모두 전달합니다"),getSharedPreferences("settings",MODE_PRIVATE).getBoolean("all_apps",true));
        allApps.setOnCheckedChangeListener((button,checked)->{getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("all_apps",checked).apply();if(checked)NotificationRelay.replayActive();renderState();});
        View divider=new View(this);divider.setBackgroundColor(line);LinearLayout.LayoutParams dividerParams=new LinearLayout.LayoutParams(-1,dp(1));dividerParams.setMargins(0,dp(15),0,dp(15));preferences.addView(divider,dividerParams);
        Switch charging=toggle(preferences,L("충전 상태 알림"),L("충전 시작만 한 번 알리고 수치 갱신은 제외합니다"),getSharedPreferences("settings",MODE_PRIVATE).getBoolean("forward_charging_status",false));
        charging.setOnCheckedChangeListener((button,checked)->{getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("forward_charging_status",checked).apply();NotificationRelay.replayActive();});
        selectedAppsButton=action(L("전달할 앱 선택"),this::selectApps,false);preferences.addView(selectedAppsButton,buttonParams());root.addView(preferences);
        LinearLayout vehicle=card();addText(vehicle,L("마이현대 차량 제어"),18,ink,true);
        addText(vehicle,L("갤럭시의 공식 제어 위젯을 워치에 연결합니다."),13,muted,false);
        vehicle.addView(action(L("차량 제어 설정"),()->startActivity(new Intent(this,VehicleSettingsActivity.class)),false),buttonParams());
        root.addView(vehicle,sectionParams(14));
        TextView note=addText(root,L("휴대폰과 워치가 가까이 있으면 연결을 이어갑니다."),12,muted,false);note.setPadding(dp(2),dp(20),dp(2),0);
    }
    private LinearLayout column(){LinearLayout v=new LinearLayout(this);v.setOrientation(LinearLayout.VERTICAL);return v;}
    private LinearLayout row(){LinearLayout v=new LinearLayout(this);v.setOrientation(LinearLayout.HORIZONTAL);return v;}
    private GradientDrawable rounded(int color,float radius){GradientDrawable d=new GradientDrawable();d.setColor(color);d.setCornerRadius(dp(radius));return d;}
    private LinearLayout card(){LinearLayout v=column();v.setPadding(dp(20),dp(20),dp(20),dp(20));v.setBackground(rounded(surface,22));return v;}
    private LinearLayout.LayoutParams sectionParams(int top){LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2);p.setMargins(0,dp(top),0,0);return p;}
    private LinearLayout.LayoutParams buttonParams(){LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(50));p.setMargins(0,dp(15),0,0);return p;}
    private TextView addText(LinearLayout parent,String value,int size,int color,boolean bold){TextView v=new TextView(this);v.setText(value);v.setTextSize(size);v.setTextColor(color);v.setFontFeatureSettings("tnum");v.setIncludeFontPadding(false);v.setLineSpacing(dp(3),1);v.setTypeface(Typeface.create("sans-serif",bold?Typeface.BOLD:Typeface.NORMAL));parent.addView(v);return v;}
    private Button action(String title,Runnable runnable,boolean primary){Button b=new Button(this);b.setText(title);b.setTextSize(14);b.setAllCaps(false);b.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));b.setTextColor(primary?background:ink);b.setPadding(dp(12),0,dp(12),0);b.setMinHeight(0);b.setMinimumHeight(0);b.setStateListAnimator(null);b.setBackground(new RippleDrawable(ColorStateList.valueOf(Color.argb(45,255,255,255)),rounded(primary?accent:line,15),null));b.setOnClickListener(v->{try{runnable.run();}catch(Exception error){toast(L("설정을 확인해 주세요: ")+error.getClass().getSimpleName());}});return b;}
    private Switch toggle(LinearLayout parent,String title,String detail,boolean checked){LinearLayout group=row();group.setGravity(Gravity.CENTER_VERTICAL);LinearLayout words=column();addText(words,title,15,ink,true);TextView description=addText(words,detail,12,muted,false);description.setPadding(0,dp(6),dp(8),0);group.addView(words,new LinearLayout.LayoutParams(0,-2,1));Switch control=new Switch(this);control.setContentDescription(title);control.setShowText(false);control.setChecked(checked);control.setThumbTintList(new ColorStateList(new int[][]{new int[]{android.R.attr.state_checked},new int[]{}},new int[]{accent,muted}));control.setTrackTintList(new ColorStateList(new int[][]{new int[]{android.R.attr.state_checked},new int[]{}},new int[]{Color.rgb(43,92,85),line}));group.addView(control,new LinearLayout.LayoutParams(-2,dp(48)));parent.addView(group);return control;}
    private String L(String value){return I18n.t(this,value);}
    private void text(TextView view,String value){if(!view.getText().toString().equals(value))view.setText(value);}
    private void toast(String text){Toast.makeText(this,text,Toast.LENGTH_LONG).show();}
    private void openNotificationAccess(){Intent i=new Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,new ComponentName(this,NotificationRelay.class).flattenToString());try{startActivity(i);}catch(ActivityNotFoundException error){startActivity(new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS));}}
    private void renderState(){
        boolean access=NotificationRelay.hasAccess(this),bound=NotificationRelay.instance!=null,connected=BridgeService.isConnected(),running=BridgeService.instance!=null;
        text(state,!access?L("알림 접근이 필요해요"):connected?L("워치와 연결됐어요"):running?L("워치를 기다리고 있어요"):L("연결을 시작해 볼까요?"));
        statusDot.setTextColor(!access||!BridgeService.error.isEmpty()?Color.rgb(255,192,126):connected?accent:muted);
        text(subtitle,!access?L("다른 앱의 알림을 읽을 수 있도록 허용해 주세요."):!BridgeService.error.isEmpty()?L(BridgeService.error):!bound?L("알림 수집 서비스에 연결하고 있어요."):connected?L("새 알림을 워치로 전달하고 있어요."):L("워치에서 FoldBridge를 열어 주세요."));
        permissionButton.setVisibility(access?View.GONE:View.VISIBLE);connectButton.setVisibility(running?View.GONE:View.VISIBLE);
        refreshButton.setVisibility(running?View.VISIBLE:View.GONE);
        pairCard.setVisibility(BridgeService.pairingCode.isEmpty()?View.GONE:View.VISIBLE);text(code,BridgeService.pairingCode);
        text(receiptCount,Long.toString(BridgeService.acknowledged));text(waitingCount,Integer.toString(BridgeService.waiting));
        boolean all=getSharedPreferences("settings",MODE_PRIVATE).getBoolean("all_apps",true);if(allApps.isChecked()!=all)allApps.setChecked(all);selectedAppsButton.setVisibility(all?View.GONE:View.VISIBLE);
        BridgeService.recordState(this);
    }
    private void showSettings(){
        String[] items={L("새 워치 등록"),L("알림 접근 설정"),L("전달할 앱 선택"),L("연결 진단"),L("연결 중지"),L("등록한 워치 해제"),L("언어 / Language")};
        new AlertDialog.Builder(this).setTitle(L("설정")).setItems(items,(dialog,index)->{
            switch(index){
                case 0->start(true);case 1->openNotificationAccess();case 2->selectApps();case 3->showDiagnostics();
                case 4->{getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("connection_enabled",false).apply();stopService(new Intent(this,BridgeService.class));}
                case 6->showLanguageSettings();
                case 5->new AlertDialog.Builder(this).setTitle(L("워치 등록을 해제할까요?")).setMessage(L("다시 연결할 때 두 기기에서 코드를 확인해야 합니다.")).setPositiveButton(L("해제"),(d,w)->BridgeService.forget(this)).setNegativeButton(L("취소"),null).show();
            }
        }).setNegativeButton(L("닫기"),null).show();
    }
    private void showLanguageSettings(){
        android.app.LocaleManager locales=getSystemService(android.app.LocaleManager.class);
        String current=locales.getApplicationLocales().toLanguageTags();
        int selected=current.isEmpty()?0:current.startsWith("ko")?1:2;
        new AlertDialog.Builder(this).setTitle(L("언어 / Language"))
            .setSingleChoiceItems(new String[]{L("시스템 설정"),"한국어","English"},selected,(dialog,index)->{
                dialog.dismiss();
                locales.setApplicationLocales(android.os.LocaleList.forLanguageTags(new String[]{"","ko","en"}[index]));
            }).setNegativeButton(L("취소"),null).show();
    }
    private void showDiagnostics(){
        String timing=BridgeService.lastRtt<0?L("아직 없음"):BridgeService.lastRtt+" ms";
        new AlertDialog.Builder(this).setTitle(L("연결 진단")).setMessage(L("연결: ")+L(BridgeService.status)+L("\n알림 접근: ")+(NotificationRelay.hasAccess(this)?L("허용됨"):L("꺼짐"))+L("\n알림 수집: ")+(NotificationRelay.instance!=null?L("연결됨"):L("대기 중"))+L("\n수집 ")+NotificationRelay.received+L(" · 전달 요청 ")+NotificationRelay.forwarded+L("\n최근 전달 확인: ")+timing+"\n\nFoldBridge Local 0.6.5").setPositiveButton(L("닫기"),null).show();
    }
    private void start(boolean pair) {
        if(checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED||checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE)!=PackageManager.PERMISSION_GRANTED) {requestPermissions(new String[]{Manifest.permission.BLUETOOTH_CONNECT,Manifest.permission.BLUETOOTH_ADVERTISE,Manifest.permission.POST_NOTIFICATIONS},7);toast(L("권한을 허용한 뒤 연결 버튼을 다시 누르세요."));return;}
        if(checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},8);
        getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("connection_enabled",true).apply();
        Intent i=new Intent(this,BridgeService.class);if(pair)i.setAction("pair");startForegroundService(i);
        NotificationRelay.reconnectIfAllowed(this);
        if(!NotificationRelay.hasAccess(this))new AlertDialog.Builder(this).setTitle(L("다른 앱 알림을 읽는 권한이 꺼져 있습니다"))
            .setMessage(L("Bluetooth 연결만으로는 다른 앱의 알림을 전달할 수 없습니다. 설정에서 ‘FoldBridge Local 알림 전달’의 알림 접근을 허용해 주세요."))
            .setPositiveButton(L("알림 접근 설정"),(d,w)->openNotificationAccess()).setNegativeButton(L("닫기"),null).show();
    }
    private void refreshConnection() {
        if(SystemClock.elapsedRealtime()-lastRefresh<3000)return;
        if(checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED||checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE)!=PackageManager.PERMISSION_GRANTED){start(false);return;}
        lastRefresh=SystemClock.elapsedRealtime();
        getSharedPreferences("settings",MODE_PRIVATE).edit().putBoolean("connection_enabled",true).apply();
        startForegroundService(new Intent(this,BridgeService.class).setAction("refresh"));
        NotificationRelay.reconnectIfAllowed(this);
        toast(L("기존 등록을 유지한 채 양쪽 연결을 다시 준비합니다. 상대 기기의 새로고침은 누르지 않아도 됩니다."));
    }
    private void selectApps() {
        TreeMap<String,String> names=new TreeMap<>(); Intent launcher=new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
        for(ResolveInfo r:getPackageManager().queryIntentActivities(launcher,PackageManager.ResolveInfoFlags.of(0)))if(!r.activityInfo.packageName.equals(getPackageName()))names.put(r.activityInfo.packageName,r.loadLabel(getPackageManager()).toString());
        if(NotificationRelay.instance!=null)for(var n:NotificationRelay.instance.getActiveNotifications())names.putIfAbsent(n.getPackageName(),n.getPackageName());
        List<Map.Entry<String,String>> apps=new ArrayList<>(names.entrySet());apps.sort(Comparator.comparing(Map.Entry::getValue));
        Set<String> selected=new HashSet<>(getSharedPreferences("settings",MODE_PRIVATE).getStringSet("apps",Collections.emptySet()));
        String[] titles=new String[apps.size()];boolean[] checked=new boolean[apps.size()];
        for(int i=0;i<apps.size();i++){titles[i]=apps.get(i).getValue();checked[i]=selected.contains(apps.get(i).getKey());}
        new AlertDialog.Builder(this).setTitle(L("선택한 앱만 전달")).setMultiChoiceItems(titles,checked,(dialog,index,isChecked)->{String id=apps.get(index).getKey();if(isChecked)selected.add(id);else selected.remove(id);}).setPositiveButton(L("저장"),(d,w)->getSharedPreferences("settings",MODE_PRIVATE).edit().putStringSet("apps",selected).putBoolean("all_apps",false).apply()).setNegativeButton(L("취소"),null).show();
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
