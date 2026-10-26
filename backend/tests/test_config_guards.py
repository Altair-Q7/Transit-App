import pytest

from app.core.config import Settings, _INSECURE_DEFAULT_SECRET

_REAL_SECRET = "9f4c1e7a2b8d3056c1f9a4e7b2d8c5f1a6e3b9d7c4f2a8e1b5d3c9f7a6e2b4d8"


def _settings(**overrides) -> Settings:
    # _env_file=None isolates the test from a developer's local backend/.env.
    return Settings(_env_file=None, **overrides)


def test_production_rejects_insecure_default_secret():
    with pytest.raises(RuntimeError, match="SECRET_KEY"):
        _settings(
            env="production",
            secret_key=_INSECURE_DEFAULT_SECRET,
            auto_create_tables=False,
        )


def test_staging_rejects_insecure_default_secret():
    with pytest.raises(RuntimeError, match="SECRET_KEY"):
        _settings(
            env="staging",
            secret_key=_INSECURE_DEFAULT_SECRET,
            auto_create_tables=False,
        )


def test_production_accepts_real_secret_with_migrations_only():
    settings = _settings(
        env="production",
        secret_key=_REAL_SECRET,
        auto_create_tables=False,
    )

    assert settings.is_production
    assert settings.auto_create_tables is False


def test_production_rejects_auto_create_tables():
    with pytest.raises(RuntimeError, match="AUTO_CREATE_TABLES"):
        _settings(
            env="production",
            secret_key=_REAL_SECRET,
            auto_create_tables=True,
        )
