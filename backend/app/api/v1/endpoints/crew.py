from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_crew_claims
from app.db.session import get_db
from app.models.fleet import Bus, Route
from app.models.operator import Crew
from app.schemas.schemas import BusOut, CrewMeOut, RouteOut

router = APIRouter(prefix="/crew", tags=["crew"])


def _operator_id(crew_claims: dict) -> int:
    try:
        return int(crew_claims["operator_id"])
    except (KeyError, TypeError, ValueError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid crew token")


@router.get("/me", response_model=CrewMeOut)
def get_crew_profile(
    crew_claims: dict = Depends(get_current_crew_claims),
    db: Session = Depends(get_db),
):
    """Profile of the authenticated crew member, scoped to their operator."""
    try:
        crew_id = int(crew_claims["sub"])
    except (KeyError, TypeError, ValueError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid crew token")

    crew = (
        db.query(Crew)
        .filter(Crew.id == crew_id, Crew.operator_id == _operator_id(crew_claims))
        .one_or_none()
    )
    if not crew:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Crew member not found")
    return crew


@router.get("/buses", response_model=list[BusOut])
def list_crew_buses(
    crew_claims: dict = Depends(get_current_crew_claims),
    db: Session = Depends(get_db),
):
    """Buses belonging to the authenticated crew member's operator."""
    return (
        db.query(Bus)
        .filter(Bus.operator_id == _operator_id(crew_claims))
        .order_by(Bus.id)
        .all()
    )


@router.get("/routes", response_model=list[RouteOut])
def list_crew_routes(
    crew_claims: dict = Depends(get_current_crew_claims),
    db: Session = Depends(get_db),
):
    """Routes belonging to the authenticated crew member's operator."""
    return (
        db.query(Route)
        .filter(Route.operator_id == _operator_id(crew_claims))
        .order_by(Route.id)
        .all()
    )
