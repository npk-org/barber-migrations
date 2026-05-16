-- Owner: barber-svc
-- Tables: barber_profiles, services, working_hours, schedule_exceptions

CREATE TABLE IF NOT EXISTS barber_profiles (
  user_id       TEXT         PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  bio           TEXT,
  photo_url     TEXT,
  verified_at   TIMESTAMPTZ,
  avg_rating    NUMERIC(3,2),
  review_count  INTEGER      NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);


CREATE TABLE IF NOT EXISTS services (
  id                TEXT          PRIMARY KEY,
  barber_id         TEXT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  template_code     VARCHAR(40)   REFERENCES service_templates(code) ON DELETE SET NULL,
  name              VARCHAR(120)  NOT NULL,
  description       TEXT,
  price_satang      BIGINT        NOT NULL,
  duration_minutes  INTEGER       NOT NULL,
  buffer_minutes    INTEGER       NOT NULL DEFAULT 10,
  is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
  deleted_at        TIMESTAMPTZ,

  CONSTRAINT services_price_check    CHECK (price_satang > 0),
  CONSTRAINT services_duration_check CHECK (duration_minutes > 0),
  CONSTRAINT services_buffer_check   CHECK (buffer_minutes  >= 0)
);

CREATE INDEX IF NOT EXISTS services_barber_idx ON services (barber_id) WHERE deleted_at IS NULL;


CREATE TABLE IF NOT EXISTS working_hours (
  id          TEXT         PRIMARY KEY,
  barber_id   TEXT         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  weekday     SMALLINT     NOT NULL,
  is_closed   BOOLEAN      NOT NULL DEFAULT FALSE,
  open_time   TIME,
  close_time  TIME,
  breaks      JSONB        NOT NULL DEFAULT '[]'::jsonb,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT working_hours_weekday_check CHECK (weekday BETWEEN 0 AND 6),
  CONSTRAINT working_hours_times_check
    CHECK (is_closed = TRUE OR (open_time IS NOT NULL AND close_time IS NOT NULL AND open_time < close_time))
);

CREATE UNIQUE INDEX IF NOT EXISTS working_hours_uq ON working_hours (barber_id, weekday);


CREATE TABLE IF NOT EXISTS schedule_exceptions (
  id                  TEXT          PRIMARY KEY,
  barber_id           TEXT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date                DATE          NOT NULL,
  is_closed           BOOLEAN       NOT NULL,
  open_time           TIME,
  close_time          TIME,
  breaks              JSONB         NOT NULL DEFAULT '[]'::jsonb,
  reason              VARCHAR(255),
  triggered_cascade   BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS schedule_exceptions_uq ON schedule_exceptions (barber_id, date);
