"""
Sarathy Core Platform — Layer 2: The Core (Python FastAPI, modular backend).

Run locally:
    uvicorn app.main:app --reload

Run via Docker (recommended, brings up MariaDB + Redis too):
    docker compose up --build
"""
import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from app.api.v1.api import api_router
from app.core.config import settings
from app.core.logging import configure_logging, new_request_id, request_id_ctx
from app.db.session import Base, engine

# Model modules must be imported before create_all so their tables are registered.
import app.models  # noqa: F401

configure_logging()
logger = logging.getLogger("sarathy")


@asynccontextmanager
async def lifespan(app: FastAPI):
    if settings.auto_create_tables:
        # Dev convenience only. Staging/production must use Alembic instead:
        #   alembic upgrade head
        # (config.py refuses to start in prod with this flag still on)
        Base.metadata.create_all(bind=engine)
    logger.info(f"Sarathy backend starting up | env={settings.env}")
    yield
    logger.info("Sarathy backend shutting down")


app = FastAPI(title=settings.app_name, description="Your Journey, Guided.", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class RequestContextMiddleware(BaseHTTPMiddleware):
    """Tags every request with an ID (for log correlation), adds basic
    security headers, and logs method/path/status/duration as one JSON line."""

    async def dispatch(self, request: Request, call_next):
        req_id = request.headers.get("x-request-id", new_request_id())
        token = request_id_ctx.set(req_id)
        start = time.perf_counter()

        try:
            response = await call_next(request)
        except Exception:
            logger.exception(f"Unhandled error | {request.method} {request.url.path}")
            request_id_ctx.reset(token)
            raise

        duration_ms = round((time.perf_counter() - start) * 1000, 1)
        logger.info(
            f"{request.method} {request.url.path} -> {response.status_code} ({duration_ms}ms)"
        )
        request_id_ctx.reset(token)

        response.headers["X-Request-ID"] = req_id
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        if settings.is_production:
            response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains"
        return response


app.add_middleware(RequestContextMiddleware)

app.include_router(api_router, prefix="/api/v1")


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    """
    Never leak stack traces / internal details to clients in prod. Full
    traceback still goes to logs (see the middleware above) with the
    request ID attached, so you can correlate a support ticket to the
    exact log line.
    """
    req_id = request_id_ctx.get()
    if settings.is_production:
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error", "request_id": req_id},
        )
    raise exc  # keep full tracebacks in dev/staging for debugging


@app.get("/health")
def health():
    return {"status": "ok", "service": settings.app_name, "env": settings.env}
