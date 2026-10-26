# Sarathy v1 — Deployment & Product Plan

> **Status (Oct 2026):** Phases 1, 3 and 4 are implemented and verified on
> `v1-foundation` (40 backend tests, CI, compose up/down with real MariaDB).
> Phase 5 is implemented on Android and analysable static config on iOS, but
> cannot be signed or run on iOS from Linux. Phase 6 (push) has not started.
> Checkboxes below reflect the actual state. Confirmed decisions:
>
> - One Flutter codebase (`apps/sarathy_app`) with `passenger`, `crew` and an
>   internal `dev` role-picker flavor.
> - Passengers are fully anonymous: no accounts, no login, no passenger JWT.
> - The operator console is `apps/web-admin`; the mobile operator role is
>   dev/demo only.
> - Operator signup is invite-code gated via `OPERATOR_SIGNUP_CODE`.
> - App IDs: `com.sarathy.transit`, `com.sarathy.transit.crew`,
>   `com.sarathy.transit.dev`.
>
> Remaining v1 blockers are deployment-time only: a real keystore and store
> accounts, a VPS `.env`, TLS/reverse proxy, and iOS build verification.

## What this app is

Sarathy is a private-bus arrival and passenger intelligence platform — essentially
"Where is my train" for privately operated Indian bus fleets. Bus companies running
corporate, school, college, and industrial-park services have no public arrival data
(Google Maps only covers metro transit), so passengers guess at stops, operators get
flooded with "where is my bus?" phone calls, and drivers run three jobs at once.
Sarathy gives operators a fleet console, gives crew a one-tap trip app that streams GPS,
and lets passengers check arrival times without ever logging in.

---

## 1. Product concept

### 1.1 The loop

The codebase is structured around a "trip lifecycle flywheel":

| Node | Action | Implementation |
|---|---|---|
| 1 | Operator signs up (email + password → JWT) | `api/v1/endpoints/auth.py` |
| 2 | Operator configures buses, routes, ordered stops | `api/v1/endpoints/fleet.py` |
| 3 | Crew one-tap starts a trip | `api/v1/endpoints/trips.py` |
| 4 | GPS ping every ~5s → **Redis**, broadcast over WebSocket | `api/v1/endpoints/trips.py` |
| 5 | Passenger checks ETA for a stop (**unauthenticated**) | `api/v1/endpoints/eta.py` |
| 6 | Crew reports breakdown / traffic / emergency | `api/v1/endpoints/trips.py` |
| 7 | Trip completes | `api/v1/endpoints/trips.py` |

### 1.2 The three ideas that work

**Write-amplification control.** GPS pings go into a Redis hash
(`trip:live:{trip_id}`, 30-minute TTL) and are fanned out over WebSocket. MariaDB only
receives a sampled `trip_pings` history. At fleet scale you cannot write every 5-second
ping to a relational database.

**False-Alarm Filter Protocol.** A crew-reported incident is stored **unverified** and
passengers are not notified. It only becomes passenger-facing after an operator calls
`POST /admin/incidents/{id}/verify`. This stops drivers crying wolf about traffic.

**Dual-engine monetisation.** Operators pay a subscription tier
(`starter` / `growth` / `fleet`). Passengers never authenticate; their stop searches and
app attention are the B2C ad inventory. The `ads` table exists with an impressions
counter but has no serving endpoint yet — so this half is currently theoretical, and
the B2B subscription is the live half.

### 1.3 The one idea that is missing

"Where is my train" is fundamentally a **schedule-versus-reality diff**. Sarathy has no
schedule, so it can report *when* a bus arrives but never *whether it is late* — which
is the question passengers actually ask.

The good news, established during design: **a timetable is not required for v1.** ETA is
computed live from position and route geometry. A timetable is a v2 concern, and when it
arrives it should be **derived from observed history** rather than demanded as operator
data entry — operators running on WhatsApp groups will not maintain a form.

---

## 2. Current state assessment

### 2.1 Genuinely production-shaped

- Operator and crew JWT auth (two roles, enforced in `api/deps.py`)
- Fleet / route / stop CRUD, correctly operator-scoped
- Trip lifecycle with Redis-backed live position + WebSocket broadcast
- Redis-backed rate limiting that survives multiple replicas
- Brute-force lockout keyed **per identifier, not per IP** (`core/rate_limit.py:46`) — so
  IP rotation does not defeat it
- Structured JSON logging with a request ID echoed in `X-Request-ID`
- Production boot guards: refuses to start with a placeholder `SECRET_KEY` or with
  `AUTO_CREATE_TABLES=true` (`core/config.py`)
- Non-root backend container, nightly `mysqldump` with rotation, security headers

### 2.2 Currently theater

| Gap | Detail |
|---|---|
| **No maps** | Admin Live Trips and passenger tracking are both placeholder `Container`s |
| **Admin `/trips` page** | Makes zero API calls — no "list all trips" endpoint exists |
| **Passenger stop search** | 3 hardcoded chips; no `/stops/search` |
| **Crew bus/route** | Hardcoded to `busId: 1, routeId: 1` |
| **Incident verification UI** | Endpoint exists; `OperatorIncidentsScreen` is a stub |
| **Operator signup UI** | Endpoint + model exist, no screen. New operators require raw API calls |
| **Crew provisioning** | `crew` is a model with **no creation path** — cannot onboard a driver without raw SQL |
| **No logout anywhere** | `AuthService.logout()` exists but is unreferenced |
| **Navigation** | `sarathy_app` has no shell; the 5 operator screens are reachable only by deep link |
| **`provider` unused** | Dependency present, `MultiProvider` never built |
| **Dead code** | `publish_trip_update()` and `TripPing` are both unwritten/unused |
| **Test coverage** | One test: `backend/tests/test_health.py` |

Also note the README claims "nine tables"; there are ten (`operators`, `crew`, `buses`,
`routes`, `stops`, `trips`, `trip_pings`, `incidents`, `stop_search_logs`, `ads`).

### 2.3 Correctness issues that must be fixed before launch

These are not cosmetic. Each one produces a wrong number or a broken deployment.

#### (a) Rate limiter collapses behind a reverse proxy — **launch blocker**

`core/rate_limit.py:31` derives the client IP from `request.client.host`:

```python
client_ip = request.client.host if request.client else "unknown"
```

Behind a reverse proxy this resolves to the *proxy's* IP. Every passenger then shares one
`eta_lookup` bucket, and at `RATE_LIMIT_DEFAULT=60/minute` the 61st request site-wide
receives a 429.

**Fix:** add `--proxy-headers --forwarded-allow-ips='*'` to the uvicorn command in
`backend/Dockerfile`.

#### (b) ETAs count backwards for buses that already passed the stop

`services/eta_engine.py:32` is pure haversine, bus → stop. If the bus is two stops ahead
it is *further* away, so the number ticks **upward** as it drives away: "18 minutes" when
the truth is "you missed it." `Stop.sequence` exists (`models/fleet.py:47`) but the ETA
path never reads it.

#### (c) Straight-line distance ignores roads

Road distance is routinely 1.4–1.8× crow-flies, so ETAs are systematically optimistic and
the error grows with distance.

#### (d) Confidence is inverted for stopped buses

`eta_engine.py:36` keys confidence off `speed > 3`. A bus stopped at a red light near your
stop scores **high** confidence; a bus moving normally scores the same. Confidence also
ignores whether the bus's position along the route is even known.

#### (e) `status` is declared but never set

`schemas/schemas.py:103` declares `status: str = "on_time"`, but `eta.py:52` constructs
`EtaResponse` without passing it. **Every ETA is reported as on time.** The "Delayed"
badge in `EtaCard` is unreachable dead UI.

#### (f) Mobile apps cannot be built at all

`apps/sarathy_app/android/` contains only `local.properties` — no Gradle project, no
manifest, no `MainActivity`. `linux/` and `macos/` are empty. There is no release signing
config, no `applicationId`, no iOS bundle ID, and default Flutter branding.

#### (g) Zero migrations

`backend/alembic/versions/` contains only `.gitkeep`. Since production boot refuses
`AUTO_CREATE_TABLES=true`, **the app cannot start in production at all** in its current
state. This is the hardest wall in the project.

#### (h) No CI, no TLS, no configured environment

No `.github` directory. Nothing terminates HTTPS. No `.env` exists. MariaDB (3306) and
Redis (6379) are both published to the host. The `web-admin` Dockerfile uses `npm install`
instead of `npm ci`, copies devDependencies into the runner, and runs as root — unlike the
carefully non-root backend.

Repository history is two commits: `first commit`, `Demo V1`.

---

## 3. Scope decisions for v1

Each of these is a deliberate cut. Together they save several weeks.

| Decision | Instead of | Rationale |
|---|---|---|
| **Ship two artifacts:** passenger app + web admin | Four frontends | `passenger_app`, `crew_app`, and `sarathy_app` overlap heavily. Maintaining three mobile apps means none stay current |
| **Crew app is sideloaded, not store-reviewed** | Shipping crew to Play | Background location triggers Play's justification review — a common rejection. A crew app is an internal tool for a handful of drivers; sideload or MDM it and skip review entirely |
| **v1 = ETA + push, no live map** | Map in v1 | A map needs a billing-enabled Maps API key plus a full SDK integration. Push has no API cost and is the higher-value feature. Map → v1.1 |
| **One baseline migration, no history** | A migration chain | Zero production data exists, so a single autogenerated baseline is cleaner than a fake history |
| **Single uvicorn worker for v1** | Multi-worker | The in-process WebSocket `ConnectionManager` is correct at one process. The Redis pub/sub seam already exists |

### 3.1 Recommended final topology

```
apps/sarathy_app      → passenger experience → Play Store + App Store
apps/crew_app         → internal crew tool   → sideloaded / MDM, no store review
apps/web-admin        → operator console     → served over HTTPS at /admin
backend               → FastAPI              → container, internal behind proxy
```

**Consolidate:** fold `passenger_app` into `sarathy_app` (which already has the broadest
coverage), delete `crew_app`/`passenger_app` once their screens are ported, and delete
`Demo/sarathy_demo/` — an empty Flutter project whose README is still the default
"A new Flutter project" boilerplate.

**Keep:** `publish_trip_update()` is written but unused. It is the intended Redis pub/sub
channel for horizontal scaling. Do not delete it.

### 3.2 Housekeeping before starting

- Done: working tree committed on `v1-foundation`
- Done: `Demo/sarathy_demo/` removed
- Done: legacy `passenger_app` / `crew_app` folded into `apps/sarathy_app`

---

## 4. Phase plan

Dependencies are sequential unless noted. Critical path is **Phase 5**.

### Phase 1 — Unblock the boot · ~2 days

Nothing deploys until this passes: `AUTO_CREATE_TABLES=false` plus an empty
`alembic/versions/` means the app refuses to start in production by design.

- [x] Generate one baseline Alembic migration covering all ten tables
- [x] Hand-edit it to add `trips.last_stop_sequence: int | None`
- [x] Verify against **real MariaDB** — SQLite will not catch `Enum` or MySQL-dialect issues
- [x] Add `--proxy-headers --forwarded-allow-ips` to the uvicorn CMD (exact proxy IP,
      never `*`; uvicorn 0.30.6 does not accept CIDR ranges)
- [x] Add a `healthcheck` hitting `/health` to the backend service; add `depends_on: condition: service_healthy`
- [x] Remove host port mappings for MariaDB (3306) and Redis (6379) — keep them internal
- [x] Configure log rotation (`max-size` / `max-file`) in compose — Docker's default json-file driver has none and will silently fill the disk
- [x] `web-admin` Dockerfile: `npm ci`, install only production dependencies in the runner stage, add `USER node`
- [ ] Generate a real `SECRET_KEY` via `openssl rand -hex 32` and real database credentials
- [ ] Write the VPS `.env` with `chmod 600`; confirm `.gitignore` still covers `.env`

**Done when:** `ENV=production AUTO_CREATE_TABLES=false docker compose up` completes on a
clean VPS, `/health` returns 200, and `alembic current` matches `alembic head`.

### Phase 2 — TLS + VPS · ~1 day

- [ ] Stand up **Caddy** as the reverse proxy (automatic Let's Encrypt renewal, far less
      friction than nginx for a single origin)
- [ ] Proxy to `web-admin:3000` and `backend:8000`
- [ ] Set `CORS_ORIGINS` to the real domain
- [ ] Confirm HSTS is active (backend already sets it in production)
- [ ] Point each Flutter app's API/WS base URLs at the live domain, per environment

**Done when:** `https://` works for admin and API, with a valid certificate and no mixed
content.

### Phase 3 — Make it correct · ~3 days

#### 3.1 The ETA fix

This is the core product work. Design goal: correct arrival answers with **no map SDK**.

**New state.** One column on `trips`:

```python
last_stop_sequence: Mapped[int | None]   # updated on every ping
```

**Step 1 — Track route progress.** On each GPS ping, match the bus position to the
nearest `Stop` on its route (the route's stops are already loaded). Write that stop's
`sequence` to `trip.last_stop_sequence`.

**Step 2 — Answer the query.** For a lookup at stop `S`:

- `S <= last_stop_sequence` → return `status="departed"` with no ETA
- `S > last_stop_sequence` → sum `haversine(stop[i], stop[i+1])` from
  `last_stop_sequence + 1` through `S`, divide by effective speed

Summing stop-to-stop segments instead of one straight line to the target is the key
economy: bends get counted, so a winding corridor stops reading as 3 minutes, and it
needs **no map dependency**. Route polyline matching can refine this later but is not a
prerequisite.

**Step 3 — Fix `status`.** `eta.py` must actually pass the field. New values:

```
en_route | departed | no_live_data
```

`departed` is not merely an error fix — "bus already left, next one in 12 minutes" is
often the answer the passenger actually needed.

**Step 4 — Redefine confidence.** Confidence should reflect *how well the bus's position
along the route is known*, not just speed. If the nearest stop on the route is 2 km away,
the bus could be on any of several segments — that is `low` confidence regardless of speed.
Suggested inputs: distance to nearest matched stop, recent speed variance, data staleness
against `settings.eta_gps_stale_seconds`.

**Step 5 — Use the existing config knobs.** `eta_gps_stale_seconds` and
`eta_confidence_speed_variance` are defined in `core/config.py` but never read by the
engine. Wire them up as part of Step 4.

**Step 6 — Sample into `trip_pings`.** Nothing currently writes it. Sampling progress while
fixing the hot path gives the departure history needed later for a derived timetable.

**Step 7 — Model dwell time.** Eight remaining stops means eight stops to pull away from.
Add a small per-stop dwell allowance to the segment sum.

#### 3.2 Stop search

- [x] Add `GET /stops/search?q=` to replace the 3 hardcoded chips
- [x] **Resolve the tenant-visibility tension:** stops are operator-scoped, but passengers
      are anonymous and do not know which operator they want. This endpoint must search
      across all *active* operators' stops
- [ ] Decide whether an operator can mark a route private, and enforce it

#### 3.3 Tests

Coverage is now 40 tests across auth, crew/operator endpoints, ETA engine, trip
progress, public endpoints, proxy rate limiting and config guards.

- [x] **Tenant isolation** — can operator A's JWT read or mutate operator B's buses,
      routes, trips, and incidents? Cross-tenant leakage is the single most likely way
      this launch goes badly wrong
- [x] Rate limiter and lockout behaviour, including the proxy-IP path from 2.3a
- [x] ETA engine: unit tests for segment-sum, `departed` detection, confidence bands
- [x] Auth: role enforcement, expiry, crew-vs-operator token separation

### Phase 4 — Onboarding · ~2 days

Market use is blocked without this — today there is no way to onboard anyone but yourself.

- [x] Operator signup screen (endpoint and model already exist; only the UI is missing)
- [x] `POST /crew` operator-scoped provisioning endpoint
- [x] Crew roster UI in the admin console
- [x] Bus and route selection on crew trip start, removing `busId: 1, routeId: 1`
- [x] Navigation shell for `sarathy_app` so operator screens are reachable without deep links
- [x] Seed script with a realistic demo corridor (Kerala route, real stop coordinates)
- [x] Logout buttons wired to the existing `AuthService.logout()`

### Phase 5 — Mobile build-out · ~2 weeks ← critical path

Android is built and verified; iOS platform files exist but cannot be compiled on
Linux, so iOS work stays static until a macOS runner or device is available.

- [x] `flutter create --platforms=android,ios .` to generate the missing platform scaffolding
- [x] Android: `applicationId`, `versionCode` / `versionName`, `minSdk`, product
      flavors and per-flavor permissions (passenger declares no location permission)
- [ ] Android: **release signing config with a real keystore** (never debug keys), R8/ProGuard
- [x] iOS: bundle ID, `Info.plist` location usage strings
- [ ] iOS: deployment target, App Store team, crew-only background mode and Xcode schemes
- [x] Port `passenger_app` screens into the consolidated app
- [x] Real launcher icons and app name (currently default Flutter branding)
- [x] `AppConfig` per-environment API/WS URLs — already runtime-overridable, wire the build flavours
- [x] Verify the offline ping queue survives backgrounding — persisted via
      `flutter_secure_storage`, FIFO, flushed on reconnect
- [ ] Build release AAB and IPA

**Store prerequisites (both stores):**

- [ ] Developer accounts (Google Play $25, Apple $99/yr) — **hard prerequisite, no signing without them**
- [ ] Privacy policy URL — neither store reviews without it
- [ ] Play Data Safety form and App Privacy label
- [ ] Store listing: screenshots, descriptions, support URL

### Phase 6 — Push notifications · ~1 week (parallel with Phase 5)

There is no notification infrastructure today. Push is what makes ETA habit-forming,
because a map dot cannot be pushed.

- [ ] FCM (free tier) and APNs integration
- [ ] Device token registration endpoint + `devices` table
- [ ] **Scheduled ETA evaluator** — a genuinely new component, since you cannot rely on the
      app being open. Either a cron container or APScheduler
- [ ] "3 min — start walking" notification
- [ ] Respect Android notification permission flow (API 33+) and iOS notification permission prompt

### Phase 7 — CI + pre-launch · ~3 days

- [x] GitHub Actions: backend lint + test
- [ ] GitHub Actions: **`alembic upgrade head` against a throwaway MariaDB service** — this
      catches broken migrations before they reach the VPS
- [x] GitHub Actions: `web-admin` build
- [ ] GitHub Actions: `flutter build apk` — proves the mobile targets actually compile
- [x] GitHub Actions: `flutter analyze` + `flutter test` (compilation is verified locally;
      an APK job would need an Android SDK runner)
- [ ] **Backup restore drill** — a backup never restored from is not a backup. Restore
      `backups_data` into a scratch MariaDB and verify row counts
- [ ] Confirm `backups_data` is mounted to off-site storage, not just a local Docker volume
- [ ] Pin base image versions rather than floating tags

### Post-v1 / explicit deferrals

| Item | Notes |
|---|---|
| Live map rendering | Needs a billing-enabled Maps API key. v1.1 |
| Digital ticketing / QR passes | Named in the roadmap; no schema yet |
| Ad-serving endpoint | `ads` model exists, zero endpoints |
| Derived timetable | From `trip_pings` + `trips.started_at`, aggregated by route and time-of-day. Do not ask operators to enter one |
| ML ETA, weather, traffic APIs | `eta_engine` is already isolated for exactly this |
| Crew app in app stores | Sideload instead |
| Horizontal scaling | Multi-worker uvicorn + Redis pub/sub on `publish_trip_update()`. Keep 1 worker for v1 |
| TLS/secrets/monitoring beyond the above | Secrets manager once more than one person deploys; Sentry or Prometheus on the existing structured logs |

---

## 5. Prerequisites to confirm before starting

1. **Google Play and Apple developer accounts** — no bundle ID or signing without them
2. **A real domain** — Caddy/TLS and `CORS_ORIGINS` both depend on it
3. **A VPS** with Docker Compose and the ports for HTTP/HTTPS
4. **Confirmation of the final app topology** in §3.1 — specifically whether the passenger
   app should be passenger-only or keep the role-selection entry point
5. **Which operator is the pilot** — real routes and stops make the seed data useful, and
   the tenant-visibility decision in §3.2 depends on it

---

## 6. Effort summary

| Phase | Duration | Nature |
|---|---|---|
| 1 — Unblock boot | ~2 days | Blocker removal |
| 2 — TLS + VPS | ~1 day | Infra |
| 3 — Correctness (ETA, search, tests) | ~3 days | Core product |
| 4 — Onboarding | ~2 days | Market-blocking |
| 5 — Mobile build-out | ~2 weeks | **Critical path** — creation, not deployment |
| 6 — Push | ~1 week | Runs parallel to 5 |
| 7 — CI + pre-launch | ~3 days | Safety net |

Infrastructure and backend work totals roughly 5 days. The mobile targets are 2 weeks
because they are being built from zero, not deployed. Push and mobile overlap, so a
realistic v1 is **about three weeks** from the day prerequisites are in place.