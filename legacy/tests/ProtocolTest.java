package dev.foldbridge;

import java.nio.file.*;
import java.security.*;
import java.security.spec.*;
import java.util.*;

public final class ProtocolTest {
    private static byte[] bytes(Properties p,String key){return Base64.getDecoder().decode(p.getProperty(key));}
    private static void equal(byte[] a,byte[] b,String why){if(!Arrays.equals(a,b))throw new AssertionError(why);}
    private static void rejected(Runnable action,String why){try{action.run();}catch(Exception expected){return;}throw new AssertionError(why);}
    public static void main(String[] args) throws Exception {
        Properties v=new Properties();try(var input=Files.newInputStream(Path.of(args[0]))){v.load(input);}
        PrivateKey own=KeyFactory.getInstance("EC").generatePrivate(new PKCS8EncodedKeySpec(bytes(v,"phone_private")));
        byte[] shared=Crypto.agree(own,bytes(v,"watch_public"));equal(shared,bytes(v,"shared"),"P-256 agreement mismatch");
        byte[] key=Crypto.hkdf(shared,Crypto.join(bytes(v,"watch_nonce"),bytes(v,"phone_nonce")),Crypto.INFO,32);equal(key,bytes(v,"key"),"HKDF mismatch");
        if(!Crypto.code(key).equals(v.getProperty("code")))throw new AssertionError("Comparison code mismatch");
        Crypto.Session phone=new Crypto.Session(key,true), watch=new Crypto.Session(key,false);
        long seq=phone.next();byte[] sealed=phone.seal(bytes(v,"plain"),seq);equal(sealed,bytes(v,"phone_cipher"),"Phone AES-GCM golden mismatch");
        try{phone.seal(bytes(v,"plain"),seq);throw new AssertionError("Nonce reuse accepted");}catch(GeneralSecurityException expected){}
        equal(watch.open(sealed,seq),bytes(v,"plain"),"Phone to watch decode");
        try{watch.open(sealed,seq);throw new AssertionError("Replay accepted");}catch(GeneralSecurityException expected){}
        long next=phone.next();byte[] original=phone.seal(bytes(v,"plain"),next),tampered=original.clone();tampered[0]^=1;
        try{watch.open(tampered,next);throw new AssertionError("Tamper accepted");}catch(GeneralSecurityException expected){}
        equal(watch.open(original,next),bytes(v,"plain"),"A failed tag must not consume sequence");
        long reply=watch.next();byte[] response=watch.seal(bytes(v,"plain"),reply);equal(response,bytes(v,"watch_cipher"),"Watch AES-GCM golden mismatch");
        equal(phone.open(response,reply),bytes(v,"plain"),"Watch to phone decode");
        byte[] wrong=key.clone();wrong[0]^=1;
        if(Crypto.code(wrong).equals(Crypto.code(key)))throw new AssertionError("Vector SAS failed to distinguish keys");
        for(int length:new int[]{1,20,200,900,4096,16384})for(int mtu:new int[]{20,23,182,200,244}) {
            byte[] data=new byte[length];new Random(77).nextBytes(data);Frames f=new Frames();Frames.Assembler a=new Frames.Assembler();byte[] result=null;
            for(byte[] frame:f.split(data,mtu))result=a.accept(frame,1);equal(data,result,"Fragment boundary roundtrip");
        }
        Frames f=new Frames();var parts=f.split(new byte[200],20);Frames.Assembler a=new Frames.Assembler();a.accept(parts.get(0),0);
        rejected(()->a.accept(parts.get(2),1),"Out-of-order fragment accepted");
        a.accept(parts.get(0),0);rejected(()->a.accept(parts.get(1),15001),"Expired fragment accepted");
        rejected(()->new Frames().split(new byte[16385],20),"Oversized message accepted");
        System.out.println("Protocol: P-256/HKDF/AES-GCM interoperability, tamper/replay protection, 30 fragmentation boundaries, ordering and timeout passed.");
    }
}
