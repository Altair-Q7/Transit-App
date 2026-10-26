import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.db.session import Base
from scripts.seed_kerala_demo import seed_demo


@pytest.fixture
def seed_db():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    db = Session(engine)
    try:
        yield db
    finally:
        db.close()
        engine.dispose()


def test_kerala_demo_seed_is_insert_only_and_repeatable(seed_db, monkeypatch):
    monkeypatch.setenv("SARATHY_DEMO_PASSWORD", "test-only-password")

    first = seed_demo(seed_db)
    seed_db.commit()
    second = seed_demo(seed_db)
    seed_db.commit()

    assert first == {
        "operators": 1,
        "crew": 1,
        "buses": 1,
        "routes": 1,
        "trips": 1,
        "incidents": 1,
    }
    assert second == {
        "operators": 0,
        "crew": 0,
        "buses": 0,
        "routes": 0,
        "trips": 0,
        "incidents": 0,
    }
