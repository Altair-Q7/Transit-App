from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class StopSearchLog(Base):
    """
    Every passenger stop search. Powers the "Strong Stop Search volume"
    MVP KPI and, later, Passenger Demand Forecasting (Sarathy 2.0).
    """
    __tablename__ = "stop_search_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    stop_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("stops.id"), nullable=True)
    query_text: Mapped[str] = mapped_column(String(255), nullable=False)
    searched_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))


class Ad(Base):
    """
    B2C Passenger Advertising engine: monetized home-screen banners and
    local stop ads. Revenue scales with passenger adoption, independent
    of the B2B subscription engine.
    """
    __tablename__ = "ads"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    image_url: Mapped[str] = mapped_column(String(512), nullable=False)
    target_stop_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("stops.id"), nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    impressions: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
