import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.api.deps import get_current_operator
from app.db.session import Base, get_db
from app.main import app
from app.models.fleet import Bus, Route
from app.models.operator import Crew, Operator
from app.models.trip import Incident, IncidentType, Trip, TripStatus


@pytest.fixture
def operator_api():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    db = Session(engine)

    owner = Operator(name="Owner", email="owner@example.test", hashed_password="hash")
    other = Operator(name="Other", email="other@example.test", hashed_password="hash")
    db.add_all([owner, other])
    db.flush()

    owner_crew = Crew(
        operator_id=owner.id,
        name="Owner Driver",
        phone="+910000000001",
        hashed_password="hash",
        role="driver",
    )
    other_crew = Crew(
        operator_id=other.id,
        name="Other Driver",
        phone="+910000000002",
        hashed_password="hash",
        role="driver",
    )
    owner_bus = Bus(operator_id=owner.id, registration_number="OWNER-1", capacity=40)
    other_bus = Bus(operator_id=other.id, registration_number="OTHER-1", capacity=40)
    owner_route = Route(
        operator_id=owner.id,
        name="Owner Route",
        origin="Kochi",
        destination="Alappuzha",
    )
    other_route = Route(
        operator_id=other.id,
        name="Other Route",
        origin="Kollam",
        destination="Thiruvananthapuram",
    )
    db.add_all([owner_crew, other_crew, owner_bus, other_bus, owner_route, other_route])
    db.flush()

    owner_trip = Trip(
        bus_id=owner_bus.id,
        route_id=owner_route.id,
        crew_id=owner_crew.id,
        status=TripStatus.ACTIVE,
    )
    other_trip = Trip(
        bus_id=other_bus.id,
        route_id=other_route.id,
        crew_id=other_crew.id,
        status=TripStatus.ACTIVE,
    )
    db.add_all([owner_trip, other_trip])
    db.flush()
    db.add_all(
        [
            Incident(
                trip_id=owner_trip.id,
                type=IncidentType.TRAFFIC,
                note="Owner incident",
            ),
            Incident(
                trip_id=other_trip.id,
                type=IncidentType.BREAKDOWN,
                note="Other incident",
            ),
        ]
    )
    db.commit()

    def override_db():
        yield db

    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_operator] = lambda: owner
    client = TestClient(app)
    try:
        yield client, db, owner
    finally:
        app.dependency_overrides.clear()
        db.close()
        engine.dispose()


def test_operator_endpoints_provision_and_scope_data(operator_api):
    client, db, owner = operator_api

    provisioned = client.post(
        "/api/v1/operator/crew",
        json={
            "name": "Owner Conductor",
            "phone": "+910000000003",
            "password": "local-demo-password",
            "role": "conductor",
        },
    )
    assert provisioned.status_code == 201
    assert provisioned.json()["role"] == "conductor"
    assert "hashed_password" not in provisioned.json()

    crew = client.get("/api/v1/operator/crew")
    assert crew.status_code == 200
    assert {member["phone"] for member in crew.json()} == {
        "+910000000001",
        "+910000000003",
    }

    trips = client.get("/api/v1/operator/trips")
    assert trips.status_code == 200
    assert len(trips.json()) == 1
    assert trips.json()[0]["bus_id"] == db.query(Bus).filter(Bus.operator_id == owner.id).one().id

    incidents = client.get("/api/v1/operator/incidents")
    assert incidents.status_code == 200
    assert [incident["note"] for incident in incidents.json()] == ["Owner incident"]
