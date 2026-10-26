from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.core.security import create_access_token
from app.db.session import Base, get_db
from app.main import app
from app.models.fleet import Bus, Route, Stop
from app.models.operator import Crew, Operator
from app.models.trip import Trip, TripPing, TripStatus
from app.services import redis_client
from app.services.ws_manager import manager


@pytest.fixture
def trip_api(monkeypatch):
    async def noop(*args, **kwargs):
        return None

    monkeypatch.setattr(redis_client, "set_live_position", noop)
    monkeypatch.setattr(manager, "broadcast", noop)

    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    db = Session(engine)

    operator = Operator(name="Progress Operator", email="progress@example.com", hashed_password="hash")
    db.add(operator)
    db.flush()

    crew = Crew(
        operator_id=operator.id,
        name="Progress Driver",
        phone="+910000000020",
        hashed_password="hash",
        role="driver",
    )
    bus = Bus(operator_id=operator.id, registration_number="PROGRESS-1", capacity=40)
    route = Route(
        operator_id=operator.id,
        name="Progress Route",
        origin="Kochi",
        destination="Alappuzha",
    )
    db.add_all([crew, bus, route])
    db.flush()

    stops = [
        Stop(route_id=route.id, name="Stop 1", sequence=1, latitude=9.967, longitude=76.32),
        Stop(route_id=route.id, name="Stop 2", sequence=2, latitude=9.49, longitude=76.33),
        Stop(route_id=route.id, name="Stop 3", sequence=3, latitude=8.89, longitude=76.59),
    ]
    db.add_all(stops)
    db.flush()

    trip = Trip(
        bus_id=bus.id,
        route_id=route.id,
        crew_id=crew.id,
        status=TripStatus.ACTIVE,
        started_at=datetime.now(timezone.utc),
    )
    db.add(trip)
    db.commit()

    headers = {
        "Authorization": f"Bearer {create_access_token(
            subject=str(crew.id),
            role='crew',
            extra={'operator_id': operator.id},
        )}"
    }

    def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    client = TestClient(app)
    try:
        yield {
            "client": client,
            "db": db,
            "trip": trip,
            "stops": stops,
            "headers": headers,
        }
    finally:
        app.dependency_overrides.clear()
        db.close()
        engine.dispose()


def _ping(api, latitude: float, longitude: float):
    response = api["client"].post(
        "/api/v1/trips/ping",
        headers=api["headers"],
        json={
            "trip_id": api["trip"].id,
            "latitude": latitude,
            "longitude": longitude,
            "speed_kmh": 30.0,
        },
    )
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
    return response


def test_ping_near_later_stop_advances_progress(trip_api):
    later_stop = trip_api["stops"][1]

    _ping(trip_api, later_stop.latitude, later_stop.longitude)

    trip_api["db"].refresh(trip_api["trip"])
    assert trip_api["trip"].last_stop_sequence == later_stop.sequence


def test_ping_near_earlier_stop_does_not_move_progress_backwards(trip_api):
    earlier_stop = trip_api["stops"][0]
    trip_api["trip"].last_stop_sequence = 2
    trip_api["db"].commit()

    _ping(trip_api, earlier_stop.latitude, earlier_stop.longitude)

    trip_api["db"].refresh(trip_api["trip"])
    assert trip_api["trip"].last_stop_sequence == 2


def test_ping_far_from_every_stop_leaves_progress_unchanged(trip_api):
    _ping(trip_api, 0.0, 0.0)

    trip_api["db"].refresh(trip_api["trip"])
    assert trip_api["trip"].last_stop_sequence is None


def test_ping_history_is_sampled_at_most_once_per_30_seconds(trip_api):
    db = trip_api["db"]
    stop = trip_api["stops"][0]

    _ping(trip_api, stop.latitude, stop.longitude)
    _ping(trip_api, stop.latitude, stop.longitude)
    assert db.query(TripPing).filter(TripPing.trip_id == trip_api["trip"].id).count() == 1

    newest = db.query(TripPing).filter(TripPing.trip_id == trip_api["trip"].id).one()
    newest.recorded_at = datetime.now(timezone.utc) - timedelta(seconds=31)
    db.commit()

    _ping(trip_api, stop.latitude, stop.longitude)

    pings = (
        db.query(TripPing)
        .filter(TripPing.trip_id == trip_api["trip"].id)
        .order_by(TripPing.recorded_at)
        .all()
    )
    assert len(pings) == 2
    assert pings[-1].latitude == stop.latitude
    assert pings[-1].longitude == stop.longitude
    assert pings[-1].speed_kmh == 30.0
