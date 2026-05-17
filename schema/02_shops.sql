-- Owner: shop-svc
-- Tables: shops, shop_opening_hours, chairs, shop_staff, service_templates

CREATE TABLE IF NOT EXISTS shops (
  id             TEXT           PRIMARY KEY,
  owner_id       TEXT           NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  name           VARCHAR(120)   NOT NULL,
  photo_url      TEXT,
  address_line   VARCHAR(255)   NOT NULL,
  district       VARCHAR(80)    NOT NULL,
  province       VARCHAR(80)    NOT NULL,
  postcode       VARCHAR(10)    NOT NULL,
  latitude       NUMERIC(9,6),
  longitude      NUMERIC(9,6),
  contact_phone  VARCHAR(20)    NOT NULL,
  line_id        VARCHAR(60),
  verified_at    TIMESTAMPTZ,
  avg_rating     NUMERIC(3,2),
  review_count   INTEGER        NOT NULL DEFAULT 0,
  is_active      BOOLEAN        NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS shops_district_idx ON shops (district);
CREATE INDEX IF NOT EXISTS shops_owner_idx    ON shops (owner_id);


CREATE TABLE IF NOT EXISTS shop_opening_hours (
  id          TEXT         PRIMARY KEY,
  shop_id     TEXT         NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  weekday     SMALLINT     NOT NULL,
  is_closed   BOOLEAN      NOT NULL DEFAULT FALSE,
  open_time   TIME,
  close_time  TIME,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT shop_opening_hours_weekday_check CHECK (weekday BETWEEN 0 AND 6),
  CONSTRAINT shop_opening_hours_times_check
    CHECK (is_closed = TRUE OR (open_time IS NOT NULL AND close_time IS NOT NULL AND open_time < close_time))
);

CREATE UNIQUE INDEX IF NOT EXISTS shop_opening_hours_uq ON shop_opening_hours (shop_id, weekday);


CREATE TABLE IF NOT EXISTS chairs (
  id             TEXT         PRIMARY KEY,
  shop_id        TEXT         NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  name           VARCHAR(60)  NOT NULL,
  is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
  display_order  SMALLINT     NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS chairs_shop_idx ON chairs (shop_id) WHERE deleted_at IS NULL;


CREATE TABLE IF NOT EXISTS shop_staff (
  id          TEXT         PRIMARY KEY,
  shop_id     TEXT         NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  barber_id   TEXT         NOT NULL REFERENCES users(id)  ON DELETE RESTRICT,
  role        VARCHAR(24)  NOT NULL,
  joined_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  left_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT shop_staff_role_check CHECK (role IN ('senior','junior','apprentice'))
);

-- v1 invariant: a barber works at exactly one shop while active.
CREATE UNIQUE INDEX IF NOT EXISTS shop_staff_active_barber_uq
  ON shop_staff (barber_id) WHERE left_at IS NULL;
CREATE INDEX        IF NOT EXISTS shop_staff_shop_idx ON shop_staff (shop_id);


CREATE TABLE IF NOT EXISTS service_templates (
  id                        TEXT          PRIMARY KEY,
  code                      VARCHAR(40)   NOT NULL,
  name_th                   VARCHAR(120)  NOT NULL,
  name_en                   VARCHAR(120)  NOT NULL,
  default_duration_minutes  INTEGER       NOT NULL,
  default_buffer_minutes    INTEGER       NOT NULL,
  created_at                TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ   NOT NULL DEFAULT now(),

  CONSTRAINT service_templates_duration_check CHECK (default_duration_minutes > 0),
  CONSTRAINT service_templates_buffer_check   CHECK (default_buffer_minutes  >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS service_templates_code_uq ON service_templates (code);
