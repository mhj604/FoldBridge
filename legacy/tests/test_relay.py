import base64
import json
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock
import urllib.error
import urllib.request
from pathlib import Path
from http.server import ThreadingHTTPServer
import httpx

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'relay'))
from server import Config, Relay, APNs, handler_for, make_payload
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import encode_dss_signature

class FakeAPNs:
    def __init__(self):self.calls=[];self.ok=True
    def send(self,*args):self.calls.append(args);return self.ok,'TestResult'

class RelayTest(unittest.TestCase):
    def setUp(self):
        self.config=Config('a'*48,'TEAM123456','KEY1234567','dev.foldbridge.watch','unused')
        self.apns=FakeAPNs();self.relay=Relay(self.config,self.apns)
        self.notification={'id':'abc123','rev':'rev1','app':'카카오톡','title':'테스트','body':'안녕하세요','posted_at':int(time.time()*1000)}
        self.request={'device_token':'a'*64,'notification':self.notification}

    def test_payload_utf8_limit(self):
        self.notification['body']='🔔'*1200
        data,_,_=make_payload(self.notification)
        self.assertLessEqual(len(data),4096)
        self.assertTrue(json.loads(data)['aps']['alert']['body'])

    def test_accepted_deduplicated_and_revision_updates(self):
        self.assertEqual(self.relay.submit(self.request)[0],202)
        self.assertEqual(self.relay.submit(self.request)[0],202)
        self.assertEqual(len(self.apns.calls),1)
        self.notification['rev']='rev2'
        self.assertEqual(self.relay.submit(self.request)[0],202)
        self.assertEqual(len(self.apns.calls),2)

    def test_apns_failure_can_retry(self):
        self.apns.ok=False;self.assertEqual(self.relay.submit(self.request)[0],502)
        self.apns.ok=True;self.assertEqual(self.relay.submit(self.request)[0],202)
        self.assertEqual(len(self.apns.calls),2)

    def test_rejects_invalid_payload_and_device(self):
        for payload in [None,{},[],{'device_token':'bad','notification':self.notification},{'device_token':'a'*64,'notification':{'body':'x'}}]:
            self.assertEqual(self.relay.submit(payload)[0],400)
        self.assertEqual(len(self.apns.calls),0)

    def test_expired_notification_never_reaches_apns(self):
        self.notification['posted_at']=int((time.time()-180)*1000)
        self.assertEqual(self.relay.submit(self.request),(410,{'error':'ExpiredNotification'}))
        self.assertEqual(self.apns.calls,[])

    def test_clock_skew_and_invalid_timestamp_are_rejected(self):
        for timestamp in [True,'now',None,0]:
            self.notification['posted_at']=timestamp
            self.assertEqual(self.relay.submit(self.request),(400,{'error':'InvalidTimestamp'}))
        self.notification['posted_at']=int((time.time()+60)*1000)
        self.assertEqual(self.relay.submit(self.request),(400,{'error':'ClockSkew'}))
        self.assertEqual(self.apns.calls,[])

    def test_apns_retry_does_not_extend_original_deadline(self):
        key=ec.generate_private_key(ec.SECP256R1())
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'key.p8';path.write_bytes(key.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption()))
            apns=APNs(Config('a'*48,'TEAM123456','KEY1234567','dev.foldbridge.watch',str(path)))
            apns.client.close()
            clock=[1000]
            requests=[]
            def transport(request):
                requests.append(request)
                self.assertEqual(request.headers['apns-expiration'],'1010')
                clock[0]=1020
                return httpx.Response(503)
            apns.client=httpx.Client(transport=httpx.MockTransport(transport))
            try:
                with mock.patch('server.time.time',side_effect=lambda:clock[0]),mock.patch('server.time.sleep'):
                    self.assertEqual(apns.send('a'*64,b'{}','abc123',1010),(False,'ExpiredNotification'))
                self.assertEqual(len(requests),1)
            finally:apns.client.close()

    def test_http_authentication_before_forward(self):
        http=ThreadingHTTPServer(('127.0.0.1',0),handler_for(self.relay));thread=threading.Thread(target=http.serve_forever,daemon=True);thread.start()
        try:
            url=f'http://127.0.0.1:{http.server_port}/v1/notify';data=json.dumps(self.request).encode()
            for auth in ['', 'Bearer bad']:
                request=urllib.request.Request(url,data=data,headers={'Authorization':auth,'Content-Type':'application/json'})
                with self.assertRaises(urllib.error.HTTPError) as error:urllib.request.urlopen(request,timeout=3)
                self.assertEqual(error.exception.code,401)
            self.assertEqual(len(self.apns.calls),0)
            request=urllib.request.Request(url,data=data,headers={'Authorization':'Bearer '+self.config.token,'Content-Type':'application/json'})
            with urllib.request.urlopen(request,timeout=3) as result:self.assertEqual(result.status,202)
        finally:http.shutdown();http.server_close();thread.join()

    def test_jwt_signature_and_cache(self):
        key=ec.generate_private_key(ec.SECP256R1())
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'key.p8';path.write_bytes(key.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption()))
            apns=APNs(Config('a'*48,'TEAM123456','KEY1234567','dev.foldbridge.watch',str(path)))
            try:
                token=apns.authorization();self.assertEqual(apns.authorization(),token)
                header,body,signature=token.split('.')
                raw=base64.urlsafe_b64decode(signature+'==');self.assertEqual(len(raw),64)
                signature=encode_dss_signature(int.from_bytes(raw[:32],'big'),int.from_bytes(raw[32:],'big'))
                key.public_key().verify(signature,f'{header}.{body}'.encode(),ec.ECDSA(hashes.SHA256()))
                self.assertEqual(json.loads(base64.urlsafe_b64decode(body+'=='))['iss'],'TEAM123456')
            finally:apns.client.close()

if __name__=='__main__':unittest.main(verbosity=2)
