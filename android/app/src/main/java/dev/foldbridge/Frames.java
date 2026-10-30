package dev.foldbridge;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.*;

/** Each ATT value: message uint32 BE, index uint16 BE, count uint16 BE, payload. */
public final class Frames {
    public static final int MAX_BYTES = 16384;
    private int next = 0;
    public List<byte[]> split(byte[] data, int valueLength) {
        if (data.length == 0 || data.length > MAX_BYTES || valueLength < 20) throw new IllegalArgumentException("Frame bounds");
        int chunk = Math.min(valueLength, 200)-8, count = (data.length+chunk-1)/chunk, id = ++next;
        List<byte[]> frames = new ArrayList<>();
        for(int i=0;i<count;i++) { int n=Math.min(chunk,data.length-i*chunk); frames.add(ByteBuffer.allocate(8+n).putInt(id).putShort((short)i).putShort((short)count).put(data,i*chunk,n).array()); }
        return frames;
    }
    public static final class Assembler {
        private int id, count, expected; private long started; private final ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        public synchronized void reset() { bytes.reset(); expected = 0; count = 0; }
        public synchronized byte[] accept(byte[] frame, long now) {
            if(frame.length < 9 || frame.length > 200) throw new IllegalArgumentException("Frame length");
            ByteBuffer b=ByteBuffer.wrap(frame); int message=b.getInt(), index=Short.toUnsignedInt(b.getShort()), total=Short.toUnsignedInt(b.getShort());
            if(total<1 || total>1366 || index>=total) throw new IllegalArgumentException("Fragment count");
            if(index==0) { reset(); id=message; count=total; started=now; }
            if(count==0 || id!=message || count!=total || index!=expected || now-started>120000) { reset(); throw new IllegalArgumentException("Fragment order or deadline"); }
            bytes.write(frame,8,frame.length-8); expected++;
            if(bytes.size()>MAX_BYTES) { reset(); throw new IllegalArgumentException("Message size"); }
            if(expected!=count) return null;
            byte[] result=bytes.toByteArray(); reset(); return result;
        }
    }
}
