from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_operator
from app.db.session import get_db
from app.models.fleet import Bus, Route, Stop
from app.models.operator import Operator
from app.schemas.schemas import BusCreate, BusOut, RouteCreate, RouteOut

router = APIRouter(tags=["fleet"])


@router.post("/buses", response_model=BusOut)
def add_bus(
    payload: BusCreate,
    operator: Operator = Depends(get_current_operator),
    db: Session = Depends(get_db),
):
    """Node 2 of the flywheel: Configuration (Bus Assigned)."""
    bus = Bus(operator_id=operator.id, **payload.model_dump())
    db.add(bus)
    db.commit()
    db.refresh(bus)
    return bus


@router.get("/buses", response_model=list[BusOut])
def list_buses(operator: Operator = Depends(get_current_operator), db: Session = Depends(get_db)):
    return db.query(Bus).filter(Bus.operator_id == operator.id).all()


@router.post("/routes", response_model=RouteOut)
def create_route(
    payload: RouteCreate,
    operator: Operator = Depends(get_current_operator),
    db: Session = Depends(get_db),
):
    route = Route(
        operator_id=operator.id,
        name=payload.name,
        origin=payload.origin,
        destination=payload.destination,
    )
    db.add(route)
    db.flush()  # get route.id before creating stops

    for stop_in in payload.stops:
        db.add(Stop(route_id=route.id, **stop_in.model_dump()))

    db.commit()
    db.refresh(route)
    return route


@router.get("/routes", response_model=list[RouteOut])
def list_routes(operator: Operator = Depends(get_current_operator), db: Session = Depends(get_db)):
    return db.query(Route).filter(Route.operator_id == operator.id).all()
