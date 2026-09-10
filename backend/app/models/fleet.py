from sqlalchemy import Boolean, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class Bus(Base):
    """Node 1 (MVP): a single vehicle in an operator's fleet."""
    __tablename__ = "buses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    operator_id: Mapped[int] = mapped_column(Integer, ForeignKey("operators.id"), nullable=False)
    registration_number: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    capacity: Mapped[int] = mapped_column(Integer, default=45)
    active: Mapped[bool] = mapped_column(Boolean, default=True)

    operator = relationship("Operator", back_populates="buses")
    trips = relationship("Trip", back_populates="bus")


class Route(Base):
    """A named route belonging to an operator, made up of ordered Stops."""
    __tablename__ = "routes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    operator_id: Mapped[int] = mapped_column(Integer, ForeignKey("operators.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    origin: Mapped[str] = mapped_column(String(255), nullable=False)
    destination: Mapped[str] = mapped_column(String(255), nullable=False)

    operator = relationship("Operator", back_populates="routes")
    stops = relationship("Stop", back_populates="route", order_by="Stop.sequence",
                          cascade="all, delete-orphan")
    trips = relationship("Trip", back_populates="route")


class Stop(Base):
    """
    A stop along a route. Passenger "stop search" volume against these
    rows is one of the MVP success KPIs (Passenger Value metric).
    """
    __tablename__ = "stops"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    route_id: Mapped[int] = mapped_column(Integer, ForeignKey("routes.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    sequence: Mapped[int] = mapped_column(Integer, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)

    route = relationship("Route", back_populates="stops")
