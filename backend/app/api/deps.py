from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.operator import Operator

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/operator/login")


def get_current_operator(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Operator:
    payload = decode_access_token(token)
    if not payload or payload.get("role") != "operator":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")

    operator = db.get(Operator, int(payload["sub"]))
    if not operator:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Operator not found")
    return operator


def get_current_crew_claims(token: str = Depends(oauth2_scheme)) -> dict:
    payload = decode_access_token(token)
    if not payload or payload.get("role") != "crew":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")
    return payload
