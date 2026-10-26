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
def eta_api(monkeypatch):
    monkeypatch.setattr(rate_limit, "get_redis", lambda: FakeRedis())

    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    db = Session(engine)

    operator = Operator(
        name="ETA Progress Operator",
        email="eta-progress@example.test",
        hashed_password="hash",
        subscription_active=True,
    )
    db.add(operator)
    db.flush()

    bus = Bus(operator_id=operator.id, registration_number="ETA-PROGRESS-1", capacity=40)
    route = Route(
        operator_id=operator.id,
        name="ETA Progress Route",
        origin="Kochi",
        destination="Alappuzha",
    )
    db.add_all([bus, route])
    db.flush()

    previous_stop = Stop(
        route_id=route.id,
        name="Previous Stop",
        sequence=1,
        latitude=9.90,
        longitude=76.30,
    )
    target_stop = Stop(
        route_id=route.id,
        name="Target Stop",
        sequence=2,
        latitude=9.95,
        longitude=76.30,
    )
    db.add_all(
        [
            previous_stop,
            target_stop,
            Stop(
                route_id=route.id,
                name="Later Stop",
                sequence=3,
                latitude=10.00,
                longitude=76.30,
            ),
        ]
    )
    db.flush()

    trip = Trip(
        bus_id=bus.id,
        route_id=route.id,
        status=TripStatus.ACTIVE,
        started_at=datetime.now(timezone.utc),
    )
    db.add(trip)
    db.commit()

    async def fake_live_position(trip_id: int):
        return {
            # Closer to the target stop than to either neighbour, but not past it.
            "lat": "9.949",
            "lng": "76.30",
            "speed_kmh": "30",
            "ts": datetime.now(timezone.utc).isoformat(),
        }

    monkeypatch.setattr(redis_client, "get_live_position", fake_live_position)

    def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    client = TestClient(app)
    try:
        yield {
            "client": client,
            "db": db,
            "trip": trip,
            "target_stop_id": target_stop.id,
        }
    finally:
        app.dependency_overrides.clear()
        db.close()
        engine.dispose()


def test_eta_marks_target_departed_from_persisted_progress(eta_api):
    eta_api["trip"].last_stop_sequence = 2
    eta_api["db"].commit()

    response = eta_api["client"].get(f"/api/v1/eta/{eta_api['target_stop_id']}")

    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["status"] == "departed"


def test_eta_without_progress_near_target_is_en_route(eta_api):
    eta_api["trip"].last_stop_sequence = None
    eta_api["db"].commit()

    response = eta_api["client"].get(f"/api/v1/eta/{eta_api['target_stop_id']}")

    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["status"] == "en_route"
