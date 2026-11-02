package dev.foldbridge;

import android.app.*;
import android.appwidget.*;
import android.content.*;
import android.graphics.Color;
import android.os.*;
import android.view.*;
import android.widget.*;
import java.util.*;

/** Owner-operated widget binding/configuration; no vehicle command is sent during setup. */
public final class VehicleSettingsActivity extends Activity {
    private static final int BIND=41,CONFIGURE=42;
    private VehicleBridge bridge;
    private int pendingID=-1;
    private TextView status;
    private FrameLayout widget;
    private LinearLayout actions;
    private Switch enabled;
    private Button recover;
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final Runnable observer=()->handler.post(this::render);
    private String t(String value){return I18n.t(this,value);}
    private int dp(int value){return Math.round(value*getResources().getDisplayMetrics().density);}
    @Override public void onCreate(Bundle saved){
        super.onCreate(saved);bridge=VehicleBridge.get(this);
        if(saved!=null)pendingID=saved.getInt("pending_widget",-1);
        getWindow().setStatusBarColor(Color.rgb(9,15,21));getWindow().setNavigationBarColor(Color.rgb(9,15,21));
        ScrollView scroll=new ScrollView(this);scroll.setBackgroundColor(Color.rgb(9,15,21));
        LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setPadding(dp(22),dp(26),dp(22),dp(26));scroll.addView(root);setContentView(scroll);
        scroll.setOnApplyWindowInsetsListener((v,insets)->{var bars=insets.getInsets(WindowInsets.Type.systemBars());v.setPadding(bars.left,bars.top,bars.right,bars.bottom);return insets;});
        addText(root,"마이현대 차량 제어",23);
        addText(root,"공식 마이현대 위젯의 버튼을 워치에서 실행합니다. 로그인과 차량 인증은 마이현대에서 처리합니다.",14);
        enabled=new Switch(this);enabled.setText(t("워치 차량 제어"));enabled.setTextColor(Color.WHITE);root.addView(enabled);
        enabled.setOnCheckedChangeListener((button,checked)->{if(bridge.enabled()!=checked)bridge.setEnabled(checked);});
        status=addText(root,"",14);
        addButton(root,"마이현대 위젯 연결",this::chooseProvider);
        addButton(root,"위젯 차량·인증 설정",()->configure(bridge.widgetID(),false));
        recover=new Button(this);recover.setText(t("안내 닫고 버튼 복구"));
        recover.setOnClickListener(v->bridge.dismissNotice());root.addView(recover,new LinearLayout.LayoutParams(-1,dp(52)));
        addText(root,"공식 위젯",16);
        widget=new FrameLayout(this);root.addView(widget,new LinearLayout.LayoutParams(-1,dp(260)));
        addText(root,"워치에 표시할 버튼",17);
        addText(root,"아래 목록에서 사용할 버튼만 선택하세요. 위젯의 제어 버튼을 누르면 실제 차량 명령이 실행될 수 있습니다.",13);
        actions=new LinearLayout(this);actions.setOrientation(LinearLayout.VERTICAL);root.addView(actions);
        addText(root,"워치에서는 FoldBridge → 차량 제어를 엽니다. 마이현대가 휴대폰 인증을 요구하면 갤럭시에서 완료하세요. 실제 제어 결과는 마이현대 알림으로 확인합니다.",14);
        addButton(root,"차량 제어 연결 해제",()->new AlertDialog.Builder(this).setTitle(t("차량 제어 연결 해제"))
            .setMessage(t("FoldBridge에 연결한 위젯과 버튼 선택만 제거합니다."))
            .setPositiveButton(t("해제"),(d,w)->bridge.removeWidget()).setNegativeButton(t("취소"),null).show());
        bridge.start();render();
    }
    private TextView addText(LinearLayout root,String text,int size){TextView v=new TextView(this);v.setText(t(text));v.setTextSize(size);v.setTextColor(Color.rgb(224,235,240));v.setPadding(0,dp(12),0,dp(10));root.addView(v);return v;}
    private void addButton(LinearLayout root,String text,Runnable action){Button b=new Button(this);b.setAllCaps(false);b.setText(t(text));b.setOnClickListener(v->{try{action.run();}catch(RuntimeException error){Toast.makeText(this,t("마이현대 위젯 설정을 열지 못했습니다."),Toast.LENGTH_LONG).show();}});root.addView(b,new LinearLayout.LayoutParams(-1,dp(52)));}
    @Override protected void onStart(){super.onStart();bridge.addObserver(observer);bridge.start();render();}
    @Override protected void onStop(){bridge.removeObserver(observer);super.onStop();}
    @Override protected void onSaveInstanceState(Bundle state){state.putInt("pending_widget",pendingID);super.onSaveInstanceState(state);}
    private void chooseProvider(){
        List<AppWidgetProviderInfo> providers=bridge.providers();
        if(providers.isEmpty()){Toast.makeText(this,t("갤럭시 마이현대 앱을 설치하고 로그인한 뒤 다시 열어 주세요."),Toast.LENGTH_LONG).show();return;}
        String[] names=new String[providers.size()];for(int i=0;i<names.length;i++){
            String type=providers.get(i).provider.getClassName();
            names[i]=providers.get(i).loadLabel(getPackageManager())+" · "+t(type.contains("Small")?"작은 제어 위젯":type.contains("Medium")?"중간 제어 위젯":"전체 제어 위젯");
        }
        new AlertDialog.Builder(this).setTitle(t("마이현대 위젯 연결")).setItems(names,(dialog,index)->{
            if(pendingID!=-1)bridge.host.deleteAppWidgetId(pendingID);
            pendingID=bridge.host.allocateAppWidgetId();AppWidgetProviderInfo info=providers.get(index);
            if(AppWidgetManager.getInstance(this).bindAppWidgetIdIfAllowed(pendingID,info.provider))configure(pendingID,true);
            else startActivityForResult(new Intent(AppWidgetManager.ACTION_APPWIDGET_BIND)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,pendingID)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER,info.provider),BIND);
        }).setNegativeButton(t("취소"),null).show();
    }
    private void configure(int id,boolean newlyBound){
        AppWidgetProviderInfo info=AppWidgetManager.getInstance(this).getAppWidgetInfo(id);
        if(info==null){if(newlyBound)cancelPending();return;}
        if(info.configure!=null){
            // Configuration stays in Hyundai's own activity, including vehicle selection/authentication.
            try{bridge.host.startAppWidgetConfigureActivityForResult(this,id,0,CONFIGURE,null);}
            catch(ActivityNotFoundException error){if(newlyBound)cancelPending();Toast.makeText(this,t("마이현대 위젯 설정을 열지 못했습니다."),Toast.LENGTH_LONG).show();}
        }else if(newlyBound)finishBinding();
    }
    @Override protected void onActivityResult(int request,int result,Intent data){
        super.onActivityResult(request,result,data);
        if(request==BIND){if(result==RESULT_OK&&pendingID!=-1)configure(pendingID,true);else cancelPending();}
        else if(request==CONFIGURE){if(pendingID!=-1){if(result==RESULT_OK)finishBinding();else cancelPending();}render();}
    }
    private void finishBinding(){if(pendingID==-1)return;int id=pendingID;pendingID=-1;bridge.useWidget(id);render();}
    private void cancelPending(){if(pendingID!=-1){bridge.host.deleteAppWidgetId(pendingID);pendingID=-1;}render();}
    private void render(){
        if(status==null)return;
        enabled.setChecked(bridge.enabled());
        String message=switch(bridge.status()){
            case "ready"->"워치에서 사용할 준비가 됐습니다.";
            case "disabled"->"워치 차량 제어가 꺼져 있습니다.";
            case "needs_widget"->"마이현대 제어 위젯을 연결해 주세요.";
            case "choose_buttons"->"워치에서 사용할 버튼을 선택해 주세요.";
            case "result_pending"->"마이현대의 이전 요청 안내가 버튼을 가리고 있습니다. 안내를 닫고 다시 선택해 주세요.";
            case "loading"->"마이현대 위젯을 갱신하는 중입니다.";
            case "busy"->"마이현대 위젯이 앞선 요청을 처리 중입니다. 잠시 후 다시 눌러 주세요.";
            case "auth_required"->"마이현대 위젯에 인증 요청이 표시되었습니다. 갤럭시에서 완료해 주세요.";
            default->"마이현대 위젯의 제어 버튼을 읽지 못했습니다. 위젯을 다시 불러오거나 갤럭시 위젯 화면을 확인해 주세요.";
        };
        recover.setVisibility("result_pending".equals(bridge.status())?View.VISIBLE:View.GONE);
        status.setText(t(message));AppWidgetHostView hosted=bridge.widgetView();
        if(hosted!=null&&hosted.getParent()!=widget){
            if(hosted.getParent() instanceof ViewGroup parent)parent.removeView(hosted);
            widget.removeAllViews();widget.addView(hosted,new FrameLayout.LayoutParams(-1,-1));
        }else if(hosted==null)widget.removeAllViews();
        actions.removeAllViews();Set<String> selected=bridge.selected();
        for(VehicleBridge.Control control:bridge.controls()){
            CheckBox check=new CheckBox(this);check.setText(control.label());check.setTextColor(Color.WHITE);check.setChecked(selected.contains(control.id()));
            check.setOnCheckedChangeListener((button,value)->bridge.select(control.id(),value));actions.addView(check);
        }
    }
}
