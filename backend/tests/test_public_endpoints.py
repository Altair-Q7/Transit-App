from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.core import rate_limit
from app.db.session import Base, get_db
from app.main import app
from app.models.fleet import Bus, Route, Stop
from app.models.operator import Operator
from app.models.trip import Trip, TripStatus
from app.services import redis_client


class FakeRedis:
    async def incr(self, key: str) -> int:
        return 1

    async def expire(self, key: str, seconds: int) -> None:
        return None


@pytest.fixture
def public_api(monkeypatch):
    monkeypatch.setattr(rate_limit, "get_redis", lambda: FakeRedis())

    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    db = Session(engine)

    operator = Operator(
        name="Public Operator",
        email="public@example.test",
        hashed_password="hash",
        subscription_active=True,
    )
    db.add(operator)
    db.flush()

    bus = Bus(operator_id=operator.id, registration_number="PUBLIC-1", capacity=40)
    route = Route(
        operator_id=operator.id,
        name="Public Route",
        origin="Kochi",
        destination="Alappuzha",
    )
    db.add_all([bus, route])
    db.flush()

    stop = Stop(
        route_id=route.id,
        name="Kochi Jetty",
        sequence=1,
        latitude=9.967,
        longitude=76.32,
    )
    db.add(stop)
    db.flush()
    db.add(
        Stop(
            route_id=route.id,
            name="Alappuzha KSRTC",
            sequence=2,
            latitude=9.49,
            longitude=76.33,
        )
    )
    db.add(
        Trip(
            bus_id=bus.id,
            route_id=route.id,
            status=TripStatus.ACTIVE,
            started_at=datetime.now(timezone.utc),
        )
    )
    db.commit()

    async def fake_live_position(trip_id: int):
        return {
            "lat": "9.97",
            "lng": "76.28",
            "speed_kmh": "30",
            "ts": datetime.now(timezone.utc).isoformat(),
        }

    monkeypatch.setattr(redis_client, "get_live_position", fake_live_position)

    def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    client = TestClient(app)
    try:
        yield client, stop.id
    finally:
        app.dependency_overrides.clear()
        db.close()
        engine.dispose()


def test_stop_search_needs_no_token(public_api):
    client, _ = public_api

    response = client.get("/api/v1/stops/search", params={"q": "Kochi"})

    assert response.status_code == 200
    assert [stop["name"] for stop in response.json()] == ["Kochi Jetty"]


def test_eta_needs_no_token(public_api):
    client, stop_id = public_api

    response = client.get(f"/api/v1/eta/{stop_id}")

    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["trip_id"] == 1


def test_live_position_needs_no_token(public_api):
    client, _ = public_api

    response = client.get("/api/v1/trips/1/live")

    assert response.status_code == 200
    assert response.json()["lat"] == "9.97"


def test_trip_websocket_needs_no_token(public_api):
    client, _ = public_api

    with client.websocket_connect("/api/v1/ws/trip/1") as websocket:
        websocket.send_text("no auth needed")
