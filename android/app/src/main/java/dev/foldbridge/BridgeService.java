package dev.foldbridge;

import android.Manifest;
import android.app.*;
import android.bluetooth.*;
import android.bluetooth.le.*;
import android.content.*;
import android.os.*;
import android.content.pm.PackageManager;
import org.json.*;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.util.*;

public final class BridgeService extends Service {
    // Retry only within the current authenticated connection; never replay an offline backlog.
    private static final long DELIVERY_RETENTION_MILLIS=24L*60*60*1000;
    private static final int MAX_PENDING=1024;
    public static final UUID SERVICE=UUID.fromString("c62d0200-7de5-4c34-a432-7c838e687a40"), TX=UUID.fromString("c62d0201-7de5-4c34-a432-7c838e687a40"), RX=UUID.fromString("c62d0202-7de5-4c34-a432-7c838e687a40"), CCC=UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
    static volatile BridgeService instance;
    static boolean isConnected(){BridgeService service=instance;return service!=null&&service.authenticated;}
    static volatile String status="중지됨", pairingCode="", error="";
    static volatile long acknowledged=0, apnsAccepted=0, lastRtt=-1;
    static volatile int waiting=0;
    private static String recordedState="";
    static void recordState(Context context) {
        BridgeService s=instance;
        JSONObject state=object("build",25,"bridgeRunning",s!=null,"status",status,"error",error,
            "centralPresent",s!=null&&s.central!=null,"subscribed",s!=null&&s.subscribed,
            "mtu",s==null?23:s.mtu,"queuedFrames",s==null?0:s.outgoing.size(),"queuedMessages",s==null?0:s.messages.size(),
            "softRefreshCount",s==null?0:s.softRefreshCount,"disconnectCount",s==null?0:s.disconnectCount,"lastDisconnectReason",s==null?"":s.lastDisconnectReason,
            "sessionGeneration",s==null?0:s.generation,"refreshCount",s==null?0:s.refreshCount,"stage",s==null?"idle":s.stage,
            "authenticated",s!=null&&s.authenticated,"watchActive",s!=null&&s.watchActive,
            "advertising",s!=null&&s.advertisements!=null,
            "observedLinks",s==null?0:s.observedLinks,"subscriptionClaims",s==null?0:s.subscriptionClaims,
            "retainedSubscriptionClaims",s==null?0:s.retainedSubscriptionClaims,
            "bootstrapSent",s==null?0:s.bootstrapSent,"discoveryRefreshes",s==null?0:s.discoveryRefreshes,
            "rejectedCharacteristicWrites",s==null?0:s.rejectedCharacteristicWrites,
            "staleLinkRecoveries",s==null?0:s.staleLinkRecoveries,"maintenanceAt",s==null?0:s.maintenanceAt,
            "connectionStartedAt",s==null?0:s.connectionStartedAt,
            "listenerAccess",NotificationRelay.hasAccess(context),"listenerBound",NotificationRelay.instance!=null,
            "received",NotificationRelay.received,"forwarded",NotificationRelay.forwarded,
            "acknowledged",acknowledged,"pending",waiting);
        String comparable=state.toString();if(comparable.equals(recordedState))return;
        try {
            state.put("updatedAt",System.currentTimeMillis());
            java.io.File folder=context.getExternalFilesDir(null);if(folder==null)return;
            try(java.io.FileOutputStream out=new java.io.FileOutputStream(new java.io.File(folder,"foldbridge-status.json"))) {
                out.write(state.toString().getBytes(StandardCharsets.UTF_8));
            }
            recordedState=comparable;
        } catch(Exception ignored) {}
    }
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final Frames frames=new Frames(); private final Frames.Assembler assembler=new Frames.Assembler();
    private final ArrayDeque<byte[]> outgoing=new ArrayDeque<>();
    private final ArrayDeque<byte[]> messages=new ArrayDeque<>();
    private final LinkedHashMap<String,Delivery> pending=new LinkedHashMap<>();
    private final Set<String> acknowledgedIcons=new HashSet<>();
    private BluetoothGattServer server; private BluetoothGattCharacteristic tx;
    private BluetoothLeAdvertiser advertiser; private BluetoothDevice central;
    private final Map<String,Integer> linkMtus=new HashMap<>();
    private static final class ResumeProbe {
        final Frames.Assembler frames=new Frames.Assembler();
        final long started=SystemClock.elapsedRealtime();
        int bytes;
    }
    private final Map<String,ResumeProbe> resumeProbes=new LinkedHashMap<>();
    private int observedLinks=0, subscriptionClaims=0, staleLinkRecoveries=0;
    private int retainedSubscriptionClaims=0, rejectedCharacteristicWrites=0;
    private int bootstrapSent=0, discoveryRefreshes=0;
    private long maintenanceAt=0;
    private volatile long indicationTicket=0;
    private int indicationGeneration;
    private byte[] indicationPacket;
    private int softRefreshCount=0;
    private String lastDisconnectReason="";
    private int disconnectCount=0;
    private int bluetoothRetries=0, bluetoothEpoch=0, refreshCount=0;
    private AdvertiseCallback advertisements;
    private final Runnable bluetoothRetry=()->{if(server==null)startBluetooth();};
    private final Runnable advertisingRetry=()->startAdvertising();
    private final Runnable connectionMaintenance=new Runnable(){@Override public void run(){
        if(instance!=BridgeService.this)return;
        try {
            BluetoothManager manager=getSystemService(BluetoothManager.class);
            BluetoothAdapter adapter=manager.getAdapter();
            if(adapter!=null&&adapter.isEnabled()) {
                if(server==null)startBluetooth();
                else {
                    // Inspect local stack state only: no heartbeat indications or
                    // extra watch background wakeups for a healthy idle link.
                    if(central!=null&&manager.getConnectionState(central,BluetoothProfile.GATT)==BluetoothProfile.STATE_DISCONNECTED) {
                        staleLinkRecoveries++;clearSession();status="워치 연결 대기 중";
                    }
                    if(central==null)startAdvertising();
                }
            }
        } catch(SecurityException ignored) {
        } catch(RuntimeException error) {android.util.Log.i("FoldBridgeConnection","local_connection_check_failed");}
        maintenanceAt=System.currentTimeMillis();recordState(BridgeService.this);
        handler.postDelayed(this,15000);
    }};
    private Vault vault; private KeyPair identity; private Crypto.Session session;
    private long connectionStartedAt=0;
    private Delivery activeDelivery;
    private byte[] ownNonce, peerPublic, peerCommit;
    private boolean subscribed=false, inFlight=false, localConfirmed=false, remoteConfirmed=false, authenticated=false, watchActive=false;
    private int mtu=23, generation=0, failures=0; private long pairUntil=0, blockedUntil=0;
    private String stage="idle";
    private static final class Delivery {
        final JSONObject message; final long queuedAt;
        int bleAttempts=0;
        boolean iconSent=false, waitingForWake=false;
        Delivery(JSONObject message){this.message=message;this.queuedAt=SystemClock.elapsedRealtime()-Math.max(0,System.currentTimeMillis()-message.optLong("posted_at",System.currentTimeMillis()));}
    }
    private static String b64(byte[] b) { return Base64.getEncoder().encodeToString(b); }
    private static byte[] unb64(String s) { return Base64.getDecoder().decode(s); }
    static JSONObject object(Object... pairs) { JSONObject o=new JSONObject(); try { for(int i=0;i<pairs.length;i+=2)o.put((String)pairs[i],pairs[i+1]); } catch(JSONException e) { throw new IllegalArgumentException(e); } return o; }
    @Override public void onCreate() {
        super.onCreate(); instance=this;
        try {
            vault=new Vault(this); identity=vault.identity();
            // Migrate old releases without reading or replaying saved messages.
            vault.remove("outbox");vault.remove("first_pair_cutoff");waiting=0;
        }
        catch(Exception e) { fail("보안 키를 준비하지 못했습니다."); stopSelf(); }
        if(vault!=null)VehicleBridge.get(this).start();
    }
    @Override public int onStartCommand(Intent intent,int flags,int startId) {
        if(vault==null) return START_NOT_STICKY;
        if(!getSharedPreferences("settings",MODE_PRIVATE).getBoolean("connection_enabled",false)) {stopSelf();return START_NOT_STICKY;}
        if(checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED || checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE)!=PackageManager.PERMISSION_GRANTED) { fail("근처 기기 권한이 필요합니다."); stopSelf(); return START_NOT_STICKY; }
        updateConnectionNotification();
        if("pair".equals(intent==null?null:intent.getAction())) { pairUntil=SystemClock.elapsedRealtime()+120000; error=""; }
        if("refresh".equals(intent==null?null:intent.getAction()))refreshBluetooth();
        else if(server==null)startBluetooth();
        handler.removeCallbacks(connectionMaintenance);handler.postDelayed(connectionMaintenance,15000);
        flush();
        handler.post(NotificationRelay::replayActive);
        NotificationRelay.reconnectIfAllowed(this);
        handler.post(()->recordState(this));
        return START_STICKY;
    }
    private void updateConnectionNotification() {
        NotificationManager manager=getSystemService(NotificationManager.class);
        manager.createNotificationChannel(new NotificationChannel("connection",I18n.t(this,"워치 연결 상태"),NotificationManager.IMPORTANCE_LOW));
        PendingIntent open=PendingIntent.getActivity(this,0,new Intent(this,MainActivity.class),PendingIntent.FLAG_IMMUTABLE);
        startForeground(10,new Notification.Builder(this,"connection").setSmallIcon(android.R.drawable.stat_sys_data_bluetooth).setContentTitle(I18n.t(this,"FoldBridge Local 실행 중")).setContentText(I18n.t(this,"Bluetooth로 애플워치 알림을 전달합니다")).setOngoing(true).setContentIntent(open).build());
    }
    @Override public void onConfigurationChanged(android.content.res.Configuration configuration) {
        super.onConfigurationChanged(configuration);updateConnectionNotification();
    }
    void resumeBluetooth() {handler.post(()->{if(server==null)startBluetooth();});}
    private void stopBluetooth() {
        bluetoothEpoch++;
        handler.removeCallbacks(bluetoothRetry);
        handler.removeCallbacks(advertisingRetry);
        BluetoothDevice previous=central;
        clearSession();
        linkMtus.clear();
        stopAdvertising();
        if(server!=null){
            if(previous!=null)try{server.cancelConnection(previous);}catch(RuntimeException ignored){}
            server.close();server=null;
        }
        tx=null;
    }
    private void refreshBluetooth() {
        refreshCount++;bluetoothRetries=0;blockedUntil=0;failures=0;pairUntil=0;
        error="";
        if(server==null){status="연결 새로고침 중";startBluetooth();return;}
        if(central!=null&&getSystemService(BluetoothManager.class).getConnectionState(central,BluetoothProfile.GATT)==BluetoothProfile.STATE_DISCONNECTED) {
            clearSession();
        }
        if(authenticated&&subscribed) {
            softRefreshCount++;
            sendSecure(object("type","refresh"));
            status="워치 연결됨";
        } else if(central!=null&&subscribed) {
            // This only requests a fresh pinned-key handshake; no data is trusted
            // until the existing peer-key check succeeds.
            sendPlain(object("type","wake","v",1));
            status="워치 인증 중";
        } else {
            // A refresh with no subscriber previously did nothing when the same
            // advertisement was already running. Re-announce without rebuilding
            // the GATT database or touching saved registration.
            if(central!=null&&!subscribed)clearSession();
            status="워치 연결 대기 중";discoveryRefreshes++;
            stopAdvertising();startAdvertising();
        }
        recordState(this);
    }
    private void retryBluetooth(String reason) {
        stopBluetooth();fail(reason);
        long delay=Math.min(30000L,1000L << Math.min(bluetoothRetries++,5));
        handler.postDelayed(bluetoothRetry,delay);
    }
    private void startBluetooth() {
        if(instance!=this || server!=null)return;
        handler.removeCallbacks(bluetoothRetry);
        try {startBluetoothReady();}
        catch(SecurityException error){fail("근처 기기 권한을 다시 허용해 주세요.");}
        catch(RuntimeException error){retryBluetooth("Bluetooth 준비를 다시 시도합니다.");}
    }
    private void startBluetoothReady() {
        BluetoothManager manager=getSystemService(BluetoothManager.class); BluetoothAdapter adapter=manager.getAdapter();
        if(adapter==null || !adapter.isEnabled()) {status="Bluetooth가 켜지면 다시 연결합니다";error="";recordState(this);return;}
        advertiser=adapter.getBluetoothLeAdvertiser();
        if(advertiser==null) {retryBluetooth("Bluetooth 광고 준비를 기다립니다.");return;}
        int token=++bluetoothEpoch;
        server=manager.openGattServer(this,callbacks(token));
        if(server==null) {retryBluetooth("Bluetooth 서버 준비를 다시 시도합니다.");return;}
        BluetoothGattService service=new BluetoothGattService(SERVICE,BluetoothGattService.SERVICE_TYPE_PRIMARY);
        tx=new BluetoothGattCharacteristic(TX,BluetoothGattCharacteristic.PROPERTY_INDICATE,0);
        tx.addDescriptor(new BluetoothGattDescriptor(CCC,BluetoothGattDescriptor.PERMISSION_READ|BluetoothGattDescriptor.PERMISSION_WRITE));
        service.addCharacteristic(tx);
        service.addCharacteristic(new BluetoothGattCharacteristic(RX,BluetoothGattCharacteristic.PROPERTY_WRITE,BluetoothGattCharacteristic.PERMISSION_WRITE));
        if(!server.addService(service))retryBluetooth("BLE 서비스 등록을 다시 시도합니다.");
    }
    private void stopAdvertising() {
        AdvertiseCallback previous=advertisements;advertisements=null;
        if(advertiser!=null&&previous!=null)try{advertiser.stopAdvertising(previous);}catch(RuntimeException ignored){}
    }
    private void startAdvertising() {
        if(instance!=this||server==null||central!=null||advertiser==null||advertisements!=null)return;
        handler.removeCallbacks(advertisingRetry);
        AdvertiseCallback callback=advertisements(bluetoothEpoch);advertisements=callback;
        try {
            advertiser.startAdvertising(new AdvertiseSettings.Builder().setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY).setConnectable(true).setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM).build(),new AdvertiseData.Builder().addServiceUuid(new ParcelUuid(SERVICE)).build(),callback);
        } catch(RuntimeException error) {
            advertisements=null;retryAdvertising();
        }
    }
    private void retryAdvertising() {
        // Advertising recovery must not close the GATT server or a live connection.
        if(central!=null||server==null)return;
        status="워치 연결 대기 중";recordState(this);
        handler.removeCallbacks(advertisingRetry);handler.postDelayed(advertisingRetry,3000);
    }
    private AdvertiseCallback advertisements(int token) {return new AdvertiseCallback() {
        @Override public void onStartSuccess(AdvertiseSettings settings) { handler.post(()->{if(token!=bluetoothEpoch||advertisements!=this)return;if(instance==BridgeService.this&&central==null){bluetoothRetries=0;status="워치 연결 대기 중";error="";recordState(BridgeService.this);}}); }
        @Override public void onStartFailure(int code) { handler.post(()->{if(token!=bluetoothEpoch||advertisements!=this)return;advertisements=null;retryAdvertising();}); }
    };}
    private BluetoothGattServerCallback callbacks(int token) {return new BluetoothGattServerCallback() {
        @Override public void onServiceAdded(int result,BluetoothGattService service) { handler.post(()->{if(token!=bluetoothEpoch)return;
            if(server==null||instance!=BridgeService.this)return;
            if(result!=BluetoothGatt.GATT_SUCCESS) {retryBluetooth("BLE 서비스 등록을 다시 시도합니다: "+result);return;}
            startAdvertising();
        }); }
        @Override public void onConnectionStateChange(BluetoothDevice device,int result,int state) { handler.post(()->{if(token!=bluetoothEpoch)return;
            if(server==null) return;
            if(state==BluetoothProfile.STATE_CONNECTED) {
                // Android reports shared LE connections, including clients using
                // another app's service. A link alone does not select our watch.
                // Claim only a client subscribing to our own TX characteristic.
                observedLinks++;recordState(BridgeService.this);
            } else if(state==BluetoothProfile.STATE_DISCONNECTED) {
                linkMtus.remove(device.getAddress());
                resumeProbes.remove(device.getAddress());
                if(matches(device)) {clearSession();status="연결 끊김, 워치 재연결 대기";startAdvertising();recordState(BridgeService.this);}
            }
        }); }
        @Override public void onMtuChanged(BluetoothDevice device,int value) { handler.post(()->{if(token!=bluetoothEpoch)return;int size=Math.max(23,value);linkMtus.put(device.getAddress(),size);if(matches(device))mtu=size;}); }
        @Override public void onDescriptorReadRequest(BluetoothDevice device,int requestId,int offset,BluetoothGattDescriptor descriptor) {
            handler.post(()->{if(token!=bluetoothEpoch)return;if(server!=null)server.sendResponse(device,requestId,offset==0?BluetoothGatt.GATT_SUCCESS:BluetoothGatt.GATT_INVALID_OFFSET,offset,subscribed?BluetoothGattDescriptor.ENABLE_INDICATION_VALUE:BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);});
        }
        @Override public void onDescriptorWriteRequest(BluetoothDevice device,int requestId,BluetoothGattDescriptor descriptor,boolean prepared,boolean response,int offset,byte[] value) {
            handler.post(()->{if(token!=bluetoothEpoch)return;
                if(server==null)return;
                boolean enable=Arrays.equals(value,BluetoothGattDescriptor.ENABLE_INDICATION_VALUE);
                boolean disable=Arrays.equals(value,BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
                boolean valid=CCC.equals(descriptor.getUuid())&&TX.equals(descriptor.getCharacteristic().getUuid())&&!prepared&&offset==0&&(enable||disable);
                if(valid&&enable&&central==null&&SystemClock.elapsedRealtime()>=blockedUntil) {
                    claimSubscription(device);subscriptionClaims++;
                }
                valid=valid&&(matches(device)||(central==null&&disable));
                if(valid)subscribed=enable;
                if(response)server.sendResponse(device,requestId,valid?BluetoothGatt.GATT_SUCCESS:BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED,0,null);
                recordState(BridgeService.this);
            });
        }
        @Override public void onCharacteristicWriteRequest(BluetoothDevice device,int requestId,BluetoothGattCharacteristic characteristic,boolean prepared,boolean response,int offset,byte[] value) {
            handler.post(()->{if(token!=bluetoothEpoch)return;
                if(server==null)return;
                boolean ownWrite=RX.equals(characteristic.getUuid())&&!prepared&&offset==0;
                if(ownWrite&&central==null) {
                    resumeRetainedSubscription(device,requestId,response,value);return;
                }
                boolean valid=ownWrite&&matches(device)&&subscribed;
                if(response)server.sendResponse(device,requestId,valid?BluetoothGatt.GATT_SUCCESS:BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED,0,null);
                if(!valid){rejectedCharacteristicWrites++;recordState(BridgeService.this);return;}
                // A normal accepted ATT write proves this payload fits the link MTU,
                // even if Android delivered onMtuChanged before STATE_CONNECTED.
                mtu=Math.max(mtu,value.length+3);
                try { byte[] message=assembler.accept(value,SystemClock.elapsedRealtime()); if(message!=null)receive(new JSONObject(new String(message,StandardCharsets.UTF_8))); }
                catch(Exception e) { disconnect("인증 또는 데이터 검증 실패"); }
            });
        }
        @Override public void onNotificationSent(BluetoothDevice device,int result) {
            long ticket=indicationTicket;
            handler.post(()->{if(token!=bluetoothEpoch||ticket!=indicationTicket||!matches(device)||!inFlight)return;
                boolean current=indicationGeneration==generation;
                byte[] completed=indicationPacket;
                inFlight=false;indicationPacket=null;
                if(result!=BluetoothGatt.GATT_SUCCESS&&current) { disconnect("BLE 전송 실패: "+result); return; }
                if(current&&outgoing.peekFirst()==completed)outgoing.pollFirst();
                drain();
            });
        }
    };}
    private void claimSubscription(BluetoothDevice device) {
        clearSession();central=device;subscribed=true;mtu=linkMtus.getOrDefault(device.getAddress(),23);
        stopAdvertising();error="";status="워치 인증 중";schedulePairingDeadline();
        int epoch=generation;
        // Send an indication as soon as the descriptor write is answered. A
        // background watch needs the characteristic event's runtime to finish
        // authentication; the old 750ms delay could outlive its connect callback.
        handler.post(()->{
            if(instance==this&&epoch==generation&&matches(device)&&subscribed
                    &&!authenticated&&"idle".equals(stage)&&!vault.get("peer").isEmpty()) {
                bootstrapSent++;sendPlain(object("type","wake","v",1,"bootstrap",true));recordState(this);
            }
        });
    }
    private void resumeRetainedSubscription(BluetoothDevice device,int requestId,boolean response,byte[] value) {
        // watchOS can retain its indication monitor across a phone process restart.
        // In that case it sends a fresh commit without writing CCC again. A shared
        // physical connection still must never select a peer on its own.
        boolean accepted=false;JSONObject commit=null;
        String address=device.getAddress();long now=SystemClock.elapsedRealtime();
        try {
            if(now<blockedUntil||vault.get("peer").isEmpty())throw new GeneralSecurityException("No saved peer");
            if(value==null||value.length<9||value.length>200)throw new GeneralSecurityException("Resume frame");
            int index=((value[4]&255)<<8)|(value[5]&255),count=((value[6]&255)<<8)|(value[7]&255);
            if(count<1||count>16||index>=count)throw new GeneralSecurityException("Resume fragments");
            resumeProbes.entrySet().removeIf(e->now-e.getValue().started>10000);
            ResumeProbe probe=resumeProbes.get(address);
            if(index==0) {
                if(probe==null&&resumeProbes.size()>=2)throw new GeneralSecurityException("Resume candidates");
                probe=new ResumeProbe();resumeProbes.put(address,probe);
            }
            if(probe==null||(probe.bytes+=value.length-8)>512)throw new GeneralSecurityException("Resume bounds");
            byte[] message=probe.frames.accept(value,now);
            if(message!=null) {
                resumeProbes.remove(address);
                commit=new JSONObject(new String(message,StandardCharsets.UTF_8));
                if(!"commit".equals(commit.optString("type"))||commit.optInt("v")!=1||unb64(commit.getString("commit")).length!=32)
                    throw new GeneralSecurityException("Resume commit");
                claimSubscription(device);retainedSubscriptionClaims++;
                mtu=Math.max(mtu,value.length+3);
            }
            accepted=true;
        } catch(Exception ignored) {resumeProbes.remove(address);commit=null;rejectedCharacteristicWrites++;}
        if(response)server.sendResponse(device,requestId,accepted?BluetoothGatt.GATT_SUCCESS:BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED,0,null);
        if(commit!=null) {
            // This restores transport state only. receive() still requires the
            // saved peer public key and both encrypted confirmations before data.
            try {receive(commit);}
            catch(Exception error){disconnect("인증 또는 데이터 검증 실패");}
        }
        recordState(this);
    }
    private boolean matches(BluetoothDevice d) { return central!=null&&d.getAddress().equals(central.getAddress()); }
    private void receive(JSONObject message) throws Exception {
        String type=message.optString("type");
        if("commit".equals(type)) {
            if(message.optInt("v")!=1)throw new GeneralSecurityException("Handshake state");
            if(vault.get("peer").isEmpty()&&SystemClock.elapsedRealtime()>pairUntil) { disconnect("휴대폰에서 새 워치 등록을 먼저 누르세요."); return; }
            byte[] commit=unb64(message.getString("commit")); if(commit.length!=32)throw new GeneralSecurityException("Commit length");
            if(!stage.equals("idle")||session!=null) {
                clearProtocol();
                schedulePairingDeadline();
            }
            peerCommit=commit;
            ownNonce=Crypto.random(32); stage="reveal";
            sendPlain(object("type","commit","v",1,"commit",b64(Crypto.digest(Crypto.join(identity.getPublic().getEncoded(),ownNonce))))); return;
        }
        if("reveal".equals(type)) {
            if(!stage.equals("reveal"))throw new GeneralSecurityException("Reveal state");
            peerPublic=unb64(message.getString("public")); byte[] nonce=unb64(message.getString("nonce"));
            if(nonce.length!=32||!MessageDigest.isEqual(peerCommit,Crypto.digest(Crypto.join(peerPublic,nonce))))throw new GeneralSecurityException("Commit mismatch");
            String pinned=vault.get("peer");
            if(!pinned.isEmpty()&&!MessageDigest.isEqual(unb64(pinned),peerPublic)) { disconnect("등록된 워치와 보안 키가 다릅니다."); return; }
            byte[] shared=Crypto.agree(identity.getPrivate(),peerPublic), key=Crypto.hkdf(shared,Crypto.join(nonce,ownNonce),Crypto.INFO,32); Arrays.fill(shared,(byte)0);
            session=new Crypto.Session(key,true); pairingCode=Crypto.code(key); stage="confirm"; localConfirmed=!pinned.isEmpty(); remoteConfirmed=false;
            sendPlain(object("type","reveal","public",b64(identity.getPublic().getEncoded()),"nonce",b64(ownNonce)));
            if(localConfirmed) sendSecure(object("type","confirm"));
            else status="두 기기의 코드가 같은지 확인하세요";
            return;
        }
        if(!"sealed".equals(type)||session==null)throw new GeneralSecurityException("Encrypted message required");
        byte[] plain=session.open(unb64(message.getString("data")),message.getLong("seq"));
        JSONObject event=new JSONObject(new String(plain,StandardCharsets.UTF_8)); String eventType=event.optString("type");
        if("confirm".equals(eventType)) { remoteConfirmed=true; finishAuthentication(); return; }
        if(!authenticated)throw new GeneralSecurityException("Confirm both devices");
        if("ack".equals(eventType)) {
            String id=event.getString("id"), revision=event.getString("rev"); Delivery d=pending.get(id);
            if(d!=null&&d.message.optString("rev").equals(revision)) {
                String icon=d.message.optString("icon_key");if(d.iconSent&&!icon.isEmpty())acknowledgedIcons.add(icon);
                pending.remove(id); acknowledged++; lastRtt=SystemClock.elapsedRealtime()-d.queuedAt; waiting=pending.size();  android.util.Log.i("FoldBridge","watch_receipt count="+acknowledged+" pending="+waiting);
            }
            if(activeDelivery!=null&&activeDelivery.message.optString("id").equals(id)&&activeDelivery.message.optString("rev").equals(revision))activeDelivery=null;
            drainPending();
            recordState(this);
        } else if("state".equals(eventType)) watchActive=event.optBoolean("active");
        else if("push_token".equals(eventType)) { String token=event.getString("token"); if(!token.matches("[0-9a-f]{64,256}"))throw new GeneralSecurityException("Push token"); vault.put("push_token",token); }
        else if("vehicle_list".equals(eventType)) sendVehicleCatalogue();
        else if("vehicle_command".equals(eventType)) sendSecure(VehicleBridge.get(this).execute(event));
        else if("sync".equals(eventType)) flush();
        else if("refresh".equals(eventType)) {softRefreshCount++;sendSecure(object("type","refreshed"));flush();recordState(this);}
        else if("ping".equals(eventType)) {
            String nonce=event.getString("nonce");
            if(nonce.length()>64)throw new GeneralSecurityException("Ping length");
            sendSecure(object("type","pong","nonce",nonce));
        }
    }
    static void confirmPair() { BridgeService s=instance; if(s!=null)s.handler.post(()->{if(s.session!=null&&!s.authenticated){s.localConfirmed=true;s.sendSecure(object("type","confirm"));s.finishAuthentication();}}); }
    private void finishAuthentication() {
        if(authenticated||!localConfirmed||!remoteConfirmed)return;
        // Every authenticated connection starts now, including saved-peer reconnects.
        // Late listener callbacks keep Android's post time and cannot replay old alerts.
        connectionStartedAt=System.currentTimeMillis();
        pending.clear();activeDelivery=null;waiting=0;
        vault.put("peer",b64(peerPublic)); authenticated=true;pairingCode="";failures=0;blockedUntil=0;error="";status="워치 연결됨";
        sendSecure(object("type","ready","liveness",0));
        recordState(this);
    }
    private void sendPlain(JSONObject object) {
        if(central==null||!subscribed)return;
        byte[] data=object.toString().getBytes(StandardCharsets.UTF_8);
        if(data.length>Frames.MAX_BYTES){disconnect("전송 메시지가 너무 큽니다.");return;}
        if(messages.size()>=256)messages.pollFirst();
        messages.addLast(data); drain();
    }
    private void sendSecure(JSONObject message) {
        try { if(session==null)return; long seq=session.next(); byte[] data=session.seal(message.toString().getBytes(StandardCharsets.UTF_8),seq); sendPlain(object("type","sealed","seq",seq,"data",b64(data))); }
        catch(Exception e) { disconnect("보안 전송 실패"); }
    }
    private void sendVehicleCatalogue(){if(authenticated)sendSecure(VehicleBridge.get(this).catalogue());}
    static void vehicleChanged(){BridgeService s=instance;if(s!=null)s.handler.post(s::sendVehicleCatalogue);}
    private void drain() {
        if(server==null||central==null||inFlight)return;
        if(outgoing.isEmpty()&&!messages.isEmpty())outgoing.addAll(frames.split(messages.removeFirst(),Math.max(20,mtu-3)));
        if(outgoing.isEmpty())return;
        inFlight=true;indicationGeneration=generation;indicationPacket=outgoing.peekFirst();
        long ticket=++indicationTicket;
        int result=server.notifyCharacteristicChanged(central,tx,true,indicationPacket);
        if(result!=BluetoothStatusCodes.SUCCESS) { inFlight=false; disconnect("BLE 전송을 시작하지 못했습니다: "+result); return; }
        handler.postDelayed(()->{if(ticket==indicationTicket&&inFlight)disconnect("BLE 전송 확인 시간 초과");},30000);
    }
    static void enqueue(JSONObject notification) {
        BridgeService s=instance; if(s==null)return;
        s.handler.post(()->{
            long postedAt=notification.optLong("posted_at",0);
            if(!s.authenticated||postedAt<=s.connectionStartedAt)return;
            String id=notification.optString("id"); Delivery previous=s.pending.get(id);
            if(previous!=null&&previous.message.optString("rev").equals(notification.optString("rev"))) {
                if(!previous.message.has("icon_key")&&notification.has("icon_key")) {
                    for(String field:new String[]{"app_id","icon_key","icon_png"})try{previous.message.put(field,notification.get(field));}catch(JSONException ignored){}
                    
                }
                return;
            }
            Delivery d=new Delivery(notification); s.pending.put(id,d);
            while(s.pending.size()>MAX_PENDING){s.pending.remove(s.pending.keySet().iterator().next());error="미전달 보관 한도에 도달해 가장 오래된 알림을 비웠습니다.";}
            waiting=s.pending.size(); s.drainPending();
            recordState(s);
        });
    }
    static void discardPending(String id) {
        BridgeService s=instance;if(s==null)return;
        s.handler.post(()->{
            if(s.pending.remove(id)==null)return;
            if(s.activeDelivery!=null&&s.activeDelivery.message.optString("id").equals(id))s.activeDelivery=null;
            waiting=s.pending.size();s.drainPending();recordState(s);
        });
    }
    private void drainPending() {
        if(instance!=this||!authenticated||activeDelivery!=null)return;
        flushExpired();
        for(Delivery d:pending.values())if(!d.waitingForWake){deliver(d);break;}
    }
    private void deliver(Delivery d) {
        if(instance!=this||!authenticated||pending.get(d.message.optString("id"))!=d)return;
        activeDelivery=d;d.bleAttempts++;
        android.util.Log.i("FoldBridge","notification_send attempt="+d.bleAttempts+" pending="+pending.size());
        int epoch=generation;
        try {
            JSONObject message=new JSONObject(d.message.toString());
            if(acknowledgedIcons.contains(message.optString("icon_key")))message.remove("icon_png");
            if(message.toString().getBytes(StandardCharsets.UTF_8).length>11000)message.remove("icon_png");
            d.iconSent=message.has("icon_png");
            sendSecure(message);
        } catch(JSONException error) {disconnect("알림을 준비하지 못했습니다.");return;}
        handler.postDelayed(()->{
            if(instance!=this||generation!=epoch||activeDelivery!=d||!authenticated)return;
            activeDelivery=null;
            if(pending.get(d.message.optString("id"))!=d){drainPending();return;}
            if(d.bleAttempts<3)deliver(d);
            else {d.waitingForWake=true;recordState(this);drainPending();}
        },90000);
    }
    private void flushExpired() {
        long now=System.currentTimeMillis();
        pending.values().removeIf(d->now-d.message.optLong("posted_at",now)>DELIVERY_RETENTION_MILLIS);
        if(activeDelivery!=null&&pending.get(activeDelivery.message.optString("id"))!=activeDelivery)activeDelivery=null;
        waiting=pending.size();
    }
    private void flush() {
        flushExpired();
        for(Delivery d:pending.values())if(d.waitingForWake){d.waitingForWake=false;d.bleAttempts=0;}
        drainPending();
    }
    private void clearProtocol() {
        generation++; acknowledgedIcons.clear(); session=null; peerPublic=null; ownNonce=null; peerCommit=null; stage="idle";
        activeDelivery=null;pending.clear();waiting=0;connectionStartedAt=0;
        authenticated=false;localConfirmed=false;remoteConfirmed=false;watchActive=false;pairingCode="";
        outgoing.clear();messages.clear();assembler.reset();
        // Keep the old ATT indication slot until its callback. Its old-generation
        // callback must not remove the first packet of the replacement session.
    }
    private void schedulePairingDeadline() {
        int epoch=generation;
        handler.postDelayed(()->{
            // A saved watch may be suspended during restoration. Keep its GATT
            // link pending; every payload still requires a fresh pinned handshake.
            if(epoch==generation&&!authenticated&&vault.get("peer").isEmpty())disconnect("인증 시간이 만료됐습니다.");
        },120000);
    }
    private void clearSession() {
        clearProtocol();central=null;subscribed=false;mtu=23;
        resumeProbes.clear();
        inFlight=false;indicationPacket=null;indicationTicket++;
    }
    private void disconnect(String why) { lastDisconnectReason=why;disconnectCount++;android.util.Log.i("FoldBridgeConnection",why); BluetoothDevice d=central; clearSession(); if(server!=null&&d!=null)server.cancelConnection(d); if(++failures>=5){blockedUntil=SystemClock.elapsedRealtime()+60000;failures=0;}startAdvertising();fail(why); }
    private void fail(String why) { error=why; status="확인 필요";recordState(this); }
    static void bluetoothOff() {
        BridgeService s=instance;if(s==null)return;
        s.handler.post(()->{s.stopBluetooth();s.bluetoothRetries=0;error="";status="Bluetooth가 켜지면 다시 연결합니다";recordState(s);});
    }
    static void test() { String id=UUID.randomUUID().toString(); enqueue(object("type","notification","id",id,"rev",id,"app","FoldBridge","title","연결 테스트","body","이 알림이 워치에 도착하면 전달 경로가 동작합니다.","posted_at",System.currentTimeMillis())); }
    static void forget(Context context) { BridgeService s=instance; if(s!=null){s.disconnect("연결을 해제했습니다.");s.pending.clear();s.connectionStartedAt=0;waiting=0;}try {Vault v=new Vault(context); v.remove("peer");v.remove("first_pair_cutoff");v.remove("push_token");v.remove("outbox");}catch(Exception ignored){} }
    @Override public IBinder onBind(Intent intent) {return null;}
    @Override public void onDestroy() {
        handler.removeCallbacksAndMessages(null);stopBluetooth();instance=null;status="중지됨";super.onDestroy();
    }
}
