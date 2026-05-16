// Atlas project config for the barber-booking schema.
//
// Two envs:
//   - local: dev Postgres at localhost:5433 (docker container)
//   - prod : URL injected via DATABASE_URL env var
//
// Schema is declared as the union of every SQL file in ./schema, applied in
// lexicographic order (the 01_, 02_, ... prefix). Atlas diffs this against the
// dev DB to produce versioned migrations in ./migrations.

variable "schema_src" {
  type    = list(string)
  default = [
    "file://schema/01_users.sql",
    "file://schema/02_shops.sql",
    "file://schema/03_barbers.sql",
    "file://schema/04_bookings.sql",
    "file://schema/05_payments.sql",
    "file://schema/06_reviews.sql",
    "file://schema/07_notifications.sql",
    "file://schema/08_audit.sql",
  ]
}

env "local" {
  src = var.schema_src
  url = "postgres://postgres:atlas@localhost:5433/dev?sslmode=disable"
  dev = "docker://postgres/17/dev"

  migration {
    dir    = "file://migrations"
    format = atlas
  }
}

env "prod" {
  src = var.schema_src
  url = getenv("DATABASE_URL")
  dev = "docker://postgres/17/dev"

  migration {
    dir    = "file://migrations"
    format = atlas
  }
}
