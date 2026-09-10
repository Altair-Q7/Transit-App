"""
Import all models here so Alembic's autogenerate and Base.metadata.create_all
can discover every table in one place.
"""
from app.models.operator import Operator, Crew, SubscriptionTier
from app.models.fleet import Bus, Route, Stop
from app.models.trip import Trip, TripPing, Incident, TripStatus, IncidentType
from app.models.passenger import StopSearchLog, Ad

__all__ = [
    "Operator", "Crew", "SubscriptionTier",
    "Bus", "Route", "Stop",
    "Trip", "TripPing", "Incident", "TripStatus", "IncidentType",
    "StopSearchLog", "Ad",
]
