-- Owner: auth-svc
-- Tables: users
--
-- The base account row for every actor in the system. Role determines which
-- additional profile tables (barber_profiles, shops.owner_id, etc.) reference
-- this row.

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS users (
  id              TEXT          PRIMARY KEY,
  role            VARCHAR(16)   NOT NULL,
  email           VARCHAR(255)  NOT NULL,
  phone           VARCHAR(20)   NOT NULL,
  phone_verified  BOOLEAN       NOT NULL DEFAULT FALSE,
  password_hash   TEXT          NOT NULL,
  display_name    VARCHAR(80)   NOT NULL,
  language        VARCHAR(8)    NOT NULL DEFAULT 'th',
  status          VARCHAR(16)   NOT NULL DEFAULT 'pending',
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ,

  CONSTRAINT users_role_check     CHECK (role     IN ('customer','barber','shop_owner','admin')),
  CONSTRAINT users_language_check CHECK (language IN ('th','en')),
  CONSTRAINT users_status_check   CHECK (status   IN ('active','suspended','pending'))
);

CREATE UNIQUE INDEX IF NOT EXISTS users_email_uq ON users (email);
CREATE UNIQUE INDEX IF NOT EXISTS users_phone_uq ON users (phone);
CREATE INDEX        IF NOT EXISTS users_role_idx ON users (role);
