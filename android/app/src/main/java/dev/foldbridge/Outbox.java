package dev.foldbridge;

import org.json.*;
import java.util.concurrent.*;

/** Crash recovery without placing disk I/O on the BLE delivery path. */
final class Outbox {
    private static final ExecutorService disk=Executors.newSingleThreadExecutor();
    private final Vault vault;
    private final Object lock=new Object();
    private String latest;private boolean scheduled;
    Outbox(Vault vault){this.vault=vault;}
    JSONArray load() throws JSONException {String saved=vault.get("outbox");return saved.isEmpty()?new JSONArray():new JSONArray(saved);}
    void save(JSONArray messages){
        synchronized(lock){latest=messages.toString();if(scheduled)return;scheduled=true;}
        disk.execute(()->{while(true){
            String snapshot;
            synchronized(lock){snapshot=latest;latest=null;if(snapshot==null){scheduled=false;return;}}
            try{vault.put("outbox",snapshot);}catch(RuntimeException error){BridgeService.error="보류 알림을 저장하지 못했습니다. 현재 연결 전송은 계속됩니다.";}
        }});
    }
}
