# barber-migrations

Owns the entire PostgreSQL 17 schema for the barber-booking system.
Atlas (https://atlasgo.io) computes diffs and applies migrations.

## Layout

```
barber-migrations/
├── atlas.hcl                 # Atlas project config (dev URL + envs)
├── schema/                   # Desired state (SQL DDL), one file per service area
│   ├── 01_users.sql
│   ├── 02_shops.sql
│   ├── 03_barbers.sql
│   ├── 04_bookings.sql
│   ├── 05_payments.sql
│   ├── 06_reviews.sql
│   ├── 07_notifications.sql
│   └── 08_audit.sql
├── migrations/               # Versioned SQL migrations (Atlas-generated)
└── Dockerfile                # Migration runner image (atlas + schema files)
```

## Ownership map

Schema file → service that owns the tables:

| File | Service | Tables |
|---|---|---|
| 01_users.sql | auth-svc | users |
| 02_shops.sql | shop-svc | shops, shop_opening_hours, chairs, shop_staff, service_templates |
| 03_barbers.sql | barber-svc | barber_profiles, services, working_hours, schedule_exceptions |
| 04_bookings.sql | booking-svc | bookings, walkin_queue_entries, capacity_shortage_responses |
| 05_payments.sql | payment-svc | payments |
| 06_reviews.sql | review-svc | reviews |
| 07_notifications.sql | notification-svc | notifications |
| 08_audit.sql | (all) | audit_logs |

## Common commands

```bash
# Diff current dev DB vs desired state; create a new versioned migration.
atlas migrate diff <name> --env local

# Apply pending migrations to dev DB.
atlas migrate apply --env local

# Lint pending migrations.
atlas migrate lint --env local --latest 1

# Inspect drift between live DB and schema/.
atlas schema inspect --env local

# Apply against production (CI/CD).
atlas migrate apply --env prod
```

## Local dev

Atlas needs a dev DB to plan migrations. Easiest:

```bash
docker run --rm -d -p 5433:5432 \
  -e POSTGRES_PASSWORD=atlas -e POSTGRES_DB=dev \
  --name barber-atlas-dev postgres:17
```

The `local` env in `atlas.hcl` points at this container.

## Two-phase schema changes

For any breaking diff: ship the additive migration → deploy code that handles
both old and new shapes → ship the destructive migration in a second migration.
Never combine an additive and destructive change in one apply.

## CI/CD

- `ci.yml`: runs `atlas migrate lint` on every PR.
- Production deploy builds a Docker image with atlas + migrations and runs it
  once before each service redeploy. See `barber-infra` for the orchestration.
