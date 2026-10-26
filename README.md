# Sarathy — private bus arrival & passenger intelligence

*"Your journey, guided."*

Sarathy gives private bus operators a live fleet console and gives passengers
arrival times without asking them to create an account. Operators configure
buses, routes and ordered stops; crew start a trip and stream GPS; passengers
search a stop and see a live ETA and map.

**End users never log in.** Stop search, ETA and live tracking are public.
Only crew (phone + password) and operators (email + password) authenticate.

## Architecture

| Layer | Component | Responsibility |
|---|---|---|
| Edge | `apps/sarathy_app` (Flutter) | Passenger, crew and dev-only operator roles |
| Edge | `apps/web-admin` (Next.js) | Operator console: fleet, routes, live trips, incidents |
| Core | `backend/` (FastAPI) | Auth, fleet, trips, ETA engine, WebSocket |
| Data | MariaDB | Historical source of truth |
| Data | Redis | Live position cache and rate-limit counters |

```
backend/          FastAPI app, Alembic migrations, demo seed, tests
apps/sarathy_app/ Flutter app (passenger + crew + dev operator)
apps/web-admin/   Next.js operator console
infra/            Backup script
docker-compose.yml
```

## Quick start

Requires Docker and Docker Compose.

```bash
cp .env.example .env          # set MARIADB_ROOT_PASSWORD and MARIADB_PASSWORD
cp backend/.env.example backend/.env
docker compose up --build
```

- API: `http://localhost:8000` (docs at `/docs`, bound to loopback only)
- Operator console: `http://localhost:3000`

Database migrations run automatically: the one-shot `migrate` service executes
`alembic upgrade head` before the backend starts. MariaDB and Redis are not
published to the host; they are reachable only on the Compose network.

Optionally load the Kerala demo dataset:

```bash
docker compose exec backend python -m scripts.seed_kerala_demo --apply
```

The demo seed is insert-only and repeatable. Set `SARATHY_DEMO_PASSWORD` for the
apply run; it is never stored in the repository.

## Mobile app

```bash
cd apps/sarathy_app
flutter pub get
flutter run --dart-define=SARATHY_API_URL=http://10.0.2.2:8000/api/v1 \
            --dart-define=SARATHY_WS_URL=ws://10.0.2.2:8000
```

Two release flavors share one codebase:

| Flavor | Package ID | Use |
|---|---|---|
| `passenger` | `com.sarathy.transit` | Store build, no background location |
| `crew` | `com.sarathy.transit.crew` | Sideload/MDM, background location |

See `apps/sarathy_app/README.md`.

## Tests

```bash
# Backend (Python 3.12 recommended)
cd backend
pip install -r requirements.txt -r requirements-dev.txt
pytest -q

# Web admin
cd apps/web-admin
npm install
npx tsc --noEmit
npm run build

# Flutter
cd apps/sarathy_app
flutter analyze
flutter test
```

## Configuration

Everything environment-specific is injected; no production domain is hardcoded.

| Variable | Used by | Purpose |
|---|---|---|
| `MARIADB_*` | Compose | Database credentials |
| `DATABASE_URL` | Backend | SQLAlchemy connection string |
| `REDIS_URL` | Backend | Live cache |
| `SECRET_KEY` | Backend | JWT signing; required in production |
| `CORS_ORIGINS` | Backend | Allowed browser origins |
| `FORWARDED_ALLOW_IPS` | Backend | Exact reverse-proxy IP trusted for `X-Forwarded-For` (no CIDR support in uvicorn 0.30.6; never `*`) |
| `OPERATOR_SIGNUP_CODE` | Backend | Invite code gating operator signup |
| `NEXT_PUBLIC_API_URL` | Web admin | API base URL, inlined at build time |
| `SARATHY_API_URL`, `SARATHY_WS_URL` | Flutter | API and WebSocket base URLs |

## Status

Passenger search/ETA/tracking, crew trip control, operator fleet and routes, and
the web console shell are implemented. The roadmap, known gaps and remaining v1
work are tracked in `V1_DEPLOYMENT_PLAN.md`.

## License

Proprietary. All rights reserved.
