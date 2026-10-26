import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.core import rate_limit
from app.core.config import settings
from app.db.session import Base, get_db
from app.main import app
from app.models.operator import Operator


class FakeRedis:
    async def incr(self, key: str) -> int:
        return 1

    async def expire(self, key: str, seconds: int) -> None:
        return None


@pytest.fixture
def signup_api(monkeypatch):
    monkeypatch.setattr(rate_limit, "get_redis", lambda: FakeRedis())
    monkeypatch.setattr(settings, "operator_signup_code", None)
    monkeypatch.setattr(settings, "env", "development")

    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    db = Session(engine)

    def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    client = TestClient(app)
    try:
        yield client, db
    finally:
        app.dependency_overrides.clear()
        db.close()
        engine.dispose()


def _signup(client, email: str, invite_code: str | None = None):
    body = {"name": "Kerala Lines", "email": email, "password": "secret"}
    if invite_code is not None:
        body["invite_code"] = invite_code
    return client.post("/api/v1/auth/operator/signup", json=body)


def test_configured_code_allows_matching_invite(signup_api, monkeypatch):
    client, _ = signup_api
    monkeypatch.setattr(settings, "operator_signup_code", "correct-code")

    response = _signup(client, "correct@example.com", "correct-code")

    assert response.status_code == 200
    assert response.json()["role"] == "operator"


def test_configured_code_rejects_wrong_invite(signup_api, monkeypatch):
    client, _ = signup_api
    monkeypatch.setattr(settings, "operator_signup_code", "correct-code")

    response = _signup(client, "wrong@example.com", "wrong-code")

    assert response.status_code == 403
    assert response.json()["detail"] == "A valid invite code is required"


def test_configured_code_rejects_missing_invite(signup_api, monkeypatch):
    client, _ = signup_api
    monkeypatch.setattr(settings, "operator_signup_code", "correct-code")

    response = _signup(client, "missing@example.com")

    assert response.status_code == 403
    assert response.json()["detail"] == "A valid invite code is required"


def test_production_without_configured_code_disables_signup(signup_api, monkeypatch):
    client, _ = signup_api
    monkeypatch.setattr(settings, "env", "production")

    response = _signup(client, "prod@example.com")

    assert response.status_code == 403
    assert response.json()["detail"] == "Operator signup is disabled"


def test_development_without_configured_code_allows_signup(signup_api):
    client, _ = signup_api

    response = _signup(client, "dev@example.com")

    assert response.status_code == 200


def test_duplicate_email_still_returns_400(signup_api):
    client, db = signup_api
    db.add(
        Operator(
            name="Existing",
            email="duplicate@example.com",
            hashed_password="hash",
        )
    )
    db.commit()

    response = _signup(client, "duplicate@example.com")

    assert response.status_code == 400
    assert response.json()["detail"] == "Email already registered"
