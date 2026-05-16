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


-- auth-svc-owned: opaque refresh tokens (30-day TTL). Stored as sha256 hash
-- of the random token so a DB leak doesn't grant the attacker live refresh
-- tokens. `replaced_by_id` tracks rotation: on /auth/refresh, the old row's
-- `replaced_by_id` is set to the new row's id (one-time-use detection).
CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
  id              TEXT          PRIMARY KEY,
  user_id         TEXT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash      BYTEA         NOT NULL,
  issued_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
  expires_at      TIMESTAMPTZ   NOT NULL,
  revoked_at      TIMESTAMPTZ,
  replaced_by_id  TEXT          REFERENCES auth_refresh_tokens(id) ON DELETE SET NULL,
  user_agent      VARCHAR(255),
  ip_address      INET,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS auth_refresh_tokens_hash_uq
  ON auth_refresh_tokens (token_hash);
CREATE INDEX IF NOT EXISTS auth_refresh_tokens_user_active_idx
  ON auth_refresh_tokens (user_id, expires_at)
  WHERE revoked_at IS NULL;


-- auth-svc-owned: JWT signing keys. Latest is_active=TRUE row is used to sign;
-- all non-revoked rows publish their public key in JWKS so in-flight tokens
-- remain verifiable across rotation.
CREATE TABLE IF NOT EXISTS auth_signing_keys (
  id           TEXT          PRIMARY KEY,
  kid          VARCHAR(64)   NOT NULL,
  algorithm    VARCHAR(16)   NOT NULL,
  public_jwk   JSONB         NOT NULL,
  private_pem  BYTEA         NOT NULL,
  is_active    BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
  rotated_at   TIMESTAMPTZ,
  retired_at   TIMESTAMPTZ,

  CONSTRAINT auth_signing_keys_algorithm_check
    CHECK (algorithm IN ('RS256','EdDSA'))
);

CREATE UNIQUE INDEX IF NOT EXISTS auth_signing_keys_kid_uq ON auth_signing_keys (kid);
CREATE UNIQUE INDEX IF NOT EXISTS auth_signing_keys_one_active
  ON auth_signing_keys ((TRUE)) WHERE is_active = TRUE;
