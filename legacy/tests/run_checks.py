#!/usr/bin/env python3
"""Cross-check the wire crypto against Python's independent cryptography implementation."""
import base64
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

root=Path(__file__).resolve().parents[1]
phone=ec.derive_private_key(7,ec.SECP256R1());watch=ec.derive_private_key(11,ec.SECP256R1())
public=lambda k:k.public_key().public_bytes(serialization.Encoding.DER,serialization.PublicFormat.SubjectPublicKeyInfo)
private=lambda k:k.private_bytes(serialization.Encoding.DER,serialization.PrivateFormat.PKCS8,serialization.NoEncryption())
wn=bytes(range(32));pn=bytes(range(32,64));secret=phone.exchange(ec.ECDH(),watch.public_key())
key=HKDF(algorithm=hashes.SHA256(),length=32,salt=wn+pn,info=b'FoldBridge/v1').derive(secret)
plain='{"body":"안녕하세요","type":"test"}'.encode()
vectors={'phone_private':private(phone),'watch_public':public(watch),'shared':secret,'watch_nonce':wn,'phone_nonce':pn,'key':key,'plain':plain,
         'phone_cipher':AESGCM(key).encrypt(b'FBP1'+(1).to_bytes(8,'big'),plain,b'FoldBridge/v1'),
         'watch_cipher':AESGCM(key).encrypt(b'FBW1'+(1).to_bytes(8,'big'),plain,b'FoldBridge/v1')}
code=f'{int.from_bytes(hashlib.sha256(key+b"compare").digest()[:4],"big")%1000000:06d}'
with tempfile.TemporaryDirectory(prefix='foldbridge-check-') as temp:
    temp=Path(temp);prop=temp/'vectors.properties'
    prop.write_text('\n'.join(f'{k}={base64.b64encode(v).decode()}' for k,v in vectors.items())+'\ncode='+code+'\n')
    java=root/'android/app/src/main/java/dev/foldbridge'
    subprocess.run(['javac','-encoding','UTF-8','-d',str(temp),str(java/'Crypto.java'),str(java/'Frames.java'),str(root/'tests/ProtocolTest.java')],check=True)
    subprocess.run(['java','-cp',str(temp),'dev.foldbridge.ProtocolTest',str(prop)],check=True)
subprocess.run([sys.executable,'-m','unittest','discover','-s',str(root/'tests'),'-p','test_*.py','-v'],check=True)
print('No physical watch, Android Bluetooth, APNs delivery, or latency was exercised by these checks.')
