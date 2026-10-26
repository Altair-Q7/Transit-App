from fastapi import FastAPI, Request
from fastapi.testclient import TestClient
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware

from app.core import rate_limit


class FakeRedis:
    def __init__(self):
        self.keys: list[str] = []

    async def incr(self, key: str) -> int:
        self.keys.append(key)
        return 1

    async def expire(self, key: str, seconds: int) -> None:
        return None


def _limited_app() -> FastAPI:
    app = FastAPI()

    @app.get("/limited")
    async def limited(request: Request):
        await rate_limit.enforce_rate_limit(request, "60/minute", bucket="proxy-test")
        return {"ok": True}

    return app


def test_forwarded_for_is_honoured_when_proxy_is_trusted(monkeypatch):
    fake = FakeRedis()
    monkeypatch.setattr(rate_limit, "get_redis", lambda: fake)
    app = _limited_app()
    # This is the peer uvicorn sees in tests; in deployment it is the
    # reverse proxy address allowed via --forwarded-allow-ips.
    app.add_middleware(ProxyHeadersMiddleware, trusted_hosts=["testclient"])

    response = TestClient(app).get(
        "/limited", headers={"X-Forwarded-For": "203.0.113.7"}
    )

    assert response.status_code == 200
    assert len(fake.keys) == 1
    assert ":203.0.113.7:" in fake.keys[0]


def test_forwarded_for_is_ignored_when_proxy_is_untrusted(monkeypatch):
    fake = FakeRedis()
    monkeypatch.setattr(rate_limit, "get_redis", lambda: fake)
    app = _limited_app()
    # The test client peer is not in the trusted proxy list, so the
    # caller-supplied header must not influence the rate-limit key.
    app.add_middleware(ProxyHeadersMiddleware, trusted_hosts=["10.0.0.1"])

    response = TestClient(app).get(
        "/limited", headers={"X-Forwarded-For": "203.0.113.7"}
    )

    assert response.status_code == 200
    assert len(fake.keys) == 1
    assert ":203.0.113.7:" not in fake.keys[0]
    assert ":testclient:" in fake.keys[0]
