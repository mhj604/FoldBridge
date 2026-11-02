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
    private static VehicleBridge shared;
    static VehicleBridge get(Context context){if(shared==null)shared=new VehicleBridge(context.getApplicationContext());return shared;}
    private final Context context;
    private final SharedPreferences prefs;
    final AppWidgetHost host;
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final Set<Runnable> observers=new HashSet<>();
    private final LinkedHashMap<String,Control> controls=new LinkedHashMap<>();
    private final LinkedHashSet<String> handled=new LinkedHashSet<>();
    private HostedView view;
    private String revision=UUID.randomUUID().toString(),fingerprint="";
    private boolean listening,updating,hostAvailable=true;
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
            view.updateAppWidgetSize(null,300,120,360,260);
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
        if(controls.isEmpty())return "no_controls";
        Set<String> selected=selected();for(String id:controls.keySet())if(selected.contains(id))return "ready";
        return "choose_buttons";
    }
    JSONObject catalogue(){
        JSONArray actions=new JSONArray();
        if("ready".equals(status())){Set<String> selected=selected();for(Control c:controls.values())if(selected.contains(c.id()))actions.put(BridgeService.object("id",c.id(),"label",c.label()));}
        return BridgeService.object("type","vehicle_catalogue","status",status(),"revision",revision,"actions",actions);
    }
    JSONObject execute(JSONObject request){
        String requestID=request.optString("id"),action=request.optString("action");
        String result="unavailable";
        if(!requestID.matches("[0-9a-fA-F-]{36}"))result="invalid";
        else if(handled.contains(requestID))result="duplicate";
        else if(!"ready".equals(status()))result="not_ready";
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
            }
        }
        // Invoking the official widget is not evidence of vehicle success. Its own
        // authentication UI and result notifications remain the authority.
        return BridgeService.object("type","vehicle_result","id",requestID,"status",result);
    }
    private final class HostedView extends AppWidgetHostView {
        HostedView(Context context){super(context);}
        @Override public void updateAppWidget(RemoteViews remoteViews){
            updating=true;super.updateAppWidget(remoteViews);
            handler.post(()->{if(this!=view)return;updating=false;scan();});
        }
    }
    private void scan(){
        if(view==null)return;
        LinkedHashMap<String,Control> found=new LinkedHashMap<>();collect(view,found);
        StringBuilder signature=new StringBuilder();for(Control c:found.values())signature.append(c.id()).append('\n');
        controls.clear();controls.putAll(found);String next=signature.toString();
        if(!next.equals(fingerprint)){fingerprint=next;revision=UUID.randomUUID().toString();changed();}
        else for(Runnable observer:new ArrayList<>(observers))observer.run();
    }
    private boolean collect(View node,Map<String,Control> result){
        if(node.getVisibility()!=View.VISIBLE)return false;
        boolean descendant=false;
        if(node instanceof ViewGroup group)for(int i=0;i<group.getChildCount();i++)descendant|=collect(group.getChildAt(i),result);
        if(!node.hasOnClickListeners()||!node.isEnabled())return descendant;
        if(descendant)return true;
        String label=label(node).replaceAll("\\s+"," ").trim();
        if(node.getId()!=View.NO_ID&&!label.isEmpty()&&label.length()<=80&&CONTROL.matcher(label).find()){
            String material=widgetID()+":"+node.getId()+":"+label;
            String id=Base64.getUrlEncoder().withoutPadding().encodeToString(Crypto.digest(material.getBytes(StandardCharsets.UTF_8)));
            if(result.size()<12)result.put(id,new Control(id,label,node));
        }
        return true;
    }
    private String label(View node){
        CharSequence description=node.getContentDescription();
        if(description!=null&&!description.toString().isBlank())return description.toString();
        if(node instanceof TextView text&&text.getText()!=null)return text.getText().toString();
        StringBuilder result=new StringBuilder();
        if(node instanceof ViewGroup group)for(int i=0;i<group.getChildCount();i++){
            String part=label(group.getChildAt(i));if(!part.isBlank()){if(result.length()>0)result.append(' ');result.append(part);}
        }
        return result.toString();
    }
    private void changed(){for(Runnable observer:new ArrayList<>(observers))observer.run();BridgeService.vehicleChanged();}
}
