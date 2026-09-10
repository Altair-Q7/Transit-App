from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.rate_limit import check_login_lockout, clear_failed_logins, enforce_rate_limit, record_failed_login
from app.core.security import create_access_token, hash_password, verify_password
from app.db.session import get_db
from app.models.operator import Crew, Operator
from app.schemas.schemas import OperatorSignup, Token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/operator/signup", response_model=Token)
async def operator_signup(payload: OperatorSignup, request: Request, db: Session = Depends(get_db)):
    """Node 1 of the Trip Lifecycle Flywheel: Setup (Operator Registration)."""
    await enforce_rate_limit(request, settings.rate_limit_auth, bucket="operator_signup")

    if db.query(Operator).filter(Operator.email == payload.email).first():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Email already registered")

    operator = Operator(
        name=payload.name,
        email=payload.email,
        hashed_password=hash_password(payload.password),
    )
    db.add(operator)
    db.commit()
    db.refresh(operator)

    token = create_access_token(subject=str(operator.id), role="operator")
    return Token(access_token=token, role="operator")


@router.post("/operator/login", response_model=Token)
async def operator_login(request: Request, form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    await enforce_rate_limit(request, settings.rate_limit_auth, bucket="operator_login")
    await check_login_lockout(form.username, settings.login_max_attempts, settings.login_lockout_seconds)

    operator = db.query(Operator).filter(Operator.email == form.username).first()
    if not operator or not verify_password(form.password, operator.hashed_password):
        await record_failed_login(form.username, settings.login_lockout_seconds)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email or password")

    await clear_failed_logins(form.username)
    token = create_access_token(subject=str(operator.id), role="operator")
    return Token(access_token=token, role="operator")


@router.post("/crew/login", response_model=Token)
async def crew_login(request: Request, form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """form.username carries the crew phone number."""
    await enforce_rate_limit(request, settings.rate_limit_auth, bucket="crew_login")
    await check_login_lockout(form.username, settings.login_max_attempts, settings.login_lockout_seconds)

    crew = db.query(Crew).filter(Crew.phone == form.username).first()
    if not crew or not verify_password(form.password, crew.hashed_password):
        await record_failed_login(form.username, settings.login_lockout_seconds)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect phone or password")

    await clear_failed_logins(form.username)
    token = create_access_token(subject=str(crew.id), role="crew", extra={"operator_id": crew.operator_id})
    return Token(access_token=token, role="crew")
