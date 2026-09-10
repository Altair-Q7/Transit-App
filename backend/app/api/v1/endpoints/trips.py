from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_crew_claims
from app.db.session import get_db
from app.models.trip import Incident, IncidentType, Trip, TripPing, TripStatus
from app.schemas.schemas import GpsPing, IncidentReport, TripOut, TripStart
from app.services import redis_client
from app.services.ws_manager import manager

router = APIRouter(prefix="/trips", tags=["trips"])


@router.post("/start", response_model=TripOut)
def start_trip(
    payload: TripStart,
    crew_claims: dict = Depends(get_current_crew_claims),
    db: Session = Depends(get_db),
):
    """Node 3 of the flywheel: Trip Start (Crew App Active) — the 'One-Tap Trip Start' button."""
    trip = Trip(
        bus_id=payload.bus_id,
        route_id=payload.route_id,
        crew_id=int(crew_claims["sub"]),
        status=TripStatus.ACTIVE,
        started_at=datetime.now(timezone.utc),
    )
    db.add(trip)
    db.commit()
    db.refresh(trip)
    return trip


@router.post("/end/{trip_id}", response_model=TripOut)
def end_trip(trip_id: int, crew_claims: dict = Depends(get_current_crew_claims), db: Session = Depends(get_db)):
    """Node 7 of the flywheel: Trip Completion (Data Stored)."""
    trip = db.get(Trip, trip_id)
    if not trip:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Trip not found")

    trip.status = TripStatus.COMPLETED
    trip.ended_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(trip)
    return trip


@router.post("/ping")
async def gps_ping(payload: GpsPing, crew_claims: dict = Depends(get_current_crew_claims)):
    """
    Node 4: Live Processing (GPS Matched).
    Crew app posts here roughly every 5s (see Crew Command UI: 'Ping: 5s').
    Writes to Redis (fast path) and fans the update out over WebSocket
    to any passenger currently watching this trip.
    """
    ts = datetime.now(timezone.utc).isoformat()
    await redis_client.set_live_position(payload.trip_id, payload.latitude, payload.longitude, payload.speed_kmh, ts)

    update = {
        "trip_id": payload.trip_id,
        "lat": payload.latitude,
        "lng": payload.longitude,
        "speed_kmh": payload.speed_kmh,
        "ts": ts,
    }
    await manager.broadcast(payload.trip_id, update)
    return {"status": "ok"}


@router.post("/incident")
def report_incident(
    payload: IncidentReport,
    crew_claims: dict = Depends(get_current_crew_claims),
    db: Session = Depends(get_db),
):
    """
    False-Alarm Filter Protocol, Filter 2: Crew Reports Incident (Unverified).
    Passengers are NOT notified until an admin verifies (see admin.py).
    """
    try:
        incident_type = IncidentType(payload.type)
    except ValueError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid incident type")

    incident = Incident(trip_id=payload.trip_id, type=incident_type, note=payload.note)
    db.add(incident)
    db.commit()
    db.refresh(incident)
    return {"id": incident.id, "status": "reported_unverified"}


@router.get("/{trip_id}/live")
async def get_live_position(trip_id: int):
    """Passenger-facing: current cached position for a trip."""
    position = await redis_client.get_live_position(trip_id)
    if not position:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No live data for this trip yet")
    return position
