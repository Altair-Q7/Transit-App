# Sarathy backend

## Database setup

The SQLAlchemy models are represented by the baseline Alembic revision. From
this directory, configure `DATABASE_URL` and run:

```sh
alembic upgrade head
```

Development may still use `AUTO_CREATE_TABLES=true`, but deployed environments
should set it to `false` and apply migrations explicitly.

## Kerala demo data

The demo seed is deliberately safe by default: without `--apply` it only
prints the planned dataset. Applying it inserts missing records for a Kerala
route and never updates or deletes existing rows. It uses the configured
database and requires a password supplied at runtime through
`SARATHY_DEMO_PASSWORD`; no password is stored in the repository or printed.

Run it after `alembic upgrade head`:

```sh
python -m scripts.seed_kerala_demo
SARATHY_DEMO_PASSWORD='choose-a-local-demo-password' \
  python -m scripts.seed_kerala_demo --apply
```

The fixed demo operator is `demo.operator@sarathy.local`, and the crew demo
phone is `+919000000001`. Re-running the apply command is idempotent for those
demo keys. Use only in a local/demo database.

## Operator API slice

After logging in as an operator, use the bearer token on:

- `POST /api/v1/operator/crew` to provision a driver or conductor
- `GET /api/v1/operator/crew` to list that operator's crew
- `GET /api/v1/operator/trips` to list that operator's trips
- `GET /api/v1/operator/incidents` to list incidents from that operator's trips

All four endpoints are scoped to the authenticated operator. Crew passwords
are accepted only for provisioning and are never returned by the API.
