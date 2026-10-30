package dev.foldbridge;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import java.io.ByteArrayOutputStream;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

/** Original installed application artwork, bounded for the BLE message size. */
final class AppIcons {
    record Artwork(String key,String png) {}
    private static final Map<String,Artwork> cache=new LinkedHashMap<>(64,0.75f,true) {
        @Override protected boolean removeEldestEntry(Map.Entry<String,Artwork> entry){return size()>64;}
    };
    static synchronized Artwork get(Context context,String packageName) {
        Artwork saved=cache.get(packageName);if(saved!=null)return saved;
        try {
            Drawable drawable=context.getPackageManager().getApplicationIcon(packageName);
            for(int size:new int[]{48,40,32,24,16}) {
                Bitmap bitmap=Bitmap.createBitmap(size,size,Bitmap.Config.ARGB_8888);
                Canvas canvas=new Canvas(bitmap);drawable.setBounds(0,0,size,size);drawable.draw(canvas);
                ByteArrayOutputStream out=new ByteArrayOutputStream();bitmap.compress(Bitmap.CompressFormat.PNG,100,out);bitmap.recycle();
                byte[] bytes=out.toByteArray();if(bytes.length>3072)continue;
                Artwork result=new Artwork(NotificationRelay.hex(Crypto.digest(bytes)),Base64.getEncoder().encodeToString(bytes));
                cache.put(packageName,result);return result;
            }
        } catch(Exception ignored) {}
        return null;
    }
}
