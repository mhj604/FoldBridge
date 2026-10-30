package dev.foldbridge;

import android.content.Context;
import android.content.SharedPreferences;
import android.security.keystore.*;
import java.security.*;
import java.security.spec.ECGenParameterSpec;
import java.util.Base64;
import javax.crypto.*;
import javax.crypto.spec.GCMParameterSpec;

/** Pair identity stays in Android Keystore; peer and relay settings are encrypted at rest. */
final class Vault {
    private static final String EC="foldbridge.identity.v1", AES="foldbridge.storage.v1";
    private final SharedPreferences prefs; private final KeyStore store;
    private static final Object GLOBAL=new Object();
    private static final java.util.concurrent.ConcurrentHashMap<String,String> cache=new java.util.concurrent.ConcurrentHashMap<>();
    Vault(Context context) throws Exception { prefs=context.getSharedPreferences("vault",Context.MODE_PRIVATE); store=KeyStore.getInstance("AndroidKeyStore"); store.load(null); }
    KeyPair identity() throws Exception { synchronized(GLOBAL){
        if(!store.containsAlias(EC)) {
            KeyPairGenerator gen=KeyPairGenerator.getInstance("EC","AndroidKeyStore");
            gen.initialize(new KeyGenParameterSpec.Builder(EC,KeyProperties.PURPOSE_AGREE_KEY).setAlgorithmParameterSpec(new ECGenParameterSpec("secp256r1")).build()); gen.generateKeyPair();
        }
        return new KeyPair(store.getCertificate(EC).getPublicKey(),(PrivateKey)store.getKey(EC,null));}
    }
    private SecretKey storageKey() throws Exception {
        if(!store.containsAlias(AES)) {
            KeyGenerator g=KeyGenerator.getInstance("AES","AndroidKeyStore");
            g.init(new KeyGenParameterSpec.Builder(AES,KeyProperties.PURPOSE_ENCRYPT|KeyProperties.PURPOSE_DECRYPT).setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build()); g.generateKey();
        }
        return (SecretKey)store.getKey(AES,null);
    }
    String get(String name) {
        String cached=cache.get(name);if(cached!=null)return cached;
        synchronized(GLOBAL){return load(name);}
    }
    private String load(String name) {
        String value=prefs.getString(name,null); if(value==null) return "";
        try { byte[] bytes=Base64.getDecoder().decode(value); Cipher c=Cipher.getInstance("AES/GCM/NoPadding"); c.init(Cipher.DECRYPT_MODE,storageKey(),new GCMParameterSpec(128,java.util.Arrays.copyOf(bytes,12))); c.updateAAD(name.getBytes(java.nio.charset.StandardCharsets.UTF_8));String plain=new String(c.doFinal(bytes,12,bytes.length-12),java.nio.charset.StandardCharsets.UTF_8);cache.put(name,plain);return plain; }
        catch(Exception e) { throw new IllegalStateException("저장된 연결 정보를 읽을 수 없습니다. 연결을 해제하고 다시 등록하세요.",e); }
    }
    void put(String name,String value) {synchronized(GLOBAL){
        try { Cipher c=Cipher.getInstance("AES/GCM/NoPadding"); c.init(Cipher.ENCRYPT_MODE,storageKey()); c.updateAAD(name.getBytes(java.nio.charset.StandardCharsets.UTF_8)); byte[] data=Crypto.join(c.getIV(),c.doFinal(value.getBytes(java.nio.charset.StandardCharsets.UTF_8))); if(!prefs.edit().putString(name,Base64.getEncoder().encodeToString(data)).commit()) throw new IllegalStateException("저장 실패");cache.put(name,value); }
        catch(Exception e) { throw new IllegalStateException("연결 정보 저장 실패",e); }}
    }
    void remove(String key) {synchronized(GLOBAL){prefs.edit().remove(key).commit();cache.remove(key);}}
}
