"""
Layer 3: The Data — MariaDB engine/session (historical source of truth).
Redis (high-frequency live ETA caching) lives separately in
app/services/redis_client.py since it's not a relational session.
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from app.core.config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True, pool_recycle=3600)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """FastAPI dependency: yields a DB session per-request, always closed."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
