-- Owner: payment-svc
-- Tables: payments

CREATE TABLE IF NOT EXISTS payments (
  id              TEXT         PRIMARY KEY,
  booking_id      TEXT         NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
  amount_satang   BIGINT       NOT NULL,
  status          VARCHAR(16)  NOT NULL,
  method          VARCHAR(24)  NOT NULL DEFAULT 'MOCK',
  authorized_at   TIMESTAMPTZ,
  captured_at     TIMESTAMPTZ,
  refunded_at     TIMESTAMPTZ,
  metadata        JSONB        NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT payments_status_check CHECK (status IN ('PENDING','SUCCEEDED','FAILED','REFUNDED')),
  CONSTRAINT payments_amount_check CHECK (amount_satang > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS payments_booking_uq ON payments (booking_id);
CREATE INDEX        IF NOT EXISTS payments_status_idx ON payments (status);
