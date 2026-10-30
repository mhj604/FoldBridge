#!/usr/bin/env python3
"""Private APNs relay. Bind to loopback behind an HTTPS reverse proxy."""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import re
import threading
import time
from collections import OrderedDict, defaultdict, deque
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import httpx
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature


def encoded(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


@dataclass(frozen=True)
class Config:
    token: str
    team: str
    key_id: str
    topic: str
    key_file: str
    sandbox: bool = True

    @classmethod
    def environment(cls) -> "Config":
        if os.environ.get("APNS_ENVIRONMENT", "sandbox") not in ("sandbox", "production"):
            raise ValueError("APNS_ENVIRONMENT must be sandbox or production")
        config = cls(*(os.environ[name] for name in ("RELAY_TOKEN", "APNS_TEAM_ID", "APNS_KEY_ID", "APNS_TOPIC", "APNS_KEY_FILE")),
                     sandbox=os.environ.get("APNS_ENVIRONMENT", "sandbox") == "sandbox")
        if len(config.token) < 32:
            raise ValueError("RELAY_TOKEN must contain at least 32 random characters")
        if not re.fullmatch(r"[A-Za-z0-9.\-]{3,200}", config.topic):
            raise ValueError("Invalid APNS_TOPIC")
        return config


def make_payload(notification: dict) -> tuple[bytes, str, str]:
    if not isinstance(notification, dict):
        raise ValueError("notification must be an object")
    limits = {"id": 64, "rev": 64, "app": 80, "title": 160, "body": 1200}
    for key, limit in limits.items():
        if not isinstance(notification.get(key), str) or len(notification[key]) > limit:
            raise ValueError("Invalid notification field")
    if not re.fullmatch(r"[a-zA-Z0-9\-]{1,64}", notification["id"]):
        raise ValueError("Invalid notification id")
    payload = {"aps": {"alert": {"title": notification["app"], "subtitle": notification["title"], "body": notification["body"]},
                       "sound": "default", "thread-id": "foldbridge"},
               "fb_id": notification["id"], "fb_rev": notification["rev"]}
    while True:
        data = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        if len(data) <= 4096:
            return data, notification["id"], notification["rev"]
        body = payload["aps"]["alert"]["body"]
        if not body:
            raise ValueError("APNs payload too large")
        payload["aps"]["alert"]["body"] = body[:max(0, len(body) - max(1, (len(data) - 4096 + 1) // 2))]


class APNs:
    def __init__(self, config: Config):
        self.config = config
        self.key = serialization.load_pem_private_key(Path(config.key_file).read_bytes(), password=None)
        if not isinstance(self.key, ec.EllipticCurvePrivateKey) or not isinstance(self.key.curve, ec.SECP256R1):
            raise ValueError("APNs requires a P-256 authentication key")
        self.client = httpx.Client(http2=True, timeout=6, limits=httpx.Limits(max_connections=10, max_keepalive_connections=5))
        self.lock = threading.Lock()
        self.jwt = ""
        self.issued = 0

    def authorization(self) -> str:
        with self.lock:
            now = int(time.time())
            if not self.jwt or now - self.issued > 2400:
                header = encoded(json.dumps({"alg": "ES256", "kid": self.config.key_id}, separators=(",", ":")).encode())
                body = encoded(json.dumps({"iss": self.config.team, "iat": now}, separators=(",", ":")).encode())
                signing_input = f"{header}.{body}".encode()
                r, s = decode_dss_signature(self.key.sign(signing_input, ec.ECDSA(hashes.SHA256())))
                self.jwt = f"{header}.{body}.{encoded(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))}"
                self.issued = now
            return self.jwt

    def send(self, device: str, payload: bytes, collapse_id: str, expires_at: int) -> tuple[bool, str]:
        host = "api.sandbox.push.apple.com" if self.config.sandbox else "api.push.apple.com"
        headers = {"authorization": f"bearer {self.authorization()}", "apns-topic": self.config.topic,
                   "apns-push-type": "alert", "apns-priority": "10", "apns-expiration": str(expires_at),
                   "apns-collapse-id": collapse_id, "content-type": "application/json"}
        for attempt in range(3):
            if time.time() >= expires_at:
                return False, "ExpiredNotification"
            try:
                response = self.client.post(f"https://{host}/3/device/{device}", content=payload, headers=headers)
            except httpx.HTTPError:
                if attempt < 2:
                    time.sleep(0.2 * (2 ** attempt))
                    continue
                return False, "APNsConnectionError"
            if response.status_code == 200:
                return True, "AcceptedByAPNs"
            if response.status_code in (429, 500, 503) and attempt < 2:
                time.sleep(0.2 * (2 ** attempt))
                continue
            # Do not return response bodies, tokens or key material to logs.
            return False, f"APNsHTTP{response.status_code}"
        return False, "APNsUnavailable"


class Relay:
    def __init__(self, config: Config, apns):
        self.config, self.apns = config, apns
        self.lock = threading.Lock()
        self.sent: OrderedDict[str, float] = OrderedDict()
        self.rates: dict[str, deque[float]] = defaultdict(deque)
        self.in_flight: set[str] = set()

    def submit(self, value: dict) -> tuple[int, dict]:
        if not isinstance(value, dict):
            return 400, {"error": "InvalidRequest"}
        token = value.get("device_token", "")
        if not isinstance(token, str) or not re.fullmatch(r"[0-9a-f]{64,256}", token):
            return 400, {"error": "InvalidDeviceToken"}
        notification = value.get("notification")
        posted_at = notification.get("posted_at") if isinstance(notification, dict) else None
        if isinstance(posted_at, bool) or not isinstance(posted_at, int) or posted_at <= 0:
            return 400, {"error": "InvalidTimestamp"}
        wall_now = time.time()
        if posted_at / 1000 > wall_now + 30:
            return 400, {"error": "ClockSkew"}
        expires_at = int(posted_at / 1000 + 120)
        if wall_now >= expires_at:
            return 410, {"error": "ExpiredNotification"}
        try:
            payload, collapse_id, revision = make_payload(value.get("notification"))
        except ValueError:
            return 400, {"error": "InvalidNotification"}
        key = hashlib.sha256(f"{token}:{collapse_id}:{revision}".encode()).hexdigest()
        now = time.monotonic()
        with self.lock:
            while self.sent and (next(iter(self.sent.values())) < now - 180 or len(self.sent) > 2048):
                self.sent.popitem(last=False)
            if key in self.sent:
                return 202, {"status": "AlreadyAcceptedByAPNs"}
            if key in self.in_flight:
                return 503, {"error": "RetryLater"}
            rate = self.rates[token]
            while rate and rate[0] < now - 60:
                rate.popleft()
            if len(rate) >= 120:
                return 429, {"error": "RateLimit"}
            rate.append(now)
            self.in_flight.add(key)
        try:
            ok, reason = self.apns.send(token, payload, collapse_id, expires_at)
        except Exception:
            ok, reason = False, "APNsUnavailable"
        finally:
            with self.lock:
                self.in_flight.discard(key)
        if ok:
            with self.lock:
                self.sent[key] = time.monotonic()
            return 202, {"status": "AcceptedByAPNs"}
        return 502, {"error": reason}


def handler_for(relay: Relay):
    class Handler(BaseHTTPRequestHandler):
        server_version = "FoldBridge"

        def setup(self):
            super().setup()
            self.connection.settimeout(8)

        def log_message(self, *args):
            pass  # Never log notification bodies, bearer tokens, or device tokens.

        def respond(self, status: int, value: dict):
            data = json.dumps(value, separators=(",", ":")).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def do_POST(self):
            if self.path != "/v1/notify":
                self.respond(404, {"error": "NotFound"})
                return
            expected = "Bearer " + relay.config.token
            if not hmac.compare_digest(self.headers.get("Authorization", "").encode("utf-8"), expected.encode("utf-8")):
                self.respond(401, {"error": "Unauthorized"})
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
                if not 0 < length <= 16384 or self.headers.get("Transfer-Encoding"):
                    raise ValueError("length")
                value = json.loads(self.rfile.read(length))
            except (ValueError, UnicodeDecodeError, TimeoutError):
                self.respond(400, {"error": "InvalidRequest"})
                return
            status, result = relay.submit(value)
            self.respond(status, result)
    return Handler


def main():
    config = Config.environment()
    server = ThreadingHTTPServer((os.environ.get("RELAY_HOST", "127.0.0.1"), int(os.environ.get("RELAY_PORT", "8787"))), handler_for(Relay(config, APNs(config))))
    print("FoldBridge relay listening. Configure HTTPS reverse proxy before connecting a phone.", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
