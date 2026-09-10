from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.deps import get_current_operator
from app.db.session import get_db
from app.models.fleet import Bus
from app.models.operator import Operator
from app.models.passenger import StopSearchLog
from app.models.trip import Incident, Trip, TripStatus

router = APIRouter(prefix="/admin", tags=["admin"])


@router.post("/incidents/{incident_id}/verify")
def verify_incident(
    incident_id: int,
    operator: Operator = Depends(get_current_operator),
    db: Session = Depends(get_db),
):
    """
    False-Alarm Filter Protocol, Filter 3: Admin Verification.
    Only after this does the incident become an
    'Accurate Passenger Notification: Route affected by incident.'
    """
    incident = db.get(Incident, incident_id)
    if not incident:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Incident not found")

    from datetime import datetime, timezone
    incident.admin_verified = True
    incident.verified_at = datetime.now(timezone.utc)
    db.commit()
    return {"id": incident.id, "status": "verified", "notify_passengers": True}


@router.get("/stats")
def platform_stats(operator: Operator = Depends(get_current_operator), db: Session = Depends(get_db)):
    """Go-to-Market & Success Metrics: the four MVP KPI tiles, per-operator slice."""
    active_trips = (
        db.query(func.count(Trip.id))
        .join(Bus, Bus.id == Trip.bus_id)
        .filter(Bus.operator_id == operator.id, Trip.status == TripStatus.ACTIVE)
        .scalar()
    )
    fleet_size = db.query(func.count(Bus.id)).filter(Bus.operator_id == operator.id).scalar()
    stop_searches_total = db.query(func.count(StopSearchLog.id)).scalar()

    return {
        "operator_value": {"fleet_size": fleet_size, "active_trips": active_trips},
        "passenger_value": {"stop_searches_total": stop_searches_total},
        "system_health": {"availability_target": "99.5%", "p95_target_ms": 500},
    }
