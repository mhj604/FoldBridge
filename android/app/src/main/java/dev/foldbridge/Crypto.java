package dev.foldbridge;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.X509EncodedKeySpec;
import java.util.Arrays;
import javax.crypto.*;
import javax.crypto.spec.*;

/** P-256 ECDH, HKDF-SHA256 and direction-separated AES-GCM. No Android dependency. */
public final class Crypto {
    public static final byte[] INFO = "FoldBridge/v1".getBytes(StandardCharsets.UTF_8);
    private static final SecureRandom RANDOM = new SecureRandom();
    public static byte[] random(int n) { byte[] b = new byte[n]; RANDOM.nextBytes(b); return b; }
    public static byte[] agree(PrivateKey own, byte[] peer) throws GeneralSecurityException {
        if (peer.length > 160) throw new GeneralSecurityException("Public key length");
        PublicKey pub = KeyFactory.getInstance("EC").generatePublic(new X509EncodedKeySpec(peer));
        if (!(pub instanceof java.security.interfaces.ECPublicKey ec) || ec.getParams().getCurve().getField().getFieldSize() != 256)
            throw new GeneralSecurityException("P-256 required");
        KeyAgreement a = KeyAgreement.getInstance("ECDH"); a.init(own); a.doPhase(pub, true); return a.generateSecret();
    }
    public static byte[] hkdf(byte[] secret, byte[] salt, byte[] info, int length) throws GeneralSecurityException {
        Mac m = Mac.getInstance("HmacSHA256"); m.init(new SecretKeySpec(salt, "HmacSHA256")); byte[] prk = m.doFinal(secret);
        byte[] output = new byte[length], previous = new byte[0]; int offset = 0;
        for (int i = 1; offset < length; i++) {
            m.init(new SecretKeySpec(prk, "HmacSHA256")); m.update(previous); m.update(info); m.update((byte)i); previous = m.doFinal();
            int n = Math.min(previous.length, length-offset); System.arraycopy(previous, 0, output, offset, n); offset += n;
        }
        Arrays.fill(prk, (byte)0); return output;
    }
    public static byte[] join(byte[] a, byte[] b) { byte[] r = Arrays.copyOf(a, a.length+b.length); System.arraycopy(b,0,r,a.length,b.length); return r; }
    public static byte[] digest(byte[] bytes) {
        try { return MessageDigest.getInstance("SHA-256").digest(bytes); } catch (GeneralSecurityException e) { throw new IllegalStateException(e); }
    }
    public static String code(byte[] key) {
        long value = Integer.toUnsignedLong(ByteBuffer.wrap(digest(join(key,"compare".getBytes(StandardCharsets.UTF_8)))).getInt());
        return String.format(java.util.Locale.ROOT, "%06d", value % 1000000);
    }
    public static final class Session {
        private final byte[] key; private final int outgoing, incoming; private long sent = 0, received = 0, sealed = 0;
        public Session(byte[] key, boolean phone) {
            this.key = key.clone(); outgoing = phone ? 0x46425031 : 0x46425731; incoming = phone ? 0x46425731 : 0x46425031;
        }
        private byte[] crypt(int mode, byte[] data, long seq, int direction) throws GeneralSecurityException {
            Cipher c = Cipher.getInstance("AES/GCM/NoPadding");
            c.init(mode, new SecretKeySpec(key,"AES"), new GCMParameterSpec(128, ByteBuffer.allocate(12).putInt(direction).putLong(seq).array()));
            c.updateAAD(INFO); return c.doFinal(data);
        }
        public synchronized long next() { if (sent == Long.MAX_VALUE) throw new IllegalStateException("Rekey required"); return ++sent; }
        public synchronized byte[] seal(byte[] data, long seq) throws GeneralSecurityException {
            if(seq != sent || seq <= sealed || seq < 1) throw new GeneralSecurityException("Outgoing sequence");
            byte[] result=crypt(Cipher.ENCRYPT_MODE,data,seq,outgoing);sealed=seq;return result;
        }
        public synchronized byte[] open(byte[] data, long seq) throws GeneralSecurityException {
            if(seq <= received || seq < 1) throw new GeneralSecurityException("Replay rejected");
            byte[] plain = crypt(Cipher.DECRYPT_MODE,data,seq,incoming); received = seq; return plain;
        }
    }
}
