from fastapi import APIRouter

from app.api.v1.endpoints import admin, auth, eta, fleet, trips, ws

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(fleet.router)
api_router.include_router(trips.router)
api_router.include_router(eta.router)
api_router.include_router(admin.router)
api_router.include_router(ws.router)
