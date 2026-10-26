from fastapi import APIRouter, Query
from sqlalchemy.orm import Session
from fastapi import Depends

from app.db.session import get_db
from app.models.fleet import Route, Stop
from app.models.operator import Operator
from app.schemas.schemas import StopOut

router = APIRouter(prefix="/stops", tags=["stops"])


@router.get("/search", response_model=list[StopOut])
def search_stops(
    q: str = Query(min_length=2, max_length=100),
    db: Session = Depends(get_db),
):
    """Public passenger stop search across active operators."""
    term = f"%{q.strip()}%"
    if len(q.strip()) < 2:
        return []
    return (
        db.query(Stop)
        .join(Route, Route.id == Stop.route_id)
        .join(Operator, Operator.id == Route.operator_id)
        .filter(Operator.subscription_active.is_(True), Stop.name.ilike(term))
        .order_by(Stop.name, Stop.sequence)
        .limit(20)
        .all()
    )
