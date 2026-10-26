from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_operator
from app.core.security import hash_password
from app.db.session import get_db
from app.models.fleet import Bus, Route
from app.models.operator import Crew, Operator
from app.models.trip import Incident, Trip
from app.schemas.schemas import CrewOut, CrewProvision, IncidentOut, OperatorTripOut

router = APIRouter(prefix="/operator", tags=["operator"])


@router.post("/crew", response_model=CrewOut, status_code=status.HTTP_201_CREATED)
def provision_crew(
    payload: CrewProvision,
    operator: Operator = Depends(get_current_operator),
    db: Session = Depends(get_db),
):
    """Provision one driver or conductor for the authenticated operator."""
    if db.query(Crew).filter(Crew.phone == payload.phone).first():
        raise HTTPException(status.HTTP_409_CONFLICT, "Phone number already registered")

    crew = Crew(
        operator_id=operator.id,
        name=payload.name,
        phone=payload.phone,
        hashed_password=hash_password(payload.password),
        role=payload.role,
    )
    db.add(crew)
    db.commit()
    db.refresh(crew)
    return crew


@router.get("/crew", response_model=list[CrewOut])
def list_crew(operator: Operator = Depends(get_current_operator), db: Session = Depends(get_db)):
    """List only crew provisioned under the authenticated operator."""
    return (
        db.query(Crew)
        .filter(Crew.operator_id == operator.id)
        .order_by(Crew.id)
        .all()
    )


@router.get("/trips", response_model=list[OperatorTripOut])
def list_trips(operator: Operator = Depends(get_current_operator), db: Session = Depends(get_db)):
    """List trips whose bus and route belong to the authenticated operator."""
    return (
        db.query(Trip)
        .join(Bus, Bus.id == Trip.bus_id)
        .join(Route, Route.id == Trip.route_id)
        .filter(Bus.operator_id == operator.id, Route.operator_id == operator.id)
        .order_by(Trip.created_at.desc(), Trip.id.desc())
        .all()
    )


@router.get("/incidents", response_model=list[IncidentOut])
def list_incidents(operator: Operator = Depends(get_current_operator), db: Session = Depends(get_db)):
    """List incidents from trips owned by the authenticated operator."""
    return (
        db.query(Incident)
        .join(Trip, Trip.id == Incident.trip_id)
        .join(Bus, Bus.id == Trip.bus_id)
        .join(Route, Route.id == Trip.route_id)
        .filter(Bus.operator_id == operator.id, Route.operator_id == operator.id)
        .order_by(Incident.reported_at.desc(), Incident.id.desc())
        .all()
    )
