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


@pytest.fixture
def crew_api():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    db = Session(engine)

    operator_a = Operator(
        name="Operator A", email="a@example.test", hashed_password="hash"
    )
    operator_b = Operator(
        name="Operator B", email="b@example.test", hashed_password="hash"
    )
    db.add_all([operator_a, operator_b])
    db.flush()

    crew_a = Crew(
        operator_id=operator_a.id,
        name="Crew A",
        phone="+910000000010",
        hashed_password="hash",
        role="driver",
    )
    crew_b = Crew(
        operator_id=operator_b.id,
        name="Crew B",
        phone="+910000000011",
        hashed_password="hash",
        role="conductor",
    )
    bus_a = Bus(operator_id=operator_a.id, registration_number="CREW-A-1", capacity=40)
    bus_b = Bus(operator_id=operator_b.id, registration_number="CREW-B-1", capacity=50)
    route_a = Route(
        operator_id=operator_a.id,
        name="Crew A Route",
        origin="Kochi",
        destination="Alappuzha",
    )
    route_b = Route(
        operator_id=operator_b.id,
        name="Crew B Route",
        origin="Kollam",
        destination="Thiruvananthapuram",
    )
    db.add_all([crew_a, crew_b, bus_a, bus_b, route_a, route_b])
    db.flush()

    db.add_all(
        [
            Stop(
                route_id=route_a.id,
                name="A Stop",
                sequence=1,
                latitude=9.967,
                longitude=76.32,
            ),
            Stop(
                route_id=route_b.id,
                name="B Stop",
                sequence=1,
                latitude=8.89,
                longitude=76.59,
            ),
        ]
    )
    db.commit()

    headers_a = {
        "Authorization": f"Bearer {create_access_token(
            subject=str(crew_a.id),
            role='crew',
            extra={'operator_id': operator_a.id},
        )}"
    }
    headers_b = {
        "Authorization": f"Bearer {create_access_token(
            subject=str(crew_b.id),
            role='crew',
            extra={'operator_id': operator_b.id},
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
            "headers_a": headers_a,
            "headers_b": headers_b,
            "crew_a": crew_a,
            "crew_b": crew_b,
            "bus_a": bus_a,
            "bus_b": bus_b,
            "route_a": route_a,
            "route_b": route_b,
            "operator_b": operator_b,
        }
    finally:
        app.dependency_overrides.clear()
        db.close()
        engine.dispose()


def test_crew_me_returns_authenticated_profile(crew_api):
    response = crew_api["client"].get(
        "/api/v1/crew/me", headers=crew_api["headers_a"]
    )

    assert response.status_code == 200
    assert response.json() == {
        "id": crew_api["crew_a"].id,
        "name": "Crew A",
        "phone": "+910000000010",
        "role": "driver",
        "operator_id": crew_api["crew_a"].operator_id,
    }
    assert "hashed_password" not in response.json()


def test_crew_buses_are_limited_to_their_operator(crew_api):
    response = crew_api["client"].get(
        "/api/v1/crew/buses", headers=crew_api["headers_a"]
    )

    assert response.status_code == 200
    assert [bus["registration_number"] for bus in response.json()] == ["CREW-A-1"]


def test_crew_routes_are_limited_to_their_operator(crew_api):
    response = crew_api["client"].get(
        "/api/v1/crew/routes", headers=crew_api["headers_a"]
    )

    assert response.status_code == 200
    routes = response.json()
    assert [route["name"] for route in routes] == ["Crew A Route"]
    assert [stop["name"] for stop in routes[0]["stops"]] == ["A Stop"]


def test_crew_tokens_cannot_see_another_operators_fleet(crew_api):
    client = crew_api["client"]

    buses_a = client.get("/api/v1/crew/buses", headers=crew_api["headers_a"]).json()
    buses_b = client.get("/api/v1/crew/buses", headers=crew_api["headers_b"]).json()
    routes_a = client.get("/api/v1/crew/routes", headers=crew_api["headers_a"]).json()
    routes_b = client.get("/api/v1/crew/routes", headers=crew_api["headers_b"]).json()

    assert {bus["id"] for bus in buses_a}.isdisjoint({bus["id"] for bus in buses_b})
    assert {route["id"] for route in routes_a}.isdisjoint(
        {route["id"] for route in routes_b}
    )
    assert [bus["registration_number"] for bus in buses_b] == ["CREW-B-1"]


def test_crew_claim_from_another_operator_is_rejected(crew_api):
    forged = create_access_token(
        subject=str(crew_api["crew_a"].id),
        role="crew",
        extra={"operator_id": crew_api["operator_b"].id},
    )

    response = crew_api["client"].get(
        "/api/v1/crew/buses",
        headers={"Authorization": f"Bearer {forged}"},
    )

    assert response.status_code == 401
