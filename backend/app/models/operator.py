import enum
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class SubscriptionTier(str, enum.Enum):
    STARTER = "starter"
    GROWTH = "growth"
    FLEET = "fleet"


class Operator(Base):
    """
    B2B node in the Tri-Node ecosystem.
    Input: fleet details, routes, subscriptions.
    Value received: live fleet visibility, passenger acquisition.
    """
    __tablename__ = "operators"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)

    subscription_tier: Mapped[SubscriptionTier] = mapped_column(
        Enum(SubscriptionTier), default=SubscriptionTier.STARTER
    )
    subscription_active: Mapped[bool] = mapped_column(default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    buses = relationship("Bus", back_populates="operator", cascade="all, delete-orphan")
    routes = relationship("Route", back_populates="operator", cascade="all, delete-orphan")
    crew_members = relationship("Crew", back_populates="operator", cascade="all, delete-orphan")


class Crew(Base):
    """
    Crew node: Driver & Conductor.
    Input: trip starts, GPS data, incident reports.
    Value received: digital workflow, direct line to operators.
    """
    __tablename__ = "crew"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    operator_id: Mapped[int] = mapped_column(Integer, ForeignKey("operators.id"), nullable=False)

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(32), default="driver")  # driver | conductor

    operator = relationship("Operator", back_populates="crew_members")
