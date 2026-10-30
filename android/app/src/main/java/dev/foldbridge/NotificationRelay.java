package dev.foldbridge;

import android.app.Notification;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.os.SystemClock;
import android.service.notification.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public final class NotificationRelay extends NotificationListenerService {
    static volatile NotificationRelay instance;
    static volatile long received=0, forwarded=0;
    private static long lastRebind=-15000;
    static boolean hasAccess(Context context) {
        return context.getSystemService(NotificationManager.class).isNotificationListenerAccessGranted(new ComponentName(context,NotificationRelay.class));
    }
    static void reconnectIfAllowed(Context context) {
        if(instance!=null||!hasAccess(context)||SystemClock.elapsedRealtime()-lastRebind<15000)return;
        lastRebind=SystemClock.elapsedRealtime();requestRebind(new ComponentName(context,NotificationRelay.class));
    }
    @Override public void onListenerConnected() {instance=this;android.util.Log.i("FoldBridge","notification_listener_connected");replayActive();BridgeService.recordState(this);}
    @Override public void onListenerDisconnected() {
        instance=null;
        android.util.Log.i("FoldBridge","notification_listener_disconnected");
        requestRebind(new android.content.ComponentName(this,NotificationRelay.class));
        BridgeService.recordState(this);
    }
    @Override public void onDestroy() {if(instance==this)instance=null;super.onDestroy();}
    static void replayActive() {
        NotificationRelay listener=instance;
        if(listener==null||BridgeService.instance==null)return;
        try {
            for(StatusBarNotification sbn:listener.getActiveNotifications()) {
                if(System.currentTimeMillis()-sbn.getPostTime()<24L*60*60*1000)listener.forward(sbn,sbn.getPostTime());
            }
        } catch(RuntimeException error){BridgeService.error="현재 알림을 읽지 못했습니다. Local 앱의 알림 접근 권한을 확인하세요.";}
    }
    @Override public void onNotificationPosted(StatusBarNotification sbn) {
        if(!sbn.getPackageName().equals(getPackageName())&&!sbn.getPackageName().equals("dev.foldbridge")) {
            received++;android.util.Log.i("FoldBridge","notification_received count="+received);
        }
        forward(sbn,System.currentTimeMillis());
    }
    private void forward(StatusBarNotification sbn,long postedAt) {
        if(BridgeService.instance==null||sbn.getPackageName().equals(getPackageName())||sbn.getPackageName().equals("dev.foldbridge"))return;
        Notification n=sbn.getNotification();
        String id=hex(Crypto.digest(sbn.getKey().getBytes(StandardCharsets.UTF_8))).substring(0,32);
        boolean chargingStatus=sbn.getPackageName().equals("com.android.systemui")&&
            ("charging_state".equals(sbn.getTag())||("CHR".equals(n.getChannelId())&&Notification.CATEGORY_SYSTEM.equals(n.category)&&(n.flags&Notification.FLAG_ONGOING_EVENT)!=0));
        if(chargingStatus&&!getSharedPreferences("settings",MODE_PRIVATE).getBoolean("forward_charging_status",false)) {
            BridgeService.discardPending(id);return;
        }
        Set<String> allowed=getSharedPreferences("settings",MODE_PRIVATE).getStringSet("apps",Collections.emptySet());
        if(!getSharedPreferences("settings",MODE_PRIVATE).getBoolean("all_apps",true)&&!allowed.contains(sbn.getPackageName()))return;
        String title=text(n.extras.getCharSequence(Notification.EXTRA_TITLE),160), body=text(n.extras.getCharSequence(Notification.EXTRA_BIG_TEXT),1200);
        if(body.isEmpty())body=text(n.extras.getCharSequence(Notification.EXTRA_TEXT),1200);
        String app=sbn.getPackageName();
        try{app=getPackageManager().getApplicationLabel(getPackageManager().getApplicationInfo(app,0)).toString();}catch(Exception ignored){}
        if(title.isEmpty()&&body.isEmpty())title="내용 없는 알림";
        String rev=hex(Crypto.digest((title+"\n"+body).getBytes(StandardCharsets.UTF_8))).substring(0,32);
        var message=BridgeService.object("type","notification","id",id,"rev",rev,"app",text(app,80),"app_id",sbn.getPackageName(),"title",title,"body",body,"posted_at",postedAt);
        AppIcons.Artwork artwork=AppIcons.get(this,sbn.getPackageName());
        if(artwork!=null)try {message.put("icon_key",artwork.key());message.put("icon_png",artwork.png());}catch(org.json.JSONException ignored){}
        BridgeService.enqueue(message);
        forwarded++;
    }
    private static String text(CharSequence value,int max) {
        String s=value==null?"":value.toString(); int end=Math.min(s.length(),max);
        if(end>0&&Character.isHighSurrogate(s.charAt(end-1)))end--;
        return s.substring(0,end);
    }
    static String hex(byte[] data) {StringBuilder out=new StringBuilder();for(byte b:data)out.append(String.format(Locale.ROOT,"%02x",b&255));return out.toString();}
}
