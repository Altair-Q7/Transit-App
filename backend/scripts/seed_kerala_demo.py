"""Seed a small, repeatable Kerala demo dataset.

The command is intentionally a no-op unless ``--apply`` is supplied. Applying
the seed only inserts missing records identified by the fixed demo keys; it
does not update or delete existing data. Set ``SARATHY_DEMO_PASSWORD`` only
for the apply invocation so no credential is stored in this source file.

Run from ``backend/`` after applying migrations::

    python -m scripts.seed_kerala_demo
    SARATHY_DEMO_PASSWORD='use-a-local-demo-password' \
        python -m scripts.seed_kerala_demo --apply
"""

from __future__ import annotations

import argparse
import os
from datetime import datetime, timezone

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models.fleet import Bus, Route, Stop
from app.models.operator import Crew, Operator, SubscriptionTier
from app.models.trip import Incident, IncidentType, Trip, TripStatus

DEMO_PASSWORD_ENV = "SARATHY_DEMO_PASSWORD"
DEMO_OPERATOR_EMAIL = "demo.operator@sarathy.local"
DEMO_OPERATOR_NAME = "Kerala Demo Transport"
DEMO_CREW_PHONE = "+919000000001"
DEMO_BUS_REGISTRATION = "KL-01-DEMO-001"
DEMO_ROUTE_NAME = "Kochi – Alappuzha Demo"

DEMO_STOPS = (
    ("Ernakulam South", 9.9670, 76.2910),
    ("Vyttila Mobility Hub", 9.9677, 76.3180),
    ("Cherthala", 9.6850, 76.3388),
    ("Alappuzha KSRTC", 9.4981, 76.3388),
)


def _get_or_create_operator(db):
    operator = db.query(Operator).filter(Operator.email == DEMO_OPERATOR_EMAIL).first()
    if operator:
        return operator, False

    operator = Operator(
        name=DEMO_OPERATOR_NAME,
        email=DEMO_OPERATOR_EMAIL,
        hashed_password=hash_password(os.environ[DEMO_PASSWORD_ENV]),
        subscription_tier=SubscriptionTier.STARTER,
        subscription_active=True,
    )
    db.add(operator)
    db.flush()
    return operator, True


def _get_or_create_crew(db, operator: Operator):
    crew = db.query(Crew).filter(Crew.phone == DEMO_CREW_PHONE).first()
    if crew:
        if crew.operator_id != operator.id:
            raise RuntimeError(f"Demo crew phone {DEMO_CREW_PHONE} belongs to another operator")
        return crew, False

    crew = Crew(
        operator_id=operator.id,
        name="Arun Kumar",
        phone=DEMO_CREW_PHONE,
        hashed_password=hash_password(os.environ[DEMO_PASSWORD_ENV]),
        role="driver",
    )
    db.add(crew)
    db.flush()
    return crew, True


def _get_or_create_bus(db, operator: Operator):
    bus = db.query(Bus).filter(Bus.registration_number == DEMO_BUS_REGISTRATION).first()
    if bus:
        if bus.operator_id != operator.id:
            raise RuntimeError(
                f"Demo bus {DEMO_BUS_REGISTRATION} belongs to another operator"
            )
        return bus, False

    bus = Bus(
        operator_id=operator.id,
        registration_number=DEMO_BUS_REGISTRATION,
        capacity=45,
        active=True,
    )
    db.add(bus)
    db.flush()
    return bus, True


def _get_or_create_route(db, operator: Operator):
    route = (
        db.query(Route)
        .filter(Route.operator_id == operator.id, Route.name == DEMO_ROUTE_NAME)
        .first()
    )
    if route:
        return route, False

    route = Route(
        operator_id=operator.id,
        name=DEMO_ROUTE_NAME,
        origin="Kochi",
        destination="Alappuzha",
    )
    db.add(route)
    db.flush()
    for sequence, (name, latitude, longitude) in enumerate(DEMO_STOPS, start=1):
        db.add(
            Stop(
                route_id=route.id,
                name=name,
                sequence=sequence,
                latitude=latitude,
                longitude=longitude,
            )
        )
    db.flush()
    return route, True


def seed_demo(db) -> dict[str, int]:
    """Insert missing demo records and return creation counts."""
    operator, operator_created = _get_or_create_operator(db)
    crew, crew_created = _get_or_create_crew(db, operator)
    bus, bus_created = _get_or_create_bus(db, operator)
    route, route_created = _get_or_create_route(db, operator)

    trip = (
        db.query(Trip)
        .filter(Trip.bus_id == bus.id, Trip.route_id == route.id)
        .order_by(Trip.id)
        .first()
    )
    trip_created = False
    if not trip:
        trip = Trip(
            bus_id=bus.id,
            route_id=route.id,
            crew_id=crew.id,
            status=TripStatus.ACTIVE,
            started_at=datetime.now(timezone.utc),
        )
        db.add(trip)
        db.flush()
        trip_created = True

    incident_created = False
    incident = (
        db.query(Incident)
        .filter(
            Incident.trip_id == trip.id,
            Incident.type == IncidentType.TRAFFIC,
            Incident.note == "Demo traffic near Vyttila Mobility Hub",
        )
        .first()
    )
    if not incident:
        db.add(
            Incident(
                trip_id=trip.id,
                type=IncidentType.TRAFFIC,
                note="Demo traffic near Vyttila Mobility Hub",
            )
        )
        incident_created = True

    return {
        "operators": int(operator_created),
        "crew": int(crew_created),
        "buses": int(bus_created),
        "routes": int(route_created),
        "trips": int(trip_created),
        "incidents": int(incident_created),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="insert missing demo rows; without this flag only show the plan",
    )
    args = parser.parse_args()

    if not args.apply:
        print(
            "Dry run: would seed the Kerala demo operator, one driver, one bus, "
            "the Kochi–Alappuzha route, an active trip, and one traffic incident."
        )
        print(f"Apply with --apply and {DEMO_PASSWORD_ENV} set in the environment.")
        return 0

    password = os.environ.get(DEMO_PASSWORD_ENV)
    if not password:
        parser.error(f"{DEMO_PASSWORD_ENV} must be set when using --apply")

    db = SessionLocal()
    try:
        counts = seed_demo(db)
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

    created = ", ".join(f"{name}={count}" for name, count in counts.items())
    print(f"Kerala demo seed applied safely ({created}).")
    print(f"Demo operator login: {DEMO_OPERATOR_EMAIL}")
    print(f"Demo crew login phone: {DEMO_CREW_PHONE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
