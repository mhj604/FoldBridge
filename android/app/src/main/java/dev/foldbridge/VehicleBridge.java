package dev.foldbridge;

import android.appwidget.*;
import android.content.*;
import android.os.*;
import android.view.*;
import android.widget.*;
import org.json.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.Pattern;

/** Hosts the owner's official widget; never reads Hyundai credentials or calls private APIs. */
final class VehicleBridge {
    static final String PACKAGE="com.hyundai.oneapp.kr";
    private static final int HOST_ID=47110;
    private static final Pattern CONTROL=Pattern.compile("시동|공조|잠금|잠그|열림|문 열|문열|문 닫|문닫|비상등|경적|충전|창문|트렁크|새로|상태|engine|start|stop|climate|lock|unlock|horn|light|charg|window|trunk|refresh|status",Pattern.CASE_INSENSITIVE);
    private static final Pattern AUTH=Pattern.compile("로그인.{0,40}(필요|해주세요|해 주세요)|인증.{0,40}(필요|해주세요|해 주세요)|비밀번호.{0,20}입력|PIN.{0,20}(입력|enter)|sign in to|log in to|authentication required",Pattern.CASE_INSENSITIVE);
    private static final Pattern PROGRESS=Pattern.compile("(처리|실행|제어|요청|불러오는|업데이트) ?중|please wait|in progress|loading",Pattern.CASE_INSENSITIVE);
    private static final Pattern RESULT=Pattern.compile("완료|승인|성공|실패|오류|접수|거절|complete|approved|success|fail|error|accepted|rejected",Pattern.CASE_INSENSITIVE);
    private static final Pattern QUESTION=Pattern.compile("하시겠|할까요|습니까[?？]|are you sure|do you want to|confirm (the )?(start|stop|lock|unlock)",Pattern.CASE_INSENSITIVE);
    private static VehicleBridge shared;
    static VehicleBridge get(Context context){if(shared==null)shared=new VehicleBridge(context.getApplicationContext());return shared;}
    private final Context context;
    private final SharedPreferences prefs;
    final AppWidgetHost host;
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final Set<Runnable> observers=new HashSet<>();
    private final LinkedHashMap<String,Control> controls=new LinkedHashMap<>();
    private final LinkedHashSet<String> handled=new LinkedHashSet<>();
    private final Set<String> ambiguousControls=new HashSet<>();
    private HostedView view;
    private View noticeDismiss;
    private String revision=UUID.randomUUID().toString(),fingerprint="";
    private boolean listening,updating,hostAvailable=true,authVisible,progressVisible,refreshPending;
    private int remoteUpdates,refreshRequests;
    private long lastRefresh=-15000;
    private String lastResult="";
    private long lastCommand=-3000;
    record Control(String id,String label,View target) {}
    private VehicleBridge(Context context){
        this.context=context;prefs=context.getSharedPreferences("vehicle",Context.MODE_PRIVATE);
        host=new AppWidgetHost(context,HOST_ID){
            @Override protected AppWidgetHostView onCreateView(Context c,int id,AppWidgetProviderInfo info){return new HostedView(c);}
        };
        try {JSONArray ids=new JSONArray(prefs.getString("handled","[]"));for(int i=0;i<ids.length();i++)handled.add(ids.getString(i));}catch(JSONException ignored){}
    }
    int widgetID(){return prefs.getInt("widget_id",-1);}
    boolean enabled(){return prefs.getBoolean("enabled",false);}
    void setEnabled(boolean value){prefs.edit().putBoolean("enabled",value).apply();changed();}
    private AppWidgetProviderInfo provider(){
        AppWidgetProviderInfo info=AppWidgetManager.getInstance(context).getAppWidgetInfo(widgetID());
        return info!=null&&PACKAGE.equals(info.provider.getPackageName())?info:null;
    }
    void start(){
        if(widgetID()==-1)return;
        if(!listening){try{host.startListening();listening=true;hostAvailable=true;}catch(RuntimeException error){hostAvailable=false;return;}}
        if(view==null&&provider()!=null){
            view=(HostedView)host.createView(context,widgetID(),provider());
            view.updateAppWidgetSize(new Bundle(),List.of(new android.util.SizeF(344,244)));
            view.post(this::scan);
            handler.postDelayed(this::scan,500);
        }
    }
    void addObserver(Runnable observer){observers.add(observer);}
    void removeObserver(Runnable observer){observers.remove(observer);}
    AppWidgetHostView widgetView(){start();return view;}
    List<AppWidgetProviderInfo> providers(){
        List<AppWidgetProviderInfo> result=new ArrayList<>();
        for(AppWidgetProviderInfo info:AppWidgetManager.getInstance(context).getInstalledProviders())
            if(PACKAGE.equals(info.provider.getPackageName())&&!info.provider.getClassName().contains("Location"))result.add(info);
        return result;
    }
    void useWidget(int id){
        AppWidgetProviderInfo info=AppWidgetManager.getInstance(context).getAppWidgetInfo(id);
        if(info==null||!PACKAGE.equals(info.provider.getPackageName()))throw new IllegalArgumentException("Unexpected widget provider");
        int previous=widgetID();
        if(view!=null&&view.getParent() instanceof ViewGroup parent)parent.removeView(view);
        view=null;controls.clear();fingerprint="";revision=UUID.randomUUID().toString();
        prefs.edit().putInt("widget_id",id).putBoolean("enabled",true).remove("selected").apply();
        if(previous!=-1&&previous!=id)host.deleteAppWidgetId(previous);
        start();changed();
    }
    void removeWidget(){
        int id=widgetID();prefs.edit().remove("widget_id").remove("selected").putBoolean("enabled",false).apply();
        if(view!=null&&view.getParent() instanceof ViewGroup parent)parent.removeView(view);
        view=null;controls.clear();fingerprint="";revision=UUID.randomUUID().toString();
        if(id!=-1)host.deleteAppWidgetId(id);changed();
    }
    List<Control> controls(){return new ArrayList<>(controls.values());}
    Set<String> selected(){return new HashSet<>(prefs.getStringSet("selected",Collections.emptySet()));}
    void select(String id,boolean value){Set<String> selected=selected();if(value)selected.add(id);else selected.remove(id);prefs.edit().putStringSet("selected",selected).apply();revision=UUID.randomUUID().toString();changed();}
    String status(){
        if(!enabled())return "disabled";
        if(provider()==null)return "needs_widget";
        if(!hostAvailable)return "unavailable";
        if(updating)return "loading";
        if(authVisible)return "auth_required";
        if(noticeDismiss!=null)return "result_pending";
        if(progressVisible)return "busy";
        if(controls.isEmpty())return refreshPending?"loading":"no_controls";
        Set<String> selected=selected();boolean disabled=false;
        for(Control c:controls.values())if(selected.contains(c.id())){
            if(c.target().isEnabled())return "ready";disabled=true;
        }
        return disabled?"busy":"choose_buttons";
    }
    JSONObject catalogue(){
        start();scan();
        if(enabled()&&!authVisible&&!progressVisible&&noticeDismiss==null&&controls.isEmpty())requestWidgetUpdate();
        writeDiagnostics();
        JSONArray actions=new JSONArray();
        if("ready".equals(status())){Set<String> selected=selected();for(Control c:controls.values())if(selected.contains(c.id())&&c.target().isEnabled())actions.put(BridgeService.object("id",c.id(),"label",c.label()));}
        return BridgeService.object("type","vehicle_catalogue","status",status(),"revision",revision,"actions",actions);
    }
    JSONObject execute(JSONObject request){
        scan();
        String requestID=request.optString("id"),action=request.optString("action");
        String result="unavailable";
        if(!requestID.matches("[0-9a-fA-F-]{36}"))result="invalid";
        else if(handled.contains(requestID))result="duplicate";
        else if("dismiss_notice".equals(action)){
            if(!revision.equals(request.optString("revision")))result="stale";
            else if(noticeDismiss==null)result=status();
            else {
                handled.add(requestID);while(handled.size()>64)handled.remove(handled.iterator().next());
                if(!prefs.edit().putString("handled",new JSONArray(handled).toString()).commit())result="unavailable";
                else result=dismissNotice()?"notice_dismissed":"unavailable";
            }
        }
        else if(!"ready".equals(status()))result=status();
        else if(!revision.equals(request.optString("revision")))result="stale";
        else if(!selected().contains(action)||!controls.containsKey(action))result="stale";
        else if(SystemClock.elapsedRealtime()-lastCommand<3000)result="busy";
        else {
            Control control=controls.get(action);
            if(control.target().isEnabled()&&control.target().hasOnClickListeners()){
                // Reserve before invoking. A lost BLE reply must never replay a car command.
                handled.add(requestID);while(handled.size()>64)handled.remove(handled.iterator().next());
                if(!prefs.edit().putString("handled",new JSONArray(handled).toString()).commit())result="unavailable";
                else {
                    lastCommand=SystemClock.elapsedRealtime();
                    try {result=control.target().performClick()?"widget_invoked":"unavailable";}
                    catch(RuntimeException error){result="unavailable";}
                }
            }else result="busy";
        }
        lastResult=result;writeDiagnostics();
        // Invoking the official widget is not evidence of vehicle success. Its own
        // authentication UI and result notifications remain the authority.
        return BridgeService.object("type","vehicle_result","id",requestID,"status",result);
    }
    private final class HostedView extends AppWidgetHostView {
        HostedView(Context context){super(context);}
        @Override public void updateAppWidget(RemoteViews remoteViews){
            remoteUpdates++;updating=true;refreshPending=false;super.updateAppWidget(remoteViews);
            handler.post(()->{if(this!=view)return;updating=false;scan();});
            for(long delay:new long[]{250,1000,3000})handler.postDelayed(()->{if(this==view)scan();},delay);
        }
    }
    private void scan(){
        if(view==null)return;
        // Responsive RemoteViews can choose/reapply a layout during onLayout.
        // The hosted widget must also receive a layout pass while its settings screen is hidden.
        if(!view.isShown()){
            int width=Math.round(360*context.getResources().getDisplayMetrics().density);
            int height=Math.round(260*context.getResources().getDisplayMetrics().density);
            view.measure(View.MeasureSpec.makeMeasureSpec(width,View.MeasureSpec.EXACTLY),View.MeasureSpec.makeMeasureSpec(height,View.MeasureSpec.EXACTLY));
            view.layout(0,0,width,height);
        }
        authVisible=false;progressVisible=false;inspectState(view);
        // The official widget uses the same acknowledgement screen for success,
        // approval and failure. Find its unique acknowledgement, not one body string.
        noticeDismiss=null;
        String text=visibleText(view);
        if(!authVisible&&!QUESTION.matcher(text).find()&&(!progressVisible||RESULT.matcher(text).find())){
            List<View> matches=new ArrayList<>();findNoticeDismiss(view,matches);
            if(matches.size()==1)noticeDismiss=matches.get(0);
        }
        LinkedHashMap<String,Control> found=new LinkedHashMap<>();ambiguousControls.clear();
        // Message containers may themselves be clickable and contain words such as
        // "engine start". They are not vehicle controls while the notice is shown.
        if(noticeDismiss==null)collect(view,found);
        migrateSelected(found);
        StringBuilder signature=new StringBuilder();signature.append(authVisible).append(progressVisible).append(refreshPending).append(noticeDismiss!=null);
        for(Control c:found.values())signature.append(c.id()).append(':').append(c.target().isEnabled()).append('\n');
        controls.clear();controls.putAll(found);String next=signature.toString();
        if(!next.equals(fingerprint)){fingerprint=next;revision=UUID.randomUUID().toString();changed();}
        else for(Runnable observer:new ArrayList<>(observers))observer.run();
        writeDiagnostics();
    }
    private void inspectState(View node){
        if(node.getVisibility()!=View.VISIBLE)return;
        if(node instanceof ProgressBar)progressVisible=true;
        CharSequence text=node instanceof TextView t?t.getText():node.getContentDescription();
        if(text!=null){String value=text.toString();authVisible|=AUTH.matcher(value).find();progressVisible|=PROGRESS.matcher(value).find();}
        if(node instanceof ViewGroup group)for(int i=0;i<group.getChildCount();i++)inspectState(group.getChildAt(i));
    }
    boolean dismissNotice(){
        View target=noticeDismiss;
        if(target==null||!target.isEnabled()||!target.hasOnClickListeners())return false;
        try{
            boolean invoked=target.performClick();
            if(invoked){handler.postDelayed(this::scan,250);handler.postDelayed(this::scan,1000);}
            return invoked;
        }catch(RuntimeException error){return false;}
    }
    private String visibleText(View node){
        if(node.getVisibility()!=View.VISIBLE)return "";
        StringBuilder text=new StringBuilder();
        if(node instanceof TextView t)text.append(t.getText()).append(' ');
        if(node instanceof ViewGroup group)for(int i=0;i<group.getChildCount();i++)text.append(visibleText(group.getChildAt(i))).append(' ');
        return text.toString().replaceAll("\\s+"," ").trim();
    }
    private boolean findNoticeDismiss(View node,List<View> matches){
        if(node.getVisibility()!=View.VISIBLE)return false;
        boolean descendant=false;
        if(node instanceof ViewGroup group)for(int i=0;i<group.getChildCount();i++)descendant|=findNoticeDismiss(group.getChildAt(i),matches);
        if(!descendant&&node.isEnabled()&&node.hasOnClickListeners()&&Set.of("확인","닫기","ok","close").contains(visibleText(node).toLowerCase(Locale.ROOT))){matches.add(node);return true;}
        return descendant;
    }
    private void requestWidgetUpdate(){
        AppWidgetProviderInfo info=provider();long current=SystemClock.elapsedRealtime();
        if(info==null||refreshPending||current-lastRefresh<15000)return;
        lastRefresh=current;refreshPending=true;refreshRequests++;
        try{context.sendBroadcast(new Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).setComponent(info.provider)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS,new int[]{widgetID()}));}
        catch(RuntimeException error){refreshPending=false;}
        handler.postDelayed(()->{refreshPending=false;scan();changed();},10000);
    }
    private void writeDiagnostics(){
        int runnable=0,currentSelected=0;Set<String> saved=selected();
        for(Control c:controls.values()){if(c.target().isEnabled())runnable++;if(saved.contains(c.id()))currentSelected++;}
        JSONObject state=BridgeService.object("updatedAt",System.currentTimeMillis(),"status",status(),"bound",provider()!=null,
            "controls",controls.size(),"runnable",runnable,"selected",selected().size(),"selectedCurrent",currentSelected,"remoteUpdates",remoteUpdates,
            "refreshRequests",refreshRequests,"authVisible",authVisible,"progressVisible",progressVisible,"noticeDismissAvailable",noticeDismiss!=null,"lastResult",lastResult);
        java.io.File folder=context.getExternalFilesDir(null);if(folder==null)return;
        try(java.io.FileOutputStream out=new java.io.FileOutputStream(new java.io.File(folder,"foldbridge-vehicle-status.json"))){
            out.write(state.toString().getBytes(StandardCharsets.UTF_8));
        }catch(java.io.IOException ignored){}
    }
    private boolean collect(View node,Map<String,Control> result){
        if(node.getVisibility()!=View.VISIBLE)return false;
        boolean descendant=false;
        if(node instanceof ViewGroup group)for(int i=0;i<group.getChildCount();i++)descendant|=collect(group.getChildAt(i),result);
        if(!node.hasOnClickListeners())return descendant;
        if(descendant)return true;
        String label=label(node).replaceAll("\\s+"," ").trim();
        if(node.getId()!=View.NO_ID&&!label.isEmpty()&&label.length()<=80&&CONTROL.matcher(label).find()){
            // Glance assigns different view IDs when its message/control layouts change.
            // Bind to a unique exact label within this widget, never to a transient view ID.
            String id=controlID(widgetID()+":label:"+label);
            if(result.containsKey(id)){result.remove(id);ambiguousControls.add(id);}
            else if(!ambiguousControls.contains(id)&&result.size()<12)result.put(id,new Control(id,label,node));
            return true;
        }
        return descendant;
    }
    private String controlID(String material){
        return Base64.getUrlEncoder().withoutPadding().encodeToString(Crypto.digest(material.getBytes(StandardCharsets.UTF_8)));
    }
    private void migrateSelected(Map<String,Control> current){
        Set<String> saved=selected();boolean changed=false;
        if(saved.isEmpty()||current.keySet().containsAll(saved))return;
        for(Control control:current.values()){
            if(saved.contains(control.id()))continue;
            Set<Integer> previousIDs=new HashSet<>();previousIDs.add(control.target().getId());
            // Earlier Glance layouts used generated child IDs in this range. Match
            // the original digest and exact current label; never infer from count/order.
            for(int id=1;id<=1024;id++)previousIDs.add(id);
            for(int id:previousIDs){
                String legacy=controlID(widgetID()+":"+id+":"+control.label());
                if(saved.remove(legacy)){saved.add(control.id());changed=true;}
            }
        }
        if(changed)prefs.edit().putStringSet("selected",saved).apply();
    }
    private String label(View node){
        if(node.getVisibility()!=View.VISIBLE)return "";
        CharSequence description=node.getContentDescription();
        if(description!=null&&!description.toString().isBlank())return description.toString();
        if(node instanceof TextView text&&text.getText()!=null)return text.getText().toString();
        StringBuilder result=new StringBuilder();
        if(node instanceof ViewGroup group)for(int i=0;i<group.getChildCount();i++){
            String part=label(group.getChildAt(i));if(!part.isBlank()){if(result.length()>0)result.append(' ');result.append(part);}
        }
        return result.toString();
    }
    private void changed(){writeDiagnostics();for(Runnable observer:new ArrayList<>(observers))observer.run();BridgeService.vehicleChanged();}
}
