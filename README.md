# Sarathy — The Private Bus Arrival & Passenger Intelligence Platform

*"Your journey, guided."*

This is a production codebase scaffold for Sarathy, built to match the architecture
and product plan in `Sarathy_Transit_Intelligence.pdf`:

```
Layer 1: The Edge     Flutter (passenger_app, crew_app) + Next.js PWA (web-admin)
Layer 2: The Core     Python FastAPI, modular backend, WebSocket live updates
Layer 3: The Data     Redis (live ETA cache) + MariaDB (historical source of truth)
```

## Repo layout

```
sarathy/
├── backend/            FastAPI app — auth, fleet, trips, ETA engine, WebSocket
├── apps/
│   ├── passenger_app/  Flutter — stop search, live ETA, live map (Passenger Intelligence)
│   ├── crew_app/       Flutter — one-tap trip start, GPS ping, incident reporting (Crew Command)
│   └── web-admin/      Next.js — operator console: fleet, routes, live trips, KPIs
└── docker-compose.yml  MariaDB + Redis + backend + web-admin, wired together
```

## Running it

**First-time setup:**

```bash
cp .env.example .env                       # root: DB creds shared by mariadb + backend
cp backend/.env.example backend/.env       # backend-only: SECRET_KEY, rate limits, etc.
```

Generate a real `SECRET_KEY` for anything beyond local dev:
```bash
openssl rand -hex 32
```

**Then bring everything up:**

```bash
docker compose up --build
```

- API: http://localhost:8000 (interactive docs at `/docs`)
- Admin console: http://localhost:3000
- MariaDB: localhost:3306 (creds from your root `.env`)
- Redis: localhost:6379
- Nightly DB backups land in the `backups_data` volume (see Security section below)

The backend auto-creates tables on startup for local dev (`AUTO_CREATE_TABLES=true`
in `backend/.env`). Anything beyond local dev must set that to `false` and use
Alembic migrations instead (`alembic upgrade head`) — the app **refuses to
start** in `ENV=staging` or `ENV=production` if it's still `true`, or if
`SECRET_KEY` is still the placeholder value.

**Flutter apps** (need the Flutter SDK installed locally):

```bash
cd apps/passenger_app && flutter pub get && flutter run
cd apps/crew_app && flutter pub get && flutter run
```

Both point at `http://localhost:8000/api/v1` and `ws://localhost:8000` by
default — change the `baseUrl` in each app's `lib/services/*.dart` for a
real device or deployed backend.

## What's implemented vs. stubbed

**Implemented end-to-end:**
- Operator signup/login, crew login (JWT)
- Fleet + route/stop management (operator-scoped)
- Trip lifecycle: start → GPS ping → live broadcast over WebSocket → end
- MVP-phase ETA engine (GPS + route distance + historical speed → baseline confidence),
  isolated behind `services/eta_engine.py` so Version 2 (traffic APIs, time-of-day)
  and Version 3 (ML + weather) can replace the internals without touching callers
- False-alarm filter: crew-reported incidents stay unverified until an admin confirms
- Offline GPS queuing on the crew app (local queue, flushed when a ping succeeds)
- KPI tiles on the admin dashboard, backed by a real `/admin/stats` endpoint

**Stubbed / next steps (see the roadmap slide — Sarathy 2.0, 3.0, 4.0):**
- Live map rendering (both the admin "Live Trips" page and the passenger live
  tracking screen have the WebSocket wiring done; drop in Google Maps/Mapbox
  for the visual layer)
- Stop search is a hardcoded demo list in the passenger app — wire to a real
  `/stops/search` endpoint as you add more routes
- Passenger advertising (Ad model exists; no ad-serving endpoint yet)
- Digital ticketing, QR passes, ML-based ETA, IoT fleet analytics (Nodes 3–4)

## Auth model

- **Operators** sign up/log in with email + password → JWT with `role: operator`
- **Crew** log in with phone + password → JWT with `role: crew`
- **Passengers** are unauthenticated for the MVP — ETA search and live tracking
  are public reads, matching the deck's B2C flow (stop searches, app attention,
  ad impressions as the "input" side of the value exchange)

## Security & production-readiness

This isn't a toy auth setup — the following is implemented and tested:

- **Secrets**: DB credentials live in one root `.env` (previously duplicated
  between the `mariadb` service and the backend's `DATABASE_URL`). The app
  **refuses to boot** in staging/production if `SECRET_KEY` is still the
  placeholder value, or if `AUTO_CREATE_TABLES` is still on (see
  `backend/app/core/config.py`).
- **Rate limiting**: Redis-backed sliding-window limiter on every auth route
  and the public ETA-lookup endpoint (`backend/app/core/rate_limit.py`) —
  works correctly across multiple backend replicas, not just one process.
- **Brute-force lockout**: after `LOGIN_MAX_ATTEMPTS` failed logins for one
  email/phone, further attempts are rejected for `LOGIN_LOCKOUT_SECONDS`
  regardless of which IP they come from.
- **Structured logging**: every log line is a single JSON object tagged with
  a request ID (`backend/app/core/logging.py`), and that same ID comes back
  in the `X-Request-ID` response header — so a user's bug report can be
  traced straight to the matching log line.
- **No leaked internals**: unhandled exceptions return a generic 500 +
  request ID to the client in production; the full traceback still goes to
  logs. Dev/staging keep full tracebacks for debugging.
- **Security headers**: `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy` on every response; `Strict-Transport-Security` added in
  production.
- **Non-root container**: the backend image runs as an unprivileged user.
- **Automated backups**: a `backup` service in `docker-compose.yml` runs
  `mysqldump` every 24h with rotation (`infra/backup/backup.sh`,
  `BACKUP_RETENTION_DAYS` in root `.env`). This gets you a recovery point —
  it is not a full disaster-recovery plan; mount `backups_data` to real
  off-site storage (S3, etc.) before you have real customer data in here.

**Still on you before this is truly production-grade:** TLS termination
(put this behind nginx/Traefik/a load balancer with real certs — nothing
here terminates HTTPS itself), a secrets manager instead of `.env` files
once you have more than one person deploying, and a monitoring/alerting
stack (Sentry, Prometheus, etc.) wired to the structured logs above.

## Database schema

Nine tables cover the whole B2B2C loop:
`operators`, `crew`, `buses`, `routes`, `stops`, `trips`, `trip_pings`,
`incidents`, `stop_search_logs`, `ads`. See `backend/app/models/` — each file
has a comment tying it back to the relevant slide (Tri-Node ecosystem, Trip
Lifecycle Flywheel, False-Alarm Filter Protocol, Dual-Engine Business Model).
# Transit-App
