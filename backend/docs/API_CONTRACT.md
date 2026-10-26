# Sarathy Backend API Contract

Source of truth for client teams. Derived from the routers registered in
`app/api/v1/api.py` and the schemas in `app/schemas/schemas.py`.

- Base path: `/api/v1` (except `GET /health`).
- Auth: `Authorization: Bearer <JWT>`.
  - `none` — public, no `Authorization` header required or read.
  - `crew` — JWT with `role=crew` (from `POST /auth/crew/login`).
  - `operator` — JWT with `role=operator` (from `POST /auth/operator/login` or `/auth/operator/signup`).
- A missing JWT on a protected route returns `401` with a
  `WWW-Authenticate: Bearer` header. An invalid/expired JWT, or a valid JWT
  with the wrong role, also returns `401` (`{"detail": ...}`), without that
  header.
- Passengers are anonymous: no passenger token or identity exists anywhere.
- All bodies are JSON unless noted. Protected operator/crew routes are always
  scoped to the JWT's `operator_id`; IDs from another tenant return `403`.
- Every route that accepts a body returns `422` on schema/query validation
  failure (FastAPI default shape `{"detail": [...]}`).
- Rate limits (Redis, keyed by client IP): auth routes `10/minute`;
  `GET /eta/{stop_id}` `60/minute`. Exceeding either returns `429`.
- Login failures are additionally locked out per email/phone after 5 failed
  attempts for 300 seconds (`429`).

## Endpoint summary

| Method | Path | Auth | Request | Response model | Success | Other statuses |
|---|---|---|---|---|---|---|
| GET | `/health` | none | — | `{status, service, env}` | 200 | — |
| POST | `/auth/operator/signup` | none | `OperatorSignup` | `Token` | 200 | 400 duplicate email, 429 |
| POST | `/auth/operator/login` | none | form: `username`, `password` | `Token` | 200 | 401 bad credentials, 429 |
| POST | `/auth/crew/login` | none | form: `username` (phone), `password` | `Token` | 200 | 401 bad credentials, 429 |
| POST | `/buses` | operator | `BusCreate` | `BusOut` | 200 | 401 |
| GET | `/buses` | operator | — | `list[BusOut]` | 200 | 401 |
| POST | `/routes` | operator | `RouteCreate` | `RouteOut` | 200 | 401 |
| GET | `/routes` | operator | — | `list[RouteOut]` | 200 | 401 |
| POST | `/trips/start` | crew | `TripStart` | `TripOut` | 200 | 401, 403, 404, 409 |
| POST | `/trips/end/{trip_id}` | crew | — | `TripOut` | 200 | 401, 403, 404, 409 |
| POST | `/trips/ping` | crew | `GpsPing` | `{status: "ok"}` | 200 | 401, 403, 404, 409 |
| POST | `/trips/incident` | crew | `IncidentReport` | `{id, status: "reported_unverified"}` | 200 | 400, 401, 403, 404, 409 |
| GET | `/trips/{trip_id}/live` | none | — | live position object | 200 | 404 (no live data) |
| GET | `/eta/{stop_id}` | none | — | `list[EtaResponse]` | 200 | 404, 429 |
| GET | `/stops/search` | none | query `q` | `list[StopOut]` | 200 | 422 (`q` outside 2–100 chars) |
| POST | `/operator/crew` | operator | `CrewProvision` | `CrewOut` | 201 | 401, 409 duplicate phone |
| GET | `/operator/crew` | operator | — | `list[CrewOut]` | 200 | 401 |
| GET | `/operator/trips` | operator | — | `list[OperatorTripOut]` | 200 | 401 |
| GET | `/operator/incidents` | operator | — | `list[IncidentOut]` | 200 | 401 |
| GET | `/crew/me` | crew | — | `CrewMeOut` | 200 | 401 |
| GET | `/crew/buses` | crew | — | `list[BusOut]` | 200 | 401 |
| GET | `/crew/routes` | crew | — | `list[RouteOut]` | 200 | 401 |
| POST | `/admin/incidents/{incident_id}/verify` | operator | — | `{id, status: "verified", notify_passengers: true}` | 200 | 401, 403, 404 |
| GET | `/admin/stats` | operator | — | stats object | 200 | 401 |
| WS | `/ws/trip/{trip_id}` | none | — | server push object | — | socket close |

## Auth

### POST `/api/v1/auth/operator/signup`
Public. Body `OperatorSignup`:

```json
{"name": "Kerala Lines", "email": "ops@example.com", "password": "secret"}
```

`200` → `Token`:

```json
{"access_token": "<jwt>", "token_type": "bearer", "role": "operator"}
```

Errors: `400 {"detail": "Email already registered"}`; `429` when over the
auth rate limit.

### POST `/api/v1/auth/operator/login`
Public. `Content-Type: application/x-www-form-urlencoded` with
`username=<email>&password=<password>` (OAuth2 password form). `200` → `Token`
with `role="operator"`. `401 {"detail": "Incorrect email or password"}`.
`429` for lockout/rate limit.

### POST `/api/v1/auth/crew/login`
Public. Same form encoding; `username` is the crew phone number. `200` →
`Token` with `role="crew"` (JWT also carries `operator_id`).
`401 {"detail": "Incorrect phone or password"}`; `429` for lockout/rate limit.

## Fleet (operator)

### POST `/api/v1/buses`
Operator. Body `BusCreate` → `200` `BusOut`. The bus is owned by the JWT's
operator.

```json
{"registration_number": "KL-01-AB-1234", "capacity": 45}
```

### GET `/api/v1/buses`
Operator. `200` → `list[BusOut]` for the JWT's operator only.

### POST `/api/v1/routes`
Operator. Body `RouteCreate` → `200` `RouteOut`, including the created stops:

```json
{
  "name": "Kochi–Alappuzha",
  "origin": "Kochi",
  "destination": "Alappuzha",
  "stops": [
    {"name": "Vyttila", "sequence": 1, "latitude": 9.967, "longitude": 76.32},
    {"name": "Alappuzha KSRTC", "sequence": 2, "latitude": 9.49, "longitude": 76.33}
  ]
}
```

### GET `/api/v1/routes`
Operator. `200` → `list[RouteOut]` for the JWT's operator only.

## Trips (crew)

`crew` routes require a crew JWT. The trip must belong to the authenticated
crew member (`sub`) and both its bus and route must belong to the JWT's
`operator_id`; otherwise `403`. Unknown trip → `404`.

### POST `/api/v1/trips/start`
Crew. Body `TripStart`:

```json
{"bus_id": 1, "route_id": 1, "crew_id": 1}
```

`crew_id` is optional; if present it must equal the JWT crew id (`403`
otherwise). `200` → `TripOut` with `status="active"`.
Errors: `404` unknown bus/route; `403` bus/route from another operator;
`409` inactive bus or bus already on an active trip.

### POST `/api/v1/trips/end/{trip_id}`
Crew. No body. `200` → `TripOut` with `status="completed"`.
`409` if the trip is not active.

### POST `/api/v1/trips/ping`
Crew. Body `GpsPing`:

```json
{"trip_id": 1, "latitude": 9.97, "longitude": 76.28, "speed_kmh": 32.5}
```

`200` → `{"status": "ok"}` after caching the position in Redis and
broadcasting it on the trip WebSocket. `409` if the trip is not active.

### POST `/api/v1/trips/incident`
Crew. Body `IncidentReport`:

```json
{"trip_id": 1, "type": "traffic", "note": "Signal failure"}
```

`type` is `breakdown | traffic | emergency`. `200` →
`{"id": 4, "status": "reported_unverified"}`. Incidents stay unverified (and
are never shown to passengers) until an operator verifies them via admin.
`400` invalid type; `409` trip not active.

### GET `/api/v1/trips/{trip_id}/live`
Public, no auth, no rate limit. `200` → cached live position for the trip:

```json
{"lat": "9.97", "lng": "76.28", "speed_kmh": "32.5", "ts": "2026-10-26T10:00:00+00:00"}
```

Values are Redis hash entries and are returned as strings; `speed_kmh` is `""`
when the crew omitted it. `404 {"detail": "No live data for this trip yet"}`
when the trip has never pinged or the cache expired.

## Crew fleet view

Crew routes require a crew JWT. Every query is scoped by the JWT's
`operator_id`; a token whose crew id belongs to a different operator is
rejected with `401`.

### GET `/api/v1/crew/me`
Crew. `200` → `CrewMeOut` for the authenticated crew member:

```json
{"id": 3, "name": "Driver One", "phone": "+919999999999", "role": "driver", "operator_id": 1}
```

### GET `/api/v1/crew/buses`
Crew. `200` → `list[BusOut]` for the crew member's operator only.

### GET `/api/v1/crew/routes`
Crew. `200` → `list[RouteOut]` for the crew member's operator only, including
each route's ordered stops.

## Passenger public surface

### GET `/api/v1/eta/{stop_id}`
Public. `200` → `list[EtaResponse]`, one entry per active trip on the stop's
route:

```json
[{"trip_id": 1, "stop_id": 7, "eta_minutes": 12.4, "confidence": "medium", "distance_km": 5.2, "status": "en_route"}]
```

`confidence` is `low | medium | high`. `status` is
`en_route | departed | no_live_data`. Trips without fresh live data are
returned with `eta_minutes=0.0`, `distance_km=0.0`, `status="no_live_data"`.
`404` unknown stop; `429` rate limited.

### GET `/api/v1/stops/search?q=<term>`
Public. `q` is required, 2–100 characters. Case-insensitive substring match on
stop name, limited to stops on routes of operators with an active
subscription, max 20 results, ordered by stop name then sequence. `200` →
`list[StopOut]` (may be empty).

### WS `/api/v1/ws/trip/{trip_id}`
Public, no token, no first-message handshake. Connect directly. The server
does not send anything on connect; it pushes one JSON object per crew GPS ping
for that trip:

```json
{"trip_id": 1, "lat": 9.97, "lng": 76.28, "speed_kmh": 32.5, "ts": "2026-10-26T10:00:00+00:00"}
```

Client text messages are read and discarded. Closing the socket removes the
subscriber. No incident data is pushed here.

## Operator crew and monitoring

### POST `/api/v1/operator/crew`
Operator. Body `CrewProvision` → `201` `CrewOut`.

```json
{"name": "Driver One", "phone": "+919999999999", "password": "secret", "role": "driver"}
```

`role` is `driver | conductor` (default `driver`). `409` duplicate phone.

### GET `/api/v1/operator/crew`
Operator. `200` → `list[CrewOut]` for the operator only.

### GET `/api/v1/operator/trips`
Operator. `200` → `list[OperatorTripOut]`, newest first, only trips whose bus
and route both belong to the operator.

### GET `/api/v1/operator/incidents`
Operator. `200` → `list[IncidentOut]`, newest first, only incidents on the
operator's trips. Includes unverified incidents (operator-only view).

## Admin (operator-authenticated)

### POST `/api/v1/admin/incidents/{incident_id}/verify`
Operator. No body. Marks the incident verified and stamps `verified_at`.
`200` → `{"id": 4, "status": "verified", "notify_passengers": true}`.
`404` unknown incident; `403` incident on another operator's trip.

### GET `/api/v1/admin/stats`
Operator. `200` →

```json
{
  "operator_value": {"fleet_size": 3, "active_trips": 1},
  "passenger_value": {"stop_searches_total": 120},
  "system_health": {"availability_target": "99.5%", "p95_target_ms": 500}
}
```

`stop_searches_total` is platform-wide; the other values are the operator's.

## Models

```text
OperatorSignup  {name: str, email: str(email), password: str}
Token           {access_token: str, token_type: "bearer", role: str}
CrewProvision   {name: str, phone: str, password: str, role: "driver"|"conductor" = "driver"}
CrewOut         {id: int, name: str, phone: str, role: str}
CrewMeOut       {id: int, name: str, phone: str, role: str, operator_id: int}
BusCreate       {registration_number: str, capacity: int = 45}
BusOut          {id: int, registration_number: str, capacity: int, active: bool}
StopCreate      {name: str, sequence: int, latitude: float, longitude: float}
StopOut         {id: int, route_id: int, name: str, sequence: int, latitude: float, longitude: float}
RouteCreate     {name: str, origin: str, destination: str, stops: StopCreate[] = []}
RouteOut        {id: int, name: str, origin: str, destination: str, stops: StopOut[]}
TripStart       {bus_id: int, route_id: int, crew_id: int|null = null}
GpsPing         {trip_id: int, latitude: float, longitude: float, speed_kmh: float|null = null}
TripOut         {id: int, bus_id: int, route_id: int, status: str, started_at: datetime|null, ended_at: datetime|null}
OperatorTripOut {TripOut, crew_id: int|null, created_at: datetime}
EtaResponse     {trip_id: int, stop_id: int, eta_minutes: float, confidence: str, distance_km: float, status: str = "en_route"}
IncidentReport  {trip_id: int, type: str, note: str|null = null}
IncidentOut     {id: int, trip_id: int, type: str, note: str|null, reported_at: datetime, admin_verified: bool, verified_at: datetime|null}
```

`status` values: trip `scheduled | active | completed | cancelled`; incident
`breakdown | traffic | emergency`.
