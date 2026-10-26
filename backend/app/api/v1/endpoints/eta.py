from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.rate_limit import enforce_rate_limit
from app.db.session import get_db
from app.models.fleet import Stop
from app.models.passenger import StopSearchLog
from app.models.trip import Trip, TripStatus
from app.schemas.schemas import EtaResponse
from app.services import redis_client
from app.services.eta_engine import estimate_eta, estimate_route_eta

router = APIRouter(prefix="/eta", tags=["eta"])


def _live_data_is_fresh(live: dict) -> bool:
    raw_timestamp = live.get("ts")
    if not raw_timestamp:
        return True
    try:
        timestamp = datetime.fromisoformat(raw_timestamp.replace("Z", "+00:00"))
    except (AttributeError, TypeError, ValueError):
        return False
    if timestamp.tzinfo is None:
        timestamp = timestamp.replace(tzinfo=timezone.utc)
    return datetime.now(timezone.utc) - timestamp <= timedelta(seconds=settings.eta_gps_stale_seconds)


@router.get("/{stop_id}", response_model=list[EtaResponse])
async def get_eta_for_stop(stop_id: int, request: Request, db: Session = Depends(get_db)):
    """
    Passenger Access (flywheel node 5): 'Search ETA'.
    Unauthenticated by design (passengers aren't asked to log in), so this
    is rate-limited per-IP to prevent scraping/abuse of the public endpoint.
    """
    await enforce_rate_limit(request, settings.rate_limit_default, bucket="eta_lookup")

    stop = db.get(Stop, stop_id)
    if not stop:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stop not found")

    db.add(StopSearchLog(stop_id=stop_id, query_text=stop.name))
    db.commit()

    active_trips = (
        db.query(Trip)
        .filter(Trip.route_id == stop.route_id, Trip.status == TripStatus.ACTIVE)
        .all()
    )
    route_stops = [
        (route_stop.sequence, route_stop.latitude, route_stop.longitude)
        for route_stop in db.query(Stop)
        .filter(Stop.route_id == stop.route_id)
        .order_by(Stop.sequence)
        .all()
    ]

    results: list[EtaResponse] = []
    for trip in active_trips:
        live = await redis_client.get_live_position(trip.id)
        if not live or not _live_data_is_fresh(live):
            results.append(EtaResponse(
                trip_id=trip.id,
                stop_id=stop_id,
                eta_minutes=0.0,
                confidence="low",
                distance_km=0.0,
                status="no_live_data",
            ))
            continue

        current_speed = live.get("speed_kmh")
        current_speed_kmh = float(current_speed) if current_speed not in (None, "") else None
        if route_stops:
            estimate = estimate_route_eta(
                bus_lat=float(live["lat"]),
                bus_lng=float(live["lng"]),
                stops=route_stops,
                target_sequence=stop.sequence,
                current_speed_kmh=current_speed_kmh,
                last_stop_sequence=trip.last_stop_sequence,
                dwell_seconds=settings.eta_stop_dwell_seconds,
            )
        else:
            estimate = estimate_eta(
                bus_lat=float(live["lat"]),
                bus_lng=float(live["lng"]),
                stop_lat=stop.latitude,
                stop_lng=stop.longitude,
                current_speed_kmh=current_speed_kmh,
            )
            estimate["status"] = "en_route"
        results.append(EtaResponse(
            trip_id=trip.id,
            stop_id=stop_id,
            eta_minutes=estimate["eta_minutes"],
            confidence=estimate["confidence"],
            distance_km=estimate["distance_km"],
            status=estimate["status"],
        ))

    return results
