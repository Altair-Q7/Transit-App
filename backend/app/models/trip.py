import enum
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class TripStatus(str, enum.Enum):
    SCHEDULED = "scheduled"
    ACTIVE = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Trip(Base):
    """
    One lap of the Trip Lifecycle Flywheel: Setup -> Configuration ->
    Trip Start -> Live Processing -> Passenger Access -> Intelligent
    Monitoring -> Trip Completion.
    """
    __tablename__ = "trips"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    bus_id: Mapped[int] = mapped_column(Integer, ForeignKey("buses.id"), nullable=False)
    route_id: Mapped[int] = mapped_column(Integer, ForeignKey("routes.id"), nullable=False)
    crew_id: Mapped[int] = mapped_column(Integer, ForeignKey("crew.id"), nullable=True)

    status: Mapped[TripStatus] = mapped_column(Enum(TripStatus), default=TripStatus.SCHEDULED)
    started_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    bus = relationship("Bus", back_populates="trips")
    route = relationship("Route", back_populates="trips")
    pings = relationship("TripPing", back_populates="trip", cascade="all, delete-orphan")
    incidents = relationship("Incident", back_populates="trip", cascade="all, delete-orphan")


class TripPing(Base):
    """
    Periodic GPS snapshot persisted to MariaDB for history/audit.
    Live, high-frequency pings are written to Redis first (see
    services/redis_client.py) and only sampled down into this table —
    keeps write volume on the relational DB sane.
    """
    __tablename__ = "trip_pings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    trip_id: Mapped[int] = mapped_column(Integer, ForeignKey("trips.id"), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    speed_kmh: Mapped[float | None] = mapped_column(Float, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    trip = relationship("Trip", back_populates="pings")


class IncidentType(str, enum.Enum):
    BREAKDOWN = "breakdown"
    TRAFFIC = "traffic"
    EMERGENCY = "emergency"


class Incident(Base):
    """
    Backs the False-Alarm Filter Protocol:
    Raw GPS Anomaly -> Filter 1 (Crew Prompt) -> Filter 2 (Crew Reports,
    unverified) -> Filter 3 (Admin Verification) -> Passenger Notification.
    """
    __tablename__ = "incidents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    trip_id: Mapped[int] = mapped_column(Integer, ForeignKey("trips.id"), nullable=False)
    type: Mapped[IncidentType] = mapped_column(Enum(IncidentType), nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    reported_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Filter 3: Admin Verification — only verified incidents are pushed to passengers
    admin_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    trip = relationship("Trip", back_populates="incidents")
