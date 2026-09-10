"""
Central configuration for the Sarathy Core Platform (Layer 2: The Core).
Values are loaded from environment variables / .env — see .env.example.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict

# Any SECRET_KEY equal to this is treated as "never configured" and is
# refused outside local development — see Settings.model_post_init below.
_INSECURE_DEFAULT_SECRET = "dev-secret-change-me"


class Settings(BaseSettings):
    app_name: str = "Sarathy"
    env: str = "development"  # development | staging | production

    secret_key: str = _INSECURE_DEFAULT_SECRET
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440

    database_url: str = "mysql+pymysql://sarathy:sarathy@localhost:3306/sarathy"
    redis_url: str = "redis://localhost:6379/0"

    cors_origins: str = "http://localhost:3000"

    # ETA engine tuning (Phase: MVP -> Version 2 -> Version 3, see roadmap)
    eta_gps_stale_seconds: int = 30          # ping interval crew app is expected to hit
    eta_confidence_speed_variance: float = 0.35

    # Security / production-readiness
    auto_create_tables: bool = True   # dev convenience only — set False once Alembic manages schema
    login_max_attempts: int = 5       # brute-force lockout threshold per identifier
    login_lockout_seconds: int = 300
    rate_limit_default: str = "60/minute"
    rate_limit_auth: str = "10/minute"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.env.lower() in ("staging", "production")

    def model_post_init(self, __context) -> None:
        if self.is_production and self.secret_key == _INSECURE_DEFAULT_SECRET:
            raise RuntimeError(
                "Refusing to start: SECRET_KEY is still the insecure default. "
                "Generate one (e.g. `openssl rand -hex 32`) and set it via the "
                "SECRET_KEY environment variable before running in "
                f"env={self.env!r}."
            )
        if self.is_production and self.auto_create_tables:
            # Auto-creating tables from models is a dev convenience that can
            # silently diverge from your migration history in prod.
            raise RuntimeError(
                "Refusing to start: AUTO_CREATE_TABLES must be false in "
                "staging/production. Run `alembic upgrade head` instead."
            )


settings = Settings()

