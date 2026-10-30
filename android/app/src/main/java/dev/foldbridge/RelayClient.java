package dev.foldbridge;

import org.json.JSONObject;
import javax.net.ssl.HttpsURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.*;
import java.util.function.Consumer;
import java.util.concurrent.atomic.AtomicLong;

final class RelayClient {
    private static final ThreadPoolExecutor network=new ThreadPoolExecutor(1,1,0,TimeUnit.SECONDS,new ArrayBlockingQueue<>(128),new ThreadPoolExecutor.AbortPolicy());
    private static volatile HttpsURLConnection active;
    private static final AtomicLong generation=new AtomicLong();
    static void cancelAll(){generation.incrementAndGet();network.getQueue().clear();HttpsURLConnection c=active;if(c!=null)c.disconnect();}
    static boolean configured(Vault v) {return !v.get("relay_url").isEmpty()&&!v.get("relay_auth").isEmpty()&&!v.get("push_token").isEmpty();}
    static void send(Vault vault,JSONObject message,Consumer<Boolean> done) {
        if(!configured(vault)){done.accept(false);return;}
        final String url=vault.get("relay_url"), auth=vault.get("relay_auth"), device=vault.get("push_token");
        final long epoch=generation.get();
        try {network.execute(()->{
            boolean success=false; HttpsURLConnection c=null;
            try {
                if(epoch!=generation.get()||System.currentTimeMillis()-message.optLong("posted_at")>=120000)return;
                URI uri=URI.create(url); if(!"https".equals(uri.getScheme())||uri.getUserInfo()!=null)throw new IllegalArgumentException("HTTPS required");
                c=(HttpsURLConnection)uri.toURL().openConnection(); active=c;c.setRequestMethod("POST");c.setConnectTimeout(4000);c.setReadTimeout(5000);c.setDoOutput(true);
                c.setRequestProperty("Authorization","Bearer "+auth);c.setRequestProperty("Content-Type","application/json");
                byte[] data=BridgeService.object("device_token",device,"notification",message).toString().getBytes(StandardCharsets.UTF_8);
                c.setFixedLengthStreamingMode(data.length);try(var out=c.getOutputStream()){
                    if(epoch!=generation.get()||System.currentTimeMillis()-message.optLong("posted_at")>=120000)return;
                    out.write(data);
                }success=c.getResponseCode()==202;
            }catch(Exception ignored){}finally{if(c!=null)c.disconnect();active=null;done.accept(success);}
        });}catch(RejectedExecutionException e){done.accept(false);}
    }
}
